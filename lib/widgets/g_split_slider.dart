import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GSplitSlider extends StatefulWidget {
  final double value; // Wert zwischen 0 und 100
  final ValueChanged<double> onChanged;

  const GSplitSlider({Key? key, required this.value, required this.onChanged})
    : super(key: key);

  @override
  _GSplitSliderState createState() => _GSplitSliderState();
}

class _GSplitSliderState extends State<GSplitSlider> {
  // Farben definieren
  final Color colStout = const Color(0xFF050505); // Fast Schwarz
  final Color colHead = const Color(0xFFF5E6D3); // Cremiges Weiß
  final Color colGold = const Color(0xFFD4AF37); // Guinness Gold

  void _updateValue(Offset localPosition, double height) {
    // Berechne den Wert basierend auf der Höhe (von unten nach oben)
    double percentage = 1.0 - (localPosition.dy / height);

    // Clampen zwischen 0 und 100
    double newValue = (percentage * 100).clamp(0.0, 100.0);

    // Nur update feuern, wenn sich was ändert
    if ((newValue - widget.value).abs() > 0.5) {
      HapticFeedback.selectionClick(); // Mechanisches Ticken
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LABEL
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "THE G-SPLIT",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              "${widget.value.toStringAsFixed(0)}%",
              style: TextStyle(
                color: widget.value > 90 ? colGold : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                fontFamily: 'Oswald', // Oder dein Font
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // DER VISUELLE SLIDER (DAS GLAS)
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onVerticalDragUpdate: (details) =>
                    _updateValue(details.localPosition, constraints.maxHeight),
                onTapDown: (details) =>
                    _updateValue(details.localPosition, constraints.maxHeight),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colHead, // Hintergrund ist Schaum
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // 1. DAS STOUT (Dunkle Flüssigkeit)
                      FractionallySizedBox(
                        heightFactor: widget.value / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colStout,
                            borderRadius: BorderRadius.vertical(
                              bottom: const Radius.circular(3),
                              top: Radius.circular(widget.value >= 100 ? 3 : 0),
                            ),
                          ),
                        ),
                      ),

                      // 2. DIE GOLDENE LINIE (Der "Split")
                      // 2. DIE GOLDENE LINIE (Der "Split")
                      Positioned(
                        bottom:
                            (constraints.maxHeight * (widget.value / 100)) - 1,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          // DAS HIER IST DIE ÄNDERUNG:
                          decoration: BoxDecoration(
                            color: colGold,
                            boxShadow: [
                              BoxShadow(
                                color: colGold.withOpacity(0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 3. TARGET ZONE MARKER (Wo das perfekte Review liegt - z.B. bei 95%)
                      Positioned(
                        top: constraints.maxHeight * (1 - 0.95), // Bei 95%
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          color: colGold,
                          child: const Text(
                            "PERFECT",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Target Line
                      Positioned(
                        top: constraints.maxHeight * (1 - 0.95),
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 1,
                          color: colGold.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
