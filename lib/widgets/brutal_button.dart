// lib/widgets/brutal_button.dart - NEUE DATEI ERSTELLEN
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ButtonVariant { primary, secondary, outline }

class BrutalButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool isEnabled;

  const BrutalButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  _BrutalButtonState createState() => _BrutalButtonState();
}

class _BrutalButtonState extends State<BrutalButton> {
  bool _isPressed = false;

  Color get _backgroundColor {
    if (!widget.isEnabled) return Color(0xFF1a1a1a);

    switch (widget.variant) {
      case ButtonVariant.primary:
        return Color(0xFFD4AF37);
      case ButtonVariant.secondary:
        return Color(0xFF1a1a1a);
      case ButtonVariant.outline:
        return Colors.transparent;
    }
  }

  Color get _textColor {
    if (!widget.isEnabled) return Color(0xFF746855);

    switch (widget.variant) {
      case ButtonVariant.primary:
        return Color(0xFF0D0D0D);
      case ButtonVariant.secondary:
      case ButtonVariant.outline:
        return Color(0xFFD4AF37);
    }
  }

  BoxBorder? get _border {
    if (widget.variant == ButtonVariant.outline) {
      return Border.all(color: Color(0xFFD4AF37), width: 1.5);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isEnabled && !widget.isLoading
          ? (_) {
              setState(() => _isPressed = true);
              HapticFeedback.mediumImpact();
            }
          : null,
      onTapUp: widget.isEnabled && !widget.isLoading
          ? (_) {
              setState(() => _isPressed = false);
              if (widget.isEnabled && !widget.isLoading) {
                widget.onPressed();
              }
            }
          : null,
      onTapCancel: widget.isEnabled && !widget.isLoading
          ? () => setState(() => _isPressed = false)
          : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scale(_isPressed && widget.isEnabled ? 0.95 : 1.0),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: _border,
          gradient: widget.variant == ButtonVariant.primary && widget.isEnabled
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFD4AF37), Color(0xFFF5E6D3)],
                )
              : null,
          boxShadow:
              widget.isEnabled &&
                  !widget.isLoading &&
                  widget.variant == ButtonVariant.primary
              ? [
                  BoxShadow(
                    color: Color(
                      0xFFD4AF37,
                    ).withOpacity(_isPressed ? 0.1 : 0.3),
                    blurRadius: _isPressed ? 10 : 20,
                    offset: Offset(0, _isPressed ? 5 : 10),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _textColor,
                    ),
                  )
                : Text(
                    widget.label,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
