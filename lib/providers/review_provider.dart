// Material's Badge-Widget ausblenden — wir nutzen unser eigenes Badge-Model
import 'package:flutter/material.dart' hide Badge;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../services/ai_service.dart';
import '../services/review_service.dart';
import '../services/user_stats_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/models.dart';

enum ReviewState {
  CAMERA,
  PREVIEW,
  AI_ANALYZING,
  RATING,
  SUBMITTING,
  SUCCESS,
  ERROR,
}

class ReviewProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AiService _aiService = AiService();
  final Uuid _uuid = Uuid();
  List<String> _aiKeywords = [];
  String? _aiExplanation;

  // Getter für die UI (damit das Sheet sie lesen kann)
  List<String> get aiKeywords => _aiKeywords;
  String? get aiExplanation => _aiExplanation;

  // ZUSTANDSVARIABLEN
  ReviewState _state = ReviewState.CAMERA;
  XFile? _photo;

  // DATEN FÜR REVIEW
  double _overallRating = 5.0; // Das ist dein G-Split / Rating Wert
  String? _notes;
  GuinnessType? _guinnessType;
  double? _price;

  // KI KRAM
  double? _aiScore;
  bool _isPerfectPour = false;

  // Nach dem Submit neu freigeschaltete Badges (für "BADGE UNLOCKED!")
  List<Badge> _newBadges = [];
  List<Badge> get newBadges => _newBadges;

  // UI STATUS
  bool _isSubmitting = false;
  String? _errorMessage;

  // GETTER
  ReviewState get state => _state;
  XFile? get photo => _photo;
  double get overallRating => _overallRating;
  String? get notes => _notes;
  GuinnessType? get guinnessType => _guinnessType;
  double? get price => _price;
  double? get aiScore => _aiScore;
  bool get isPerfectPour => _isPerfectPour;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  // VALIDIERUNG: Foto muss da sein und Rating > 0
  bool get isValid => _photo != null && _overallRating > 0;

  // ---------------- ACTIONS ----------------

  Future<void> takePhoto() async {
    try {
      _errorMessage = null;
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (photo != null) {
        _photo = photo;
        _state = ReviewState.PREVIEW;
      } else {
        _state = ReviewState.CAMERA;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Kamera-Fehler: ${e.toString()}';
      _state = ReviewState.ERROR;
      notifyListeners();
    }
  }

  void retakePhoto() {
    _photo = null;
    _state = ReviewState.CAMERA;
    notifyListeners();
  }

  void confirmPhoto() {
    if (photo == null) return;
    // Anstatt direkt zu RATING zu gehen, starten wir die Analyse
    _state = ReviewState.AI_ANALYZING;
    notifyListeners();

    // Wir rufen die Analyse im Hintergrund auf
    _analyzePhoto();
  }

  Future<void> _analyzePhoto() async {
    // Zugriff auf _photo (privat)
    if (_photo == null) return;

    try {
      final result = await _aiService.analyzePint(_photo!);

      double score = (result['score'] as num).toDouble();
      bool isGuinness = result['is_guinness'] ?? true;

      // Keywords speichern (in die private Variable)
      _aiKeywords = List<String>.from(result['keywords'] ?? []);
      _aiExplanation = result['explanation'];

      if (!isGuinness) {
        score = 1.0;
        _aiExplanation = "AI says: That doesn't look like a Guinness!";
      }

      // Speichern in privaten Variablen
      _aiScore = score;
      _overallRating = score; // Slider automatisch einstellen
      _isPerfectPour = score >= 8.5; // Gleiche Schwelle wie Review.setAIScore
    } catch (e) {
      print("AI Error: $e");
      _aiScore = null;
      _overallRating = 7.0; // Fallback
    }

    // Status ändern (privat)
    _state = ReviewState.RATING;
    notifyListeners();
  }

  // Hier wird der Wert vom Glas-Slider aktualisiert
  void updateRating(double value) {
    _overallRating = value;
    notifyListeners();
  }

  void updateNotes(String text) {
    _notes = text;
    // notifyListeners() hier sparsam nutzen, sonst laggt das Tippen
  }

  void setGuinnessType(GuinnessType? type) {
    _guinnessType = type;
    notifyListeners();
  }

  void updatePrice(String text) {
    final value = double.tryParse(text);
    if (value != null) _price = value;
  }

  // ---------------- SPEICHERN (Das Wichtigste) ----------------

  Future<void> submitReview(String pubId, {String? pubName}) async {
    if (!isValid || _isSubmitting) return;

    // Review gehört immer dem eingeloggten User — keine IDs von außen
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _errorMessage = 'Nicht eingeloggt. Bitte neu anmelden.';
      _state = ReviewState.ERROR;
      notifyListeners();
      return;
    }

    _isSubmitting = true;
    _state = ReviewState.SUBMITTING;
    notifyListeners();

    try {
      final reviewId = _uuid.v4();

      // Anzeigename: Auth-Profil -> users-Doc -> E-Mail-Prefix
      String userName = user.displayName ?? '';
      if (userName.isEmpty) {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        userName =
            (userDoc.data()?['displayName'] as String?) ??
            user.email?.split('@').first ??
            'Guinness Fan';
      }

      // Foto zu Firebase Storage — Upload-Fehler sind nicht fatal,
      // das Review wird dann ohne Foto gespeichert.
      // Hartes Timeout: Ohne aktivierten Storage-Bucket retried das SDK
      // sonst endlos und der User hängt für immer im Lade-Spinner.
      final photoUrls = <String>[];
      try {
        final bytes = await _photo!.readAsBytes();
        final storage = FirebaseStorage.instance;
        storage.setMaxUploadRetryTime(const Duration(seconds: 10));
        storage.setMaxOperationRetryTime(const Duration(seconds: 10));
        final storageRef = storage.ref('reviews/$reviewId.jpg');
        await storageRef
            .putData(bytes, SettableMetadata(contentType: 'image/jpeg'))
            .timeout(const Duration(seconds: 20));
        photoUrls.add(
          await storageRef.getDownloadURL().timeout(
            const Duration(seconds: 10),
          ),
        );
      } catch (e) {
        print("STORAGE ERROR (Review wird ohne Foto gespeichert): $e");
      }

      // Wir bauen die Daten genau so, wie das neue Model sie braucht
      final reviewData = {
        'reviewId': reviewId,
        'pubId': pubId,
        'pubName': pubName,
        'userId': user.uid,
        'userName': userName,

        // --- WICHTIG: DIE NEUEN FELDER ---
        'rating': _overallRating, // Das Haupt-Rating (vom Slider)
        'comment': _notes ?? "", // Der Kommentar
        // --- COMPATIBILITY MODE ---
        // Da dein Model "shtickRating" und "presentationRating" zwingend erwartet (required),
        // müssen wir sie füllen. Wir nehmen einfach denselben Wert wie rating.
        'shtickRating': _overallRating,
        'presentationRating': _overallRating,
        'text': _notes ?? "", // Altes Feld zur Sicherheit auch füllen
        // --- OPTIONALES ---
        'price': _price,
        'guinnessType': _guinnessType
            ?.index, // WICHTIG: .index speichern (Int), nicht das Enum objekt
        'isPerfectPour': _isPerfectPour,
        'aiColorScore': _aiScore,
        'photoUrls': photoUrls,
        // --- META ---
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': <String>[],
        'isPublic': true,
      };

      // Ab nach Firestore
      await _db.collection('reviews').add(reviewData);

      // 2. --- PUB STATS AKTUALISIEREN ---
      await ReviewService().recalcPubStats(pubId);

      // 3. --- USER-STATS & BADGES (nicht fatal bei Fehler) ---
      try {
        _newBadges = await UserStatsService().recordReview(
          pubId: pubId,
          rating: _overallRating,
          isPerfectPour: _isPerfectPour,
          guinnessType: _guinnessType,
        );
      } catch (e) {
        print("STATS ERROR: $e");
        _newBadges = [];
      }

      _state = ReviewState.SUCCESS;
      notifyListeners();
    } catch (e) {
      print("FIREBASE ERROR: $e"); // Damit du es in der Konsole siehst
      _errorMessage = e.toString();
      _state = ReviewState.ERROR;
      notifyListeners();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void reset() {
    _state = ReviewState.CAMERA;
    _photo = null;
    _overallRating = 5.0;
    _notes = null;
    _guinnessType = null;
    _price = null;
    _aiScore = null;
    _isPerfectPour = false;
    _isSubmitting = false;
    _errorMessage = null;
    _newBadges = [];
    notifyListeners();
  }
}
