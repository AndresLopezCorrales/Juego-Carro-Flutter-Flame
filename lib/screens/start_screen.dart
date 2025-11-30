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
        fontSize: baseSize * 2.2, // Título más grande
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
        fontSize: baseSize * 1.1, // Subtítulo
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
    final titleY = size.y * 0.25;

    titlePaint.render(canvas, titleText, Vector2(titleX, titleY));

    // Subtítulo - Centrado
    final subtitleText = 'Toca JUGAR para comenzar';
    final subtitleSize = _measureText(subtitleText, subtitlePaint);
    final subtitleX = (size.x - subtitleSize.x) / 2;
    final subtitleY = titleY + titleSize.y + size.y * 0.05;

    subtitlePaint.render(canvas, subtitleText, Vector2(subtitleX, subtitleY));

    // Botón de jugar - Centrado
    final buttonText = 'JUGAR';
    final buttonTextSize = _measureText(buttonText, buttonPaint);

    // Tamaños responsivos del botón
    final buttonWidth = size.x * 0.4; // 40% del ancho de pantalla
    final buttonHeight = size.y * 0.08; // 8% del alto de pantalla
    final minButtonWidth = 180.0; // Ancho mínimo
    final minButtonHeight = 60.0; // Alto mínimo

    final finalButtonWidth = buttonWidth > minButtonWidth
        ? buttonWidth
        : minButtonWidth;
    final finalButtonHeight = buttonHeight > minButtonHeight
        ? buttonHeight
        : minButtonHeight;

    final buttonX = (size.x - finalButtonWidth) / 2;
    final buttonY = size.y * 0.55;

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
      Paint()..color = Color(0xFF4CAF50), // Verde
    );

    // Borde del botón
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, buttonRadius),
      Paint()
        ..color = BasicPalette.white.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = finalButtonHeight * 0.05, // Responsivo
    );

    // Texto del botón - Centrado
    final buttonTextX = buttonX + (finalButtonWidth - buttonTextSize.x) / 2;
    final buttonTextY = buttonY + (finalButtonHeight - buttonTextSize.y) / 2;

    buttonPaint.render(canvas, buttonText, Vector2(buttonTextX, buttonTextY));
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

    // Calcular posición del botón (misma lógica que en render)
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
    final buttonY = size.y * 0.55;

    // Verificar si se tocó el botón de jugar
    if (tapPosition.x >= buttonX &&
        tapPosition.x <= buttonX + finalButtonWidth &&
        tapPosition.y >= buttonY &&
        tapPosition.y <= buttonY + finalButtonHeight) {
      gameRef.startGame();
    }
  }
}
