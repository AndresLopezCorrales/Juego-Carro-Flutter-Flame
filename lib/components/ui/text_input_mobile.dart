import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;

class TextInputMobile extends PositionComponent with TapCallbacks {
  final Function(String) onSubmitted;
  final VoidCallback? onCancel;

  String text = '';
  bool isFocused = false;
  double cursorTimer = 0;
  bool showCursor = true;

  late TextPaint textPaint;
  late TextPaint placeholderPaint;

  services.TextInputConnection? _textInputConnection;
  _TextInputClient? _client;

  TextInputMobile({
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

    _attachTextInputClient();
  }

  void unfocus() {
    if (isFocused) {
      isFocused = false;
      _detachTextInputClient();
    }
  }

  void _updateText(String newText) {
    if (newText.length > 20) {
      newText = newText.substring(0, 20);
    }
    text = newText;
  }

  void _attachTextInputClient() {
    _client = _TextInputClient(
      onTextChanged: (newText) {
        _updateText(newText);
      },
      onSubmitted: (submittedText) {
        submit();
      },
      getCurrentText: () => text,
    );

    _textInputConnection = services.TextInput.attach(
      _client!,
      const services.TextInputConfiguration(
        inputType: services.TextInputType.text,
        inputAction: services.TextInputAction.done,
        autocorrect: false,
        enableSuggestions: false,
      ),
    );

    // Asignar la conexión al cliente DESPUÉS de crearla
    _client!._textInputConnection = _textInputConnection;

    _textInputConnection?.show();
    _textInputConnection?.setEditingState(
      services.TextEditingValue(
        text: text,
        selection: services.TextSelection.collapsed(offset: text.length),
      ),
    );
  }

  void _detachTextInputClient() {
    if (_textInputConnection != null) {
      _textInputConnection?.close();
      _textInputConnection = null;
      _client = null;
    }
  }

  void submit() {
    final trimmedText = text.trim();
    if (trimmedText.length >= 3) {
      unfocus();
      onSubmitted(trimmedText);
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

class _TextInputClient implements services.TextInputClient {
  final Function(String) onTextChanged;
  final Function(String) onSubmitted;
  final String Function() getCurrentText;

  services.TextEditingValue _currentValue = const services.TextEditingValue();
  services.TextInputConnection? _textInputConnection;

  _TextInputClient({
    required this.onTextChanged,
    required this.onSubmitted,
    required this.getCurrentText,
  });

  @override
  services.AutofillScope? get currentAutofillScope => null;

  @override
  services.TextEditingValue? get currentTextEditingValue => _currentValue;

  @override
  void performAction(services.TextInputAction action) {
    if (action == services.TextInputAction.done) {
      onSubmitted(getCurrentText());
    }
  }

  @override
  void updateEditingValue(services.TextEditingValue value) {
    // PRIMERO: Actualizar el valor actual con lo que viene del teclado
    _currentValue = value;

    String newText = value.text;
    bool needsSync = false;

    // Validar caracteres
    final validPattern = RegExp(r'^[a-zA-Z0-9\s\-_\.áéíóúÁÉÍÓÚñÑüÜ]*$');
    if (!validPattern.hasMatch(newText)) {
      newText = newText
          .split('')
          .where((char) {
            return RegExp(r'^[a-zA-Z0-9\s\-_\.áéíóúÁÉÍÓÚñÑüÜ]$').hasMatch(char);
          })
          .join('');
      needsSync = true;
    }

    // Límite de longitud
    if (newText.length > 20) {
      newText = newText.substring(0, 20);
      needsSync = true;
    }

    // Si el texto cambió por validación, sincronizar de vuelta
    if (needsSync && newText != value.text) {
      _currentValue = services.TextEditingValue(
        text: newText,
        selection: services.TextSelection.collapsed(offset: newText.length),
      );
      // Sincronizar con el teclado virtual
      _textInputConnection?.setEditingState(_currentValue);
    }

    onTextChanged(newText);
  }

  @override
  void connectionClosed() {
    _currentValue = const services.TextEditingValue();
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void updateFloatingCursor(services.RawFloatingCursorPoint point) {}

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
