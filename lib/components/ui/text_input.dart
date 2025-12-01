import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextInput extends PositionComponent with TapCallbacks, KeyboardHandler {
  final Function(String) onSubmitted;
  final Function()? onCancel;

  String _text = '';
  bool _isActive = false;
  final int maxLength = 20;

  TextInput({
    required this.onSubmitted,
    this.onCancel,
    super.position,
    super.size,
  });

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Fondo del input
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.black.withOpacity(0.3),
    );

    // Borde
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()
        ..color = _isActive ? const Color(0xFF4CAF50) : const Color(0xFF666666)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Texto o placeholder
    final displayText = _text.isEmpty ? 'Escribe aquí...' : _text;
    final textColor = _text.isEmpty ? const Color(0xFF888888) : Colors.white;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: 18,
      fontFamily: 'Arial',
    );

    final textPaint = TextPaint(style: textStyle);
    final textPosition = Vector2(10, (size.y - 18) / 2);

    textPaint.render(canvas, displayText, textPosition);

    // Indicador de cursor cuando está activo
    if (_isActive) {
      final textWidth = _measureTextWidth(displayText, textStyle);
      final cursorX = textPosition.x + textWidth;
      canvas.drawRect(
        Rect.fromLTWH(cursorX, textPosition.y, 2, 18),
        Paint()..color = Colors.white,
      );
    }
  }

  // Método auxiliar para medir el ancho del texto
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
    _isActive = true;
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!_isActive) return false;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_text.isNotEmpty) {
          _text = _text.substring(0, _text.length - 1);
          return true;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_text.trim().isNotEmpty) {
          onSubmitted(_text.trim());
          _text = '';
          _isActive = false;
        }
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _isActive = false;
        onCancel?.call();
        return true;
      } else if (event.character != null && event.character!.isNotEmpty) {
        final char = event.character!;
        if (_text.length < maxLength &&
            RegExp(r'^[a-zA-Z0-9 ]$').hasMatch(char)) {
          _text += char;
          return true;
        }
      }
    }
    return false;
  }

  void setActive(bool active) {
    _isActive = active;
  }

  // Método para enviar el texto (para usar desde el botón)
  void submit() {
    if (_text.trim().isNotEmpty) {
      onSubmitted(_text.trim());
      _text = '';
      _isActive = false;
    }
  }

  // Getter para acceder al texto desde fuera
  String get currentText => _text;
}
