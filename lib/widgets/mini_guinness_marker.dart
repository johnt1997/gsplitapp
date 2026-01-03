// lib/widgets/mini_guinness_marker.dart
import 'package:flutter/material.dart';

class MiniGuinnessMarker extends StatefulWidget {
  final double rating;
  final bool isHot;

  const MiniGuinnessMarker({Key? key, required this.rating, this.isHot = false})
    : super(key: key);

  @override
  State<MiniGuinnessMarker> createState() => _MiniGuinnessMarkerState();
}

class _MiniGuinnessMarkerState extends State<MiniGuinnessMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Animation: "Atmen" für HOT Pubs
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200), // Etwas schnellerer Puls
      lowerBound: 0.85,
      upperBound: 1.05, // Ein bisschen über 1.0 hinauswachsen
    );

    if (widget.isHot) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Hier definieren wir die Farben basierend auf der NOTE (nicht Hotness)
  Color _getGlowColor(double rating) {
    if (rating >= 9.0) {
      return Color(0xFFFFD700); // LEGENDÄR: Guinness Gold
    } else if (rating >= 8.0) {
      return Color(0xFFFFC107); // SEHR GUT: Helles Amber/Gelb
    } else {
      return Color(
        0xFFFF5722,
      ); // OKAY: Tiefes Orange (nicht Rot, das wirkt wie Warnung)
    }
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = _getGlowColor(widget.rating);
    final foamColor = Color(0xFFF5E6D3);

    // Füllhöhe berechnen
    final fillPercent = (widget.rating / 10).clamp(0.2, 0.9);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Skalierung: Nur wenn Hot, nutzt er den Controller, sonst steht er still auf 1.0
        final scale = widget.isHot ? _controller.value : 1.0;

        // 1. Basis-Radius je nach Rating (9.0+ leuchtet stärker)
        final double baseBlur = widget.rating >= 9.0 ? 18.0 : 10.0;
        final double baseSpread = widget.rating >= 9.0 ? 3.0 : 1.0;

        // 2. Extra Intensität, wenn "Hot" (pulsiert mit dem Controller)
        final double blurRadius = widget.isHot
            ? baseBlur * 1.5 * _controller.value
            : baseBlur;

        final double spreadRadius = widget.isHot
            ? baseSpread * 2.0 * _controller.value
            : baseSpread;

        return Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // DAS GLAS (Stack)
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  // 1. Glow / Schatten (Hintergrund)
                  Container(
                    width: 40,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(4),
                        bottom: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withOpacity(
                            0.7,
                          ), // Hohe Deckkraft für Neon-Effekt
                          blurRadius: blurRadius,
                          spreadRadius: spreadRadius,
                        ),
                      ],
                    ),
                  ),

                  // 2. Das Glas selbst (Inhalt)
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4),
                      bottom: Radius.circular(12),
                    ),
                    child: Container(
                      width: 40,
                      height: 55,
                      color: Color(0xFF0D0D0D), // Fast Schwarz
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Flüssigkeit
                          FractionallySizedBox(
                            heightFactor: fillPercent,
                            widthFactor: 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF2A0A0A), // Rubinrot Schimmer
                                    Colors.black,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Schaum
                          Positioned(
                            bottom: 55 * fillPercent - 4,
                            left: 0,
                            right: 0,
                            child: Container(height: 8, color: foamColor),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Die Zahl
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        widget.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // DIE SPITZE (Damit es wie ein Map-Pin aussieht)
              ClipPath(
                clipper: _TriangleClipper(),
                child: Container(
                  width: 12,
                  height: 8,
                  color: Color(0xFF0D0D0D),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
