import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

// Eigene Dateien
import 'firebase_options.dart';
import 'auth_wrapper.dart';
import 'providers/review_provider.dart';
import 'screens/review_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ReviewProvider())],
      child: const GuinnessApp(),
    ),
  );
}

class GuinnessApp extends StatelessWidget {
  const GuinnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guinness Rater',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        primaryColor: const Color(0xFFD4AF37),
        // Nutzt den System-Font, wenn SF Pro nicht installiert ist
        fontFamily: 'SF Pro Display',
      ),
      home: const AuthWrapper(),
      // Routes sind optional, da du Navigator.push verwendest,
      // aber für Deep Links sind sie gut:
      routes: {
        '/review': (context) {
          // Fallback-Route (In Produktion meist über Navigator.push mit Argumenten)
          return const ReviewScreen(
            pubId: 'demo',
            pubName: 'Select Pub',
            pubAddress: '',
            userId: 'unknown',
          );
        },
      },
    );
  }
}
