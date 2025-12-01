import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class CustomButton extends PositionComponent with TapCallbacks {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final bool centered;

  CustomButton({
    required this.text,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF2D2D2D),
    this.textColor = Colors.white,
    this.width = 300,
    this.height = 55,
    this.centered = true,
    super.position,
    super.size,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    if (centered) {
      size = Vector2(width, height);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Fondo del botón
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = backgroundColor,
    );

    // Borde sutil
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Texto centrado
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      fontFamily: 'Arial',
    );

    final textPaint = TextPaint(style: textStyle);
    final textWidth = _measureTextWidth(text, textStyle);

    final textPosition = Vector2((size.x - textWidth) / 2, (size.y - 18) / 2);

    textPaint.render(canvas, text, textPosition);
  }

  double _measureTextWidth(String text, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    onPressed();
  }
}
