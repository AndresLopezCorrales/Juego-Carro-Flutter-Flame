import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flutter/painting.dart';
import '../main.dart';

class GameOverScreen extends PositionComponent
    with HasGameRef<MyGame>, TapCallbacks {
  late TextPaint titlePaint;
  late TextPaint scorePaint;
  late TextPaint highScorePaint;
  late TextPaint buttonPaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    position = Vector2.zero();
    priority = 1000;
    _setupTextPaints();
  }

  void _setupTextPaints() {
    final double baseSize = _calculateBaseFontSize();

    titlePaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.red.color,
        fontSize: baseSize * 2.2, // Título grande
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

    scorePaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: baseSize * 1.4, // Puntuación destacada
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

    highScorePaint = TextPaint(
      style: TextStyle(
        color: Color(0xFFFFD700), // Dorado
        fontSize: baseSize * 1.2, // High score
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

    buttonPaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: baseSize * 1.3, // Texto del botón
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
    // Usar el menor entre ancho y alto para asegurar legibilidad
    final double screenMin = size.x < size.y ? size.x : size.y;

    if (screenMin < 400) {
      // Pantallas muy pequeñas (móviles en portrait)
      return 16.0;
    } else if (screenMin < 600) {
      // Pantallas pequeñas
      return 18.0;
    } else if (screenMin < 800) {
      // Pantallas medianas
      return 20.0;
    } else if (screenMin < 1200) {
      // Pantallas grandes
      return 22.0;
    } else {
      // Pantallas muy grandes
      return 24.0;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    position = Vector2.zero();
    _setupTextPaints(); // Recalcular tamaños al cambiar tamaño
  }

  @override
  void render(Canvas canvas) {
    // Fondo semitransparente
    final backgroundRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      backgroundRect,
      Paint()..color = BasicPalette.black.color.withOpacity(0.85),
    );

    // Título GAME OVER - Centrado
    final titleText = 'GAME OVER';
    final titleSize = _measureText(titleText, titlePaint);
    final titleX = (size.x - titleSize.x) / 2;
    final titleY = size.y * 0.2;

    titlePaint.render(canvas, titleText, Vector2(titleX, titleY));

    // Puntuación final - Centrado
    final scoreText = 'Puntuación: ${gameRef.score}';
    final scoreSize = _measureText(scoreText, scorePaint);
    final scoreX = (size.x - scoreSize.x) / 2;
    final scoreY = titleY + titleSize.y + size.y * 0.08;

    scorePaint.render(canvas, scoreText, Vector2(scoreX, scoreY));

    // High Score - Centrado
    final highScoreText = 'Mejor Puntuación Global: ${gameRef.globalHighScore}';
    final highScoreSize = _measureText(highScoreText, highScorePaint);
    final highScoreX = (size.x - highScoreSize.x) / 2;
    final highScoreY = scoreY + scoreSize.y + size.y * 0.04;

    highScorePaint.render(
      canvas,
      highScoreText,
      Vector2(highScoreX, highScoreY),
    );

    // Botón para regresar al menú - Centrado
    _renderButton(canvas, 'VOLVER AL MENÚ', size.y * 0.65, Color(0xFF2196F3));
  }

  void _renderButton(Canvas canvas, String text, double y, Color color) {
    final buttonTextSize = _measureText(text, buttonPaint);

    // Tamaños responsivos del botón
    final buttonWidth = size.x * 0.5; // 50% del ancho de pantalla
    final buttonHeight = size.y * 0.07; // 7% del alto de pantalla
    final minButtonWidth = 200.0; // Ancho mínimo
    final minButtonHeight = 55.0; // Alto mínimo

    final finalButtonWidth = buttonWidth > minButtonWidth
        ? buttonWidth
        : minButtonWidth;
    final finalButtonHeight = buttonHeight > minButtonHeight
        ? buttonHeight
        : minButtonHeight;

    final buttonX = (size.x - finalButtonWidth) / 2;
    final buttonY = y;

    // Fondo del botón con bordes redondeados
    final buttonRect = Rect.fromLTWH(
      buttonX,
      buttonY,
      finalButtonWidth,
      finalButtonHeight,
    );

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
        ..strokeWidth = finalButtonHeight * 0.04, // Responsivo
    );

    // Texto del botón - Centrado
    final buttonTextX = buttonX + (finalButtonWidth - buttonTextSize.x) / 2;
    final buttonTextY = buttonY + (finalButtonHeight - buttonTextSize.y) / 2;

    buttonPaint.render(canvas, text, Vector2(buttonTextX, buttonTextY));
  }

  // Método para medir el tamaño del texto
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

    // Botón VOLVER AL MENÚ - Misma lógica de cálculo que en render
    final buttonWidth = size.x * 0.5;
    final buttonHeight = size.y * 0.07;
    final minButtonWidth = 200.0;
    final minButtonHeight = 55.0;

    final finalButtonWidth = buttonWidth > minButtonWidth
        ? buttonWidth
        : minButtonWidth;
    final finalButtonHeight = buttonHeight > minButtonHeight
        ? buttonHeight
        : minButtonHeight;

    final buttonX = (size.x - finalButtonWidth) / 2;
    final buttonY = size.y * 0.65;

    if (tapPosition.x >= buttonX &&
        tapPosition.x <= buttonX + finalButtonWidth &&
        tapPosition.y >= buttonY &&
        tapPosition.y <= buttonY + finalButtonHeight) {
      gameRef.goToStartScreen();
    }
  }
}
