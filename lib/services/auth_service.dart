import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream: Hört auf den Status (Eingeloggt / Ausgeloggt)
  // Wird in der main.dart oder einem Wrapper-Widget genutzt
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Helper: Gibt die aktuelle User-ID zurück (oder null)
  String? get currentUserId => _auth.currentUser?.uid;

  // ================= REGISTRIERUNG =================
  Future<AppUser?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // 1. User in Firebase Authentication erstellen
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = result.user;

      if (firebaseUser != null) {
        // 2. Das AppUser-Dokument für Firestore erstellen
        // Wir setzen Standardwerte für den Start
        AppUser newUser = AppUser(
          id: firebaseUser.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          stats: {'totalReviews': 0, 'perfectPours': 0, 'longestStreak': 0},
        );

        // 3. In Firestore speichern (users Collection)
        await _db
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toFirestore());

        return newUser;
      }
    } on FirebaseAuthException catch (e) {
      // Spezifische Fehler werfen, damit das UI sie anzeigen kann
      if (e.code == 'weak-password') {
        throw Exception('Das Passwort ist zu schwach.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Diese E-Mail wird bereits verwendet.');
      } else {
        throw Exception(e.message ?? 'Registrierung fehlgeschlagen.');
      }
    } catch (e) {
      throw Exception('Ein unbekannter Fehler ist aufgetreten: $e');
    }
    return null;
  }

  // ================= LOGIN =================
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Login bei Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. User-Daten aus Firestore laden
      if (result.user != null) {
        return await getUserData(result.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Kein Nutzer mit dieser E-Mail gefunden.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Falsches Passwort.');
      } else {
        throw Exception('Login fehlgeschlagen. Bitte prüfe deine Eingaben.');
      }
    }
    return null;
  }

  // ================= DATEN LADEN =================
  // Lädt das volle Profil aus Firestore (inkl. Badges, Stats etc.)
  Future<AppUser?> getUserData(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _db
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        return AppUser.fromFirestore(doc, null);
      }
    } catch (e) {
      print("Fehler beim Laden der User-Daten: $e");
    }
    return null;
  }

  // ================= LOGOUT =================
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ================= PASSWORD RESET =================
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
