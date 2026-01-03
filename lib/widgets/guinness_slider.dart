// lib/widgets/guinness_slider.dart - VOLLSTÄNDIGE KORREKTUR
import 'dart:math';
import 'package:flutter/material.dart';

// IN guinness_slider.dart - KORREKTE paint() SIGNATUR:

class _GuinnessTrackShape extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 12.0;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset, // ✅ NEUER PARAMETER in neueren Flutter Versionen!
    bool isDiscrete = false,
    bool isEnabled = false,
    double? additionalActiveTrackHeight, // ✅ OPTIONALER PARAMETER
  }) {
    final canvas = context.canvas;
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Draw track background
    final backgroundPaint = Paint()
      ..color = Color(0xFF1a1a1a)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, Radius.circular(6)),
      backgroundPaint,
    );

    // Draw active track (progress)
    final activeRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );

    final activePaint = Paint()
      ..shader = LinearGradient(
        colors: [Color(0xFFD4AF37), Color(0xFFF5E6D3)],
      ).createShader(activeRect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(activeRect, Radius.circular(6)),
      activePaint,
    );

    // Draw track border
    final borderPaint = Paint()
      ..color = Color(0xFF746855).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, Radius.circular(6)),
      borderPaint,
    );
  }
}

class _GuinnessThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(24, 24);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Determine thumb color based on value
    Color thumbColor;
    if (value < 6.0) {
      thumbColor = Color(0xFF8B0000);
    } else if (value < 8.0) {
      thumbColor = Color(0xFFFFA500);
    } else {
      thumbColor = Color(0xFFD4AF37);
    }

    // Draw thumb circle
    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 12, thumbPaint);

    // Draw thumb border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, 12, borderPaint);

    // Draw inner dot
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 4, dotPaint);

    // Draw gold glow for high ratings
    if (value >= 8.0) {
      final glowPaint = Paint()
        ..color = Color(0xFFD4AF37).withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(center, 16, glowPaint);
    }
  }
}

class GuinnessSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String label;

  const GuinnessSlider({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.label,
  }) : super(key: key);

  @override
  _GuinnessSliderState createState() => _GuinnessSliderState();
}

class _GuinnessSliderState extends State<GuinnessSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _fillAnimation;
  late Animation<double> _fillTween;
  bool _isSliding = false;

  @override
  void initState() {
    super.initState();
    _fillAnimation = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fillTween = Tween(
      begin: 0.0,
      end: widget.value / 10,
    ).animate(_fillAnimation);
    _fillAnimation.value = widget.value / 10;
  }

  @override
  void didUpdateWidget(GuinnessSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSliding) {
      _fillTween = Tween(
        begin: oldWidget.value / 10,
        end: widget.value / 10,
      ).animate(_fillAnimation);
      _fillAnimation.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _fillAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fillPercentage = widget.value / 10;
    final color = _getColorForRating(widget.value);

    return Column(
      children: [
        // Rating value with glass icon
        Row(
          children: [
            Text(
              widget.value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: AnimatedBuilder(
                animation: _fillAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(40, 60),
                    painter: _GuinnessGlassPainter(
                      fillPercentage: _fillTween.value,
                      color: color,
                    ),
                  );
                },
              ),
            ),
            Text(
              '/10',
              style: TextStyle(fontSize: 16, color: Color(0xFF746855)),
            ),
          ],
        ),

        SizedBox(height: 8),

        // Slider
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 12,
            trackShape: _GuinnessTrackShape(),
            thumbShape: _GuinnessThumbShape(),
            overlayShape: SliderComponentShape.noOverlay,
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            thumbColor: color,
          ),
          child: Slider(
            value: widget.value,
            min: 1.0,
            max: 10.0,
            divisions: 90,
            onChanged: (value) {
              setState(() => _isSliding = true);
              widget.onChanged(value);
            },
            onChangeEnd: (_) {
              setState(() => _isSliding = false);
            },
          ),
        ),
      ],
    );
  }

  Color _getColorForRating(double rating) {
    if (rating < 6.0) return Color(0xFF8B0000);
    if (rating < 8.0) return Color(0xFFFFA500);
    return Color(0xFFD4AF37);
  }
}

class _GuinnessGlassPainter extends CustomPainter {
  final double fillPercentage;
  final Color color;

  _GuinnessGlassPainter({required this.fillPercentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final glassPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.8, 0)
      ..lineTo(size.width * 0.2, 0)
      ..close();

    final glassPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withOpacity(0.7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(glassPath, glassPaint);

    final fillHeight = size.height * (1 - fillPercentage);
    final fillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, fillHeight)
      ..lineTo(0, fillHeight)
      ..close();

    canvas.drawPath(fillPath, fillPaint);

    final foamPaint = Paint()
      ..color = Color(0xFFF5E6D3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, fillHeight - 4, size.width, 4), foamPaint);

    if (color == Color(0xFFD4AF37)) {
      final glowPaint = Paint()
        ..color = Color(0xFFD4AF37).withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawRect(
        Rect.fromLTWH(0, fillHeight - 4, size.width, 4),
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GuinnessGlassPainter oldDelegate) => true;
}
