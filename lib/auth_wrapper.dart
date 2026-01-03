import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
// import 'screens/home_screen.dart'; // Deinen Map/Home Screen hier importieren

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Wenn Daten laden...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            ),
          );
        }

        // Wenn User eingeloggt ist -> Zeige Home (Map)
        if (snapshot.hasData) {
          return MapScreen();
          // Später ersetzen durch: return HomeScreen();
        }

        // Sonst -> Login Screen
        return const LoginScreen();
      },
    );
  }
}
