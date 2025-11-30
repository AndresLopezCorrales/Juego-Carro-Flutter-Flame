import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flutter/painting.dart';
import '../main.dart';

class StartScreen extends PositionComponent
    with HasGameRef<MyGame>, TapCallbacks {
  late TextPaint titlePaint;
  late TextPaint subtitlePaint;
  late TextPaint buttonPaint;
  late TextPaint modeButtonPaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    position = Vector2.zero();
    _setupTextPaints();
  }

  void _setupTextPaints() {
    final double baseSize = _calculateBaseFontSize();

    titlePaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: baseSize * 2.2,
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

    subtitlePaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: baseSize * 1.1,
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
        fontSize: baseSize * 1.3,
        fontFamily: 'Arial',
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: BasicPalette.black.color,
            blurRadius: 4.0,
            offset: Offset(2.0, 2.0),
          ),
        ],
      ),
    );

    modeButtonPaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: baseSize * 1.0,
        fontFamily: 'Arial',
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: BasicPalette.black.color,
            blurRadius: 4.0,
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
    super.render(canvas);

    // Fondo semitransparente
    final backgroundRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      backgroundRect,
      Paint()..color = BasicPalette.black.color.withOpacity(0.8),
    );

    // Título del juego - Centrado
    final titleText = 'SLIDE ROAD';
    final titleSize = _measureText(titleText, titlePaint);
    final titleX = (size.x - titleSize.x) / 2;
    final titleY = size.y * 0.2;

    titlePaint.render(canvas, titleText, Vector2(titleX, titleY));

    // Subtítulo - Centrado
    final subtitleText = 'Toca JUGAR para comenzar';
    final subtitleSize = _measureText(subtitleText, subtitlePaint);
    final subtitleX = (size.x - subtitleSize.x) / 2;
    final subtitleY = titleY + titleSize.y + size.y * 0.05;

    subtitlePaint.render(canvas, subtitleText, Vector2(subtitleX, subtitleY));

    // Botón de jugar - Centrado
    _renderButton(
      canvas,
      'JUGAR',
      size.y * 0.55,
      Color(0xFF4CAF50),
      buttonPaint,
    );

    // NUEVO: Botón de modo horizontal
    final modeText = gameRef.isHorizontalMode
        ? 'MODO: HORIZONTAL'
        : 'MODO: VERTICAL';
    _renderButton(
      canvas,
      modeText,
      size.y * 0.68,
      Color(0xFF2196F3),
      modeButtonPaint,
    );
  }

  void _renderButton(
    Canvas canvas,
    String text,
    double y,
    Color color,
    TextPaint textPaint,
  ) {
    final buttonTextSize = _measureText(text, textPaint);

    // Tamaños responsivos del botón
    final buttonWidth = size.x * 0.4;
    final buttonHeight = size.y * 0.08;
    final minButtonWidth = 180.0;
    final minButtonHeight = 60.0;

    final finalButtonWidth = buttonWidth > minButtonWidth
        ? buttonWidth
        : minButtonWidth;
    final finalButtonHeight = buttonHeight > minButtonHeight
        ? buttonHeight
        : minButtonHeight;

    final buttonX = (size.x - finalButtonWidth) / 2;
    final buttonY = y;

    // Fondo del botón
    final buttonRect = Rect.fromLTWH(
      buttonX,
      buttonY,
      finalButtonWidth,
      finalButtonHeight,
    );

    // Botón con bordes redondeados
    final buttonRadius = Radius.circular(finalButtonHeight * 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, buttonRadius),
      Paint()..color = color,
    );

    // Borde del botón
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, buttonRadius),
      Paint()
        ..color = BasicPalette.white.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = finalButtonHeight * 0.05,
    );

    // Texto del botón - Centrado
    final buttonTextX = buttonX + (finalButtonWidth - buttonTextSize.x) / 2;
    final buttonTextY = buttonY + (finalButtonHeight - buttonTextSize.y) / 2;

    textPaint.render(canvas, text, Vector2(buttonTextX, buttonTextY));
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

    // Botón JUGAR
    final playButtonWidth = size.x * 0.4;
    final playButtonHeight = size.y * 0.08;
    final playButtonX = (size.x - playButtonWidth) / 2;
    final playButtonY = size.y * 0.55;

    if (tapPosition.x >= playButtonX &&
        tapPosition.x <= playButtonX + playButtonWidth &&
        tapPosition.y >= playButtonY &&
        tapPosition.y <= playButtonY + playButtonHeight) {
      gameRef.startGame();
    }

    // NUEVO: Botón MODO
    final modeButtonWidth = size.x * 0.4;
    final modeButtonHeight = size.y * 0.08;
    final modeButtonX = (size.x - modeButtonWidth) / 2;
    final modeButtonY = size.y * 0.68;

    if (tapPosition.x >= modeButtonX &&
        tapPosition.x <= modeButtonX + modeButtonWidth &&
        tapPosition.y >= modeButtonY &&
        tapPosition.y <= modeButtonY + modeButtonHeight) {
      // Cambiar modo
      gameRef.setHorizontalMode(!gameRef.isHorizontalMode);
      _setupTextPaints(); // Actualizar texto del botón
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    position = Vector2.zero();
    _setupTextPaints();
  }
}
