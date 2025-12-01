import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import '../main.dart';

class OptionsScreen extends PositionComponent
    with HasGameRef<MyGame>, TapCallbacks {
  late TextPaint titlePaint;
  late TextPaint optionPaint;
  late TextPaint buttonPaint;

  // Áreas
  late Rect _titleArea;
  late Rect _orientationArea;
  late Rect _orientationButtonArea;
  late Rect _backButtonArea;

  // Notifier para forzar repintado
  final ValueNotifier<bool> _refreshNotifier = ValueNotifier<bool>(false);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    position = Vector2.zero();
    _setupTextPaints();
    _calculateAreas();
  }

  void _calculateAreas() {
    final double screenHeight = size.y;
    final double screenWidth = size.x;

    // Título
    _titleArea = Rect.fromLTWH(
      0,
      screenHeight * 0.1,
      screenWidth,
      screenHeight * 0.15,
    );

    // Área de orientación (texto)
    _orientationArea = Rect.fromLTWH(
      0,
      _titleArea.bottom + screenHeight * 0.05,
      screenWidth,
      screenHeight * 0.1,
    );

    // Botón de orientación
    _orientationButtonArea = Rect.fromLTWH(
      0,
      _orientationArea.bottom + screenHeight * 0.02,
      screenWidth,
      screenHeight * 0.15,
    );

    // Botón de regresar
    _backButtonArea = Rect.fromLTWH(
      0,
      screenHeight * 0.8,
      screenWidth,
      screenHeight * 0.1,
    );
  }

  void _setupTextPaints() {
    final double baseSize = _calculateBaseFontSize();

    titlePaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: baseSize * 1.8,
        fontFamily: 'Arial',
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: BasicPalette.black.color,
            blurRadius: 8.0,
            offset: Offset(3.0, 3.0),
          ),
        ],
      ),
    );

    optionPaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: baseSize * 1.0,
        fontFamily: 'Arial',
        fontWeight: FontWeight.normal,
        shadows: [
          Shadow(
            color: BasicPalette.black.color,
            blurRadius: 4.0,
            offset: Offset(2.0, 2.0),
          ),
        ],
      ),
    );

    buttonPaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: baseSize * 1.2,
        fontFamily: 'Arial',
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: BasicPalette.black.color,
            blurRadius: 6.0,
            offset: Offset(2.0, 2.0),
          ),
        ],
      ),
    );
  }

  double _calculateBaseFontSize() {
    final double screenMin = size.x < size.y ? size.x : size.y;

    if (screenMin < 400)
      return 16.0;
    else if (screenMin < 600)
      return 18.0;
    else if (screenMin < 800)
      return 20.0;
    else if (screenMin < 1200)
      return 22.0;
    else
      return 24.0;
  }

  @override
  void render(Canvas canvas) {
    // Leer el notifier para forzar repintado cuando cambie
    final _ = _refreshNotifier.value;

    super.render(canvas);

    // Fondo semitransparente
    final backgroundRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      backgroundRect,
      Paint()..color = BasicPalette.black.color.withOpacity(0.9),
    );

    _renderTitleSection(canvas);
    _renderOrientationSection(canvas);
    _renderOrientationButtonSection(canvas);
    _renderBackButtonSection(canvas);
  }

  void _renderTitleSection(Canvas canvas) {
    final titleText = 'OPCIONES';
    final titleSize = _measureText(titleText, titlePaint);
    final titleX = _titleArea.center.dx - (titleSize.x / 2);
    final titleY = _titleArea.center.dy - (titleSize.y / 2);

    titlePaint.render(canvas, titleText, Vector2(titleX, titleY));
  }

  void _renderOrientationSection(Canvas canvas) {
    final optionText = 'ORIENTACIÓN DE JUEGO';
    final optionSize = _measureText(optionText, optionPaint);
    final optionX = _orientationArea.center.dx - (optionSize.x / 2);
    final optionY = _orientationArea.center.dy - (optionSize.y / 2);

    optionPaint.render(canvas, optionText, Vector2(optionX, optionY));
  }

  void _renderOrientationButtonSection(Canvas canvas) {
    // Usar el estado ACTUAL del juego para mostrar el texto correcto
    final buttonText = gameRef.isHorizontalMode ? 'HORIZONTAL' : 'VERTICAL';
    _renderButtonInArea(
      canvas,
      buttonText,
      _orientationButtonArea,
      Color(0x804CAF50),
    );
  }

  void _renderBackButtonSection(Canvas canvas) {
    _renderButtonInArea(canvas, 'REGRESAR', _backButtonArea, Color(0x80666666));
  }

  void _renderButtonInArea(Canvas canvas, String text, Rect area, Color color) {
    final buttonTextSize = _measureText(text, buttonPaint);

    // Botón ocupa 50% del ancho
    final double buttonWidth = area.width * 0.5;
    final double buttonHeight = area.height * 0.7;

    final buttonX = area.center.dx - (buttonWidth / 2);
    final buttonY = area.top + (area.height - buttonHeight) / 2;

    // Fondo del botón
    final buttonRect = Rect.fromLTWH(
      buttonX,
      buttonY,
      buttonWidth,
      buttonHeight,
    );

    // Botón con bordes redondeados
    final buttonRadius = Radius.circular(buttonHeight * 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, buttonRadius),
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0),
    );

    // Borde del botón
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, buttonRadius),
      Paint()
        ..color = BasicPalette.white.color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Texto del botón
    final buttonTextX = buttonX + (buttonWidth - buttonTextSize.x) / 2;
    final buttonTextY = buttonY + (buttonHeight - buttonTextSize.y) / 2;

    buttonPaint.render(canvas, text, Vector2(buttonTextX, buttonTextY));
  }

  Vector2 _measureText(String text, TextPaint textPaint) {
    final textStyle = textPaint.style;
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return Vector2(textPainter.width, textPainter.height);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    final tapPosition = event.localPosition;

    // Verificar si se tocó el botón de orientación
    if (_orientationButtonArea.contains(tapPosition.toOffset())) {
      _toggleOrientation();
    }
    // Verificar si se tocó el botón de regresar
    else if (_backButtonArea.contains(tapPosition.toOffset())) {
      _goBackToStartScreen();
    }
  }

  void _toggleOrientation() {
    // Cambiar la orientación DIRECTAMENTE en el juego
    bool newOrientation = !gameRef.isHorizontalMode;
    gameRef.setHorizontalMode(newOrientation);

    // Forzar repintado inmediato usando el notifier
    _refreshNotifier.value = !_refreshNotifier.value;

    print(
      'Orientación cambiada a: ${newOrientation ? 'HORIZONTAL' : 'VERTICAL'}',
    );

    // Guardar inmediatamente después del cambio
    gameRef
        .saveOrientationPreference(); // Llamar directamente al método de guardado
  }

  void _goBackToStartScreen() {
    // Remover esta pantalla y volver a la pantalla de inicio
    gameRef.remove(this);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    position = Vector2.zero();
    _calculateAreas();
    _setupTextPaints();
  }

  @override
  void onRemove() {
    _refreshNotifier.dispose();
    super.onRemove();
  }
}
