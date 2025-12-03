import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;

// Límite máximo de caracteres.
const int _maxTextLength = 20;

/// Componente de entrada de texto para Desktop/Web (manejo manual de eventos de teclado).
class TextInputDesktop extends PositionComponent
    with TapCallbacks, KeyboardHandler {
  final Function(String) onSubmitted;
  final VoidCallback? onCancel;

  String text = '';
  bool isFocused = false;
  double cursorTimer = 0;
  bool showCursor = true;

  late TextPaint textPaint;
  late TextPaint placeholderPaint;

  TextInputDesktop({
    required this.onSubmitted,
    this.onCancel,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // (Estilos omitidos por brevedad, son idénticos a la versión móvil)
    textPaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontFamily: 'Arial',
      ),
    );
    placeholderPaint = TextPaint(
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 20,
        fontFamily: 'Arial',
      ),
    );
  }

  @override
  void update(double dt) {
    if (isFocused) {
      cursorTimer += dt;
      if (cursorTimer >= 0.5) {
        showCursor = !showCursor;
        cursorTimer = 0;
      }
    }
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    // Implementación de renderizado idéntica (fondo, borde, texto, cursor)
    final inputRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inputRect, const Radius.circular(8)),
      Paint()
        ..color = isFocused ? const Color(0xFF333333) : const Color(0xFF222222),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(inputRect, const Radius.circular(8)),
      Paint()
        ..color = isFocused ? Colors.cyan : Colors.white54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final displayText = text.isEmpty ? 'Ingresa tu nombre...' : text;
    final paint = text.isEmpty ? placeholderPaint : textPaint;

    final textPosition = Vector2(15, (size.y - 20) / 2);
    paint.render(canvas, displayText, textPosition);

    if (isFocused && showCursor) {
      final textWidth = text.isEmpty ? 0.0 : _measureTextWidth(text);
      const cursorOffset = 2.0;
      canvas.drawLine(
        Offset(15 + textWidth + cursorOffset, (size.y - 20) / 2),
        Offset(15 + textWidth + cursorOffset, (size.y + 20) / 2),
        Paint()
          ..color = Colors.cyan
          ..strokeWidth = 2.0,
      );
    }
    super.render(canvas);
  }

  double _measureTextWidth(String text) {
    final textSpan = TextSpan(text: text, style: textPaint.style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }

  @override
  void onTapDown(TapDownEvent event) {
    focus();
  }

  void focus() {
    if (isFocused) return;
    isFocused = true;
    showCursor = true;
    cursorTimer = 0;
    // No se adjunta TextInputConnection en desktop
  }

  void unfocus() {
    isFocused = false;
  }

  // Manejo del teclado físico: implementa toda la lógica aquí
  @override
  bool onKeyEvent(
    services.KeyEvent event,
    Set<services.LogicalKeyboardKey> keysPressed,
  ) {
    if (!isFocused) return false;

    if (event is services.KeyDownEvent || event is services.KeyRepeatEvent) {
      final key = event.logicalKey;

      if (key == services.LogicalKeyboardKey.enter ||
          key == services.LogicalKeyboardKey.numpadEnter) {
        submit();
        return true;
      }

      if (key == services.LogicalKeyboardKey.escape) {
        cancel();
        return true;
      }

      // 1. Backspace para borrar
      if (key == services.LogicalKeyboardKey.backspace) {
        if (text.isNotEmpty) {
          text = text.substring(0, text.length - 1);
        }
        return true;
      }

      // 2. Caracteres imprimibles
      final character = event.character;
      if (character != null && character.length == 1) {
        if (_isValidCharacter(character)) {
          if (text.length < _maxTextLength) {
            text += character;
          }
          return true;
        }
      }
    }

    // Devolvemos false para que otros componentes puedan capturar teclas que no procesamos.
    return false;
  }

  bool _isValidCharacter(String char) {
    // Permitir letras, números, espacios y caracteres especiales de uso común, incluyendo acentos.
    final validPattern = RegExp(r'^[a-zA-Z0-9\s\-_\.áéíóúÁÉÍÓÚñÑüÜ]$');
    return validPattern.hasMatch(char);
  }

  void submit() {
    if (text.trim().length >= 3) {
      unfocus();
      onSubmitted(text.trim());
    }
  }

  void cancel() {
    unfocus();
    text = '';
    if (onCancel != null) {
      onCancel!();
    }
  }
}
