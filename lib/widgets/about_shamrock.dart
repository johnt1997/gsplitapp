import 'dart:ui';
import 'package:flutter/material.dart';

// --- KONFIGURATION ---
// Farben für den Brutal-Look
const Color _kBrutalBlack = Color(0xFF121212);
const Color _kBrutalGold = Color(0xFFD4AF37);
const Color _kBrutalCream = Color(0xFFF5E6D3);

// Text-Styles
const TextStyle _kTitleStyle = TextStyle(
  fontFamily: 'Oswald', // Falls du die Font hast, sonst weglassen
  fontWeight: FontWeight.w900,
  fontSize: 16,
  color: _kBrutalGold,
  letterSpacing: 1.2,
);

const TextStyle _kDataStyle = TextStyle(
  fontWeight: FontWeight.bold,
  fontSize: 14,
  color: _kBrutalCream,
  height: 1.2,
);

// --- DIE HAUPTFUNKTION ZUM AUFRUFEN ---
void showBrutalShamrockDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Close",
    barrierColor: Colors.black.withOpacity(0.85), // Sehr dunkler Hintergrund
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (ctx, anim1, anim2) {
      return const Center(child: _ShamrockWidget());
    },
    transitionBuilder: (ctx, anim1, anim2, child) {
      // Coole "Aufplopp"-Animation mit leichtem Zoom und Fade
      return Transform.scale(
        scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut).value,
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
  );
}

// --- DAS WIDGET SELBST ---
class _ShamrockWidget extends StatelessWidget {
  const _ShamrockWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Größe der Blätter definieren
    const double leafSize = 130.0;
    // Überlappungs-Faktor
    const double overlap = leafSize * 0.25;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: leafSize * 2 - overlap,
        height: leafSize * 2.5,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 4. Der Stiel (Ganz hinten)
            Positioned(bottom: 0, child: _buildStem()),
            // 2. Linkes Blatt (Unten Links)
            Positioned(
              bottom: leafSize * 0.6,
              left: 0,
              child: _buildLeaf(
                content: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "VERSION",
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                    Text("v1.0.1", style: _kTitleStyle),
                    Text(
                      "STOUT BUILD",
                      style: TextStyle(color: _kBrutalCream, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            // 3. Rechtes Blatt (Unten Rechts)
            Positioned(
              bottom: leafSize * 0.6,
              right: 0,
              child: _buildLeaf(
                content: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "AUTHOR",
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                    Text("DIPL. ING.", style: _kTitleStyle),
                    Text("JOHN TUSHA", style: _kDataStyle),
                  ],
                ),
              ),
            ),
            // 1. Oberes Blatt (Ganz vorne, mittig)
            Positioned(
              top: 0,
              child: _buildLeaf(
                isTop: true,
                content: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.verified, color: _kBrutalGold, size: 24),
                    SizedBox(height: 4),
                    Text(
                      "GUINNESS\nRATER",
                      textAlign: TextAlign.center,
                      style: _kTitleStyle,
                    ),
                  ],
                ),
              ),
            ),
            // Kleiner Schließen-Hinweis
            Positioned(
              bottom: -30,
              child: Text(
                "TAP TO CLOSE",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper zum Bauen eines Blattes
  Widget _buildLeaf({required Widget content, bool isTop = false}) {
    const double size = 130.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Brutaler Look: Dunkler Verlauf mit hartem Goldrand
        gradient: RadialGradient(
          colors: [_kBrutalBlack.withOpacity(0.9), Colors.black],
          center: Alignment.topLeft,
          radius: 1.2,
        ),
        border: Border.all(
          color: _kBrutalGold,
          width: isTop ? 3.0 : 1.5, // Oberes Blatt ist fetter
        ),
        boxShadow: [
          // Harter 3D Schatten
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 15,
            offset: Offset(0, 10),
            spreadRadius: 2,
          ),
          // Inneres Glühen (optional, für Metall-Look)
          BoxShadow(
            color: _kBrutalGold.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: -5,
            offset: Offset(-5, -5),
          ),
        ],
      ),
      child: Center(child: content),
    );
  }

  // Helper zum Bauen des Stiels
  Widget _buildStem() {
    return Container(
      width: 40,
      height: 100,
      decoration: BoxDecoration(
        color: _kBrutalBlack,
        border: Border(
          left: BorderSide(color: _kBrutalGold, width: 1.5),
          right: BorderSide(color: _kBrutalGold, width: 1.5),
          bottom: BorderSide(color: _kBrutalGold, width: 3.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.eco,
          color: _kBrutalGold,
          size: 20,
        ), // Kleines Kleeblatt im Stiel
      ),
    );
  }
}
