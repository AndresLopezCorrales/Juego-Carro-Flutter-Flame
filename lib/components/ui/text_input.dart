import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;

class TextInput extends PositionComponent with TapCallbacks {
  final Function(String) onSubmitted;
  final VoidCallback? onCancel;

  String text = '';
  bool isFocused = false;
  double cursorTimer = 0;
  bool showCursor = true;

  late TextPaint textPaint;
  late TextPaint placeholderPaint;

  // Cliente de entrada de texto para teclado móvil
  services.TextInputConnection? _textInputConnection;

  TextInput({
    required this.onSubmitted,
    this.onCancel,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

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
    super.update(dt);

    if (isFocused) {
      cursorTimer += dt;
      if (cursorTimer >= 0.5) {
        showCursor = !showCursor;
        cursorTimer = 0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Fondo del input
    final inputRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inputRect, const Radius.circular(8)),
      Paint()
        ..color = isFocused ? const Color(0xFF333333) : const Color(0xFF222222),
    );

    // Borde
    canvas.drawRRect(
      RRect.fromRectAndRadius(inputRect, const Radius.circular(8)),
      Paint()
        ..color = isFocused ? Colors.cyan : Colors.white54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Texto o placeholder
    final displayText = text.isEmpty ? 'Ingresa tu nombre...' : text;
    final paint = text.isEmpty ? placeholderPaint : textPaint;

    final textPosition = Vector2(15, (size.y - 20) / 2);
    paint.render(canvas, displayText, textPosition);

    // Cursor parpadeante
    if (isFocused && showCursor && text.isNotEmpty) {
      final textWidth = _measureTextWidth(text);
      canvas.drawLine(
        Offset(15 + textWidth + 2, (size.y - 20) / 2),
        Offset(15 + textWidth + 2, (size.y + 20) / 2),
        Paint()
          ..color = Colors.cyan
          ..strokeWidth = 2.0,
      );
    }
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

    // Abrir teclado virtual en móviles
    _attachTextInputClient();
  }

  void unfocus() {
    isFocused = false;
    _detachTextInputClient();
  }

  void _attachTextInputClient() {
    final client = _TextInputClient(
      onTextChanged: (newText) {
        text = newText;
        if (text.length > 20) {
          text = text.substring(0, 20);
        }
      },
      onSubmitted: (submittedText) {
        submit();
      },
    );

    _textInputConnection = services.TextInput.attach(
      client,
      const services.TextInputConfiguration(
        inputType: TextInputType.text,
        inputAction: TextInputAction.done,
        autocorrect: false,
        enableSuggestions: false,
      ),
    );

    _textInputConnection?.show();
    _textInputConnection?.setEditingState(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
  }

  void _detachTextInputClient() {
    _textInputConnection?.close();
    _textInputConnection = null;
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

  @override
  void onRemove() {
    _detachTextInputClient();
    super.onRemove();
  }
}

// Cliente de entrada de texto personalizado
class _TextInputClient implements services.TextInputClient {
  final Function(String) onTextChanged;
  final Function(String) onSubmitted;

  _TextInputClient({required this.onTextChanged, required this.onSubmitted});

  @override
  services.AutofillScope? get currentAutofillScope => null;

  @override
  TextEditingValue? get currentTextEditingValue => null;

  @override
  void performAction(services.TextInputAction action) {
    if (action == services.TextInputAction.done) {
      onSubmitted('');
    }
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void updateEditingValue(TextEditingValue value) {
    onTextChanged(value.text);
  }

  @override
  void updateFloatingCursor(services.RawFloatingCursorPoint point) {}

  @override
  void connectionClosed() {}

  @override
  void showToolbar() {}

  @override
  void insertTextPlaceholder(Size size) {}

  @override
  void removeTextPlaceholder() {}

  @override
  void performSelector(String selectorName) {}

  @override
  void insertContent(services.KeyboardInsertedContent content) {}

  @override
  void didChangeInputControl(
    services.TextInputControl? oldControl,
    services.TextInputControl? newControl,
  ) {}
}
