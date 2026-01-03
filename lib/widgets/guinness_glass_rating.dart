// lib/widgets/guinness_glass_rating.dart - DIE "NEON BRUTAL" VERSION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class GuinnessGlassRating extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final Size size;

  const GuinnessGlassRating({
    Key? key,
    required this.rating,
    required this.onRatingChanged,
    required this.size,
  }) : super(key: key);

  void _updateRating(Offset localPosition) {
    // Berechnung basierend auf der vertikalen Position
    final double relativeY = (size.height - localPosition.dy) / size.height;
    final double newRating = (relativeY * 10).clamp(1.0, 10.0);

    // Feines Update für smoothe Animation
    if ((newRating - rating).abs() > 0.05) {
      onRatingChanged(newRating);

      // Haptik-Kick nur bei ganzen Zahlen
      if (newRating.toInt() != rating.toInt()) {
        HapticFeedback.selectionClick();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) => _updateRating(details.localPosition),
      onVerticalDragStart: (details) => _updateRating(details.localPosition),
      onTapDown: (details) => _updateRating(details.localPosition),
      child: Container(
        width: size.width,
        height: size.height,
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Der komplexe Neon-Painter
            CustomPaint(
              size: size,
              painter: _NeonGuinnessPainter(
                fillLevel: rating / 10,
                // Wir nutzen den Rating-Wert als Seed für "zufällige" Bubbles,
                // damit sie nicht flackern, sondern sich organisch anfühlen.
                randomSeed: (rating * 100).toInt(),
              ),
            ),

            // Die fette Score-Anzeige (Leuchtend)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text-Shadow für den Neon-Effekt
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF5E6D3), // Creme-Farbe
                    shadows: [
                      Shadow(color: Color(0xFFD4AF37), blurRadius: 20),
                      Shadow(color: Colors.black, blurRadius: 5),
                    ],
                  ),
                ),
                Text(
                  'STOUT SCORE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD4AF37),
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        color: Color(0xFFD4AF37).withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NeonGuinnessPainter extends CustomPainter {
  final double fillLevel;
  final int randomSeed;

  _NeonGuinnessPainter({required this.fillLevel, required this.randomSeed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final glassWidth = size.width * 0.65;
    final glassHeight = size.height * 0.8;

    // 1. DIE FORM: Ein echtes Pint-Glas (Tulpenform)
    final glassPath = Path();
    final topWidth = glassWidth * 1.0;
    final bottomWidth = glassWidth * 0.7;
    final neckWidth = glassWidth * 0.85; // Die Engstelle unten

    // Start unten links
    glassPath.moveTo(center.dx - bottomWidth / 2, center.dy + glassHeight / 2);

    // Kurve nach oben links (Tulpen-Bauch)
    glassPath.cubicTo(
      center.dx - bottomWidth / 2,
      center.dy + glassHeight * 0.2, // Control 1
      center.dx - topWidth / 2 - 10,
      center.dy - glassHeight * 0.1, // Control 2
      center.dx - topWidth / 2,
      center.dy - glassHeight / 2, // Ziel (Oben links)
    );

    // Oben rüber
    glassPath.lineTo(center.dx + topWidth / 2, center.dy - glassHeight / 2);

    // Kurve nach unten rechts
    glassPath.cubicTo(
      center.dx + topWidth / 2 + 10,
      center.dy - glassHeight * 0.1,
      center.dx + bottomWidth / 2,
      center.dy + glassHeight * 0.2,
      center.dx + bottomWidth / 2,
      center.dy + glassHeight / 2,
    );

    // Unten schließen
    glassPath.close();

    // 2. NEON GLOW HINTERGRUND (Wie auf deinem AI Bild)
    final neonPaint = Paint()
      ..color = Color(0xFFD4AF37).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15); // Starker Blur

    canvas.drawPath(glassPath, neonPaint);

    // 3. FLÜSSIGKEIT (Clipping Mask)
    canvas.save();
    canvas.clipPath(glassPath);

    // Hintergrund (leeres Glas) leicht dunkelgrau
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Color(0xFF1a1a1a),
    );

    // Flüssigkeits-Level berechnen
    final liquidHeight = glassHeight * fillLevel;
    final liquidTop = (center.dy + glassHeight / 2) - liquidHeight;

    // Die "Surge" (Der typische Guinness Farbverlauf: Schwarz zu Rubinrot)
    final liquidGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(
          0xFF2A0A0A,
        ), // Ganz oben: Tiefes Dunkelrot (wie echtes Guinness gegen Licht)
        Colors.black, // Unten: Schwarz
        Colors.black,
      ],
    ).createShader(Rect.fromLTWH(0, liquidTop, size.width, liquidHeight));

    canvas.drawRect(
      Rect.fromLTRB(0, liquidTop, size.width, size.height),
      Paint()..shader = liquidGradient,
    );

    // Die Harfe (Logo) zeichnen - NUR wenn genug Bier im Glas ist
    if (fillLevel > 0.4) {
      _drawHarp(canvas, center, glassWidth * 0.5);
    }

    canvas.restore(); // Clip entfernen für den Schaum

    // 4. DER SCHAUM (Muss über den Rand ragen können!)
    if (fillLevel > 0.05) {
      final foamHeight = 25.0; // Fester, cremiger Schaum

      // Schaum-Farbe (Creme, nicht Reinweiß)
      final foamPaint = Paint()..color = Color(0xFFF5E6D3);

      // Schaum-Rechteck (Basis)
      final foamRect = Rect.fromLTRB(
        center.dx - topWidth / 2 + 4, // Etwas Randabstand
        liquidTop - foamHeight + 5, // Sitzt oben drauf
        center.dx + topWidth / 2 - 4,
        liquidTop + 5,
      );

      // Zeichne den Schaum (mit abgerundeten Ecken oben)
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          foamRect,
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
        foamPaint,
      );

      // BUBBLES im Schaum
      final rng = Random(42); // Konstanter Seed für Positionen
      for (int i = 0; i < 20; i++) {
        double bx = foamRect.left + rng.nextDouble() * foamRect.width;
        double by = foamRect.top + rng.nextDouble() * foamRect.height;
        double br = 1 + rng.nextDouble() * 2; // Radius 1-3
        canvas.drawCircle(
          Offset(bx, by),
          br,
          Paint()..color = Colors.black.withOpacity(0.1),
        );
      }

      // KRASSER EFFEKT: ÜBERLAUFEN (Nur bei > 9.5 Rating)
      if (fillLevel > 0.95) {
        _drawOverflow(canvas, foamRect, foamPaint);
      }
    }

    // 5. GLAS UMRISS (Scharfe Neon-Linie oben drauf)
    final outlinePaint = Paint()
      ..color = Color(0xFFF5E6D3)
          .withOpacity(0.9) // Fast weißer Rand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(glassPath, outlinePaint);

    // Zweiter, goldener Glow direkt am Rand
    canvas.drawPath(
      glassPath,
      Paint()
        ..color = Color(0xFFD4AF37).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, 4),
    );
  }

  // Hilfsmethode: Zeichnet die überlaufende "Sauerei"
  void _drawOverflow(Canvas canvas, Rect foamRect, Paint foamPaint) {
    // Tropfen links
    canvas.drawCircle(
      Offset(foamRect.left - 5, foamRect.top + 10),
      6,
      foamPaint,
    );
    canvas.drawCircle(
      Offset(foamRect.left - 5, foamRect.top + 25),
      4,
      foamPaint,
    );

    // Tropfen rechts (länger)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(foamRect.right - 2, foamRect.top + 5, 8, 40),
        Radius.circular(4),
      ),
      foamPaint,
    );
  }

  // Hilfsmethode: Zeichnet eine stilisierte Harfe
  void _drawHarp(Canvas canvas, Offset center, double width) {
    final harpPaint = Paint()
      ..color = Color(0xFFD4AF37)
          .withOpacity(0.8) // Gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final hCenter = center + Offset(0, -20); // Etwas höher setzen

    // Harfen-Rahmen
    final path = Path();
    path.moveTo(hCenter.dx - width / 3, hCenter.dy - width / 3); // Oben links
    path.quadraticBezierTo(
      hCenter.dx + width / 2,
      hCenter.dy - width / 3, // Curve Control
      hCenter.dx + width / 3,
      hCenter.dy + width / 3, // Unten rechts
    );
    path.lineTo(hCenter.dx - width / 4, hCenter.dy + width / 3); // Unten links
    path.close(); // Zurück zum Start (gerade Linie hoch)

    canvas.drawPath(path, harpPaint);

    // Saiten (Strings)
    for (int i = 1; i < 5; i++) {
      double x = hCenter.dx - width / 3 + (i * 8);
      canvas.drawLine(
        Offset(x, hCenter.dy - width / 4 + (i * 2)),
        Offset(x, hCenter.dy + width / 3),
        harpPaint..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_NeonGuinnessPainter oldDelegate) =>
      oldDelegate.fillLevel != fillLevel;
}
