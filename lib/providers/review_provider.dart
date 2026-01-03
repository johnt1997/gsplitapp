import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../services/ai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final Random _random = Random();
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
      final result = await _aiService.analyzePint(_photo!.path);

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

      // Falls du isPerfectPour als Variable hast:
      // _isPerfectPour = score >= 9.5;
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

  Future<void> submitReview(String pubId, String userId) async {
    if (!isValid || _isSubmitting) return;

    _isSubmitting = true;
    _state = ReviewState.SUBMITTING;
    notifyListeners();

    try {
      // Wir bauen die Daten genau so, wie das neue Model sie braucht
      final reviewData = {
        'reviewId': _uuid.v4(), // Optional, Firestore macht eigene IDs
        'pubId': pubId,
        'userId': userId,

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
        'photoUrls':
            [], // Upload kommt später, leere Liste damit es nicht null ist
        // --- META ---
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'isPublic': true,
      };

      // Ab nach Firestore
      await _db.collection('reviews').add(reviewData);

      // 2. --- QUICK FIX: PUB STATS AKTUALISIEREN ---
      // Wir holen alle Reviews für diesen Pub, um den neuen Schnitt zu berechnen
      final allReviewsQuery = await _db
          .collection('reviews')
          .where('pubId', isEqualTo: pubId)
          .get();

      if (allReviewsQuery.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in allReviewsQuery.docs) {
          // Wir nutzen 'rating' (unser neues Feld)
          totalRating += (doc.data()['rating'] as num? ?? 0).toDouble();
        }
        double newAverage = totalRating / allReviewsQuery.docs.length;
        // Jetzt schreiben wir den neuen Schnitt direkt zurück in das Pub-Dokument
        await _db.collection('pubs').doc(pubId).update({
          'averageRating': newAverage,
          'reviewCount': allReviewsQuery.docs.length,
          'isHot': newAverage >= 7.5, // Optional: Setzt isHot automatisch
        });
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
    notifyListeners();
  }
}
