import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/painting.dart';
import '../main.dart';

class GameHUD extends PositionComponent with HasGameRef<MyGame> {
  late TextPaint scoreTextPaint;
  late TextPaint fuelTextPaint;
  late TextPaint labelTextPaint;

  GameHUD() {
    _setupTextPaints();
  }

  void _setupTextPaints() {
    scoreTextPaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: 24.0,
        fontFamily: 'Arial',
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: BasicPalette.black.color,
            blurRadius: 4.0,
            offset: Offset(2.0, 2.0),
          ),
        ],
      ),
    );

    fuelTextPaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: 16.0,
        fontFamily: 'Arial',
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: BasicPalette.black.color,
            blurRadius: 3.0,
            offset: Offset(1.0, 1.0),
          ),
        ],
      ),
    );

    labelTextPaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: 14.0,
        fontFamily: 'Arial',
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: BasicPalette.black.color,
            blurRadius: 2.0,
            offset: Offset(1.0, 1.0),
          ),
        ],
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _renderFuelBar(canvas);
    _renderScore(canvas);
  }

  void _renderFuelBar(Canvas canvas) {
    // Dimensiones completamente responsivas
    final double barWidth = size.x * 0.35;
    final double barHeight = size.y * 0.025;
    final double barX = size.x * 0.03;
    final double barY = size.y * 0.04;

    // Fondo de la barra
    final backgroundRect = Rect.fromLTWH(barX, barY, barWidth, barHeight);
    canvas.drawRect(
      backgroundRect,
      Paint()..color = BasicPalette.black.color.withOpacity(0.5),
    );

    // Barra de gasolina (progreso)
    final fuelPercent = gameRef.fuelManager.fuelPercent;
    final fuelWidth = barWidth * fuelPercent.clamp(0.0, 1.0);

    if (fuelWidth > 0) {
      final fuelRect = Rect.fromLTWH(barX, barY, fuelWidth, barHeight);
      canvas.drawRect(fuelRect, Paint()..color = _getFuelColor(fuelPercent));
    }

    // Borde de la barra
    final borderRect = Rect.fromLTWH(barX, barY, barWidth, barHeight);
    canvas.drawRect(
      borderRect,
      Paint()
        ..color = BasicPalette.white.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Texto de porcentaje al lado derecho de la barra
    final fuelPercentText = '${(fuelPercent * 100).toStringAsFixed(0)}%';
    final textX = barX + barWidth + 10.0;
    final textY = barY + (barHeight / 2) - 8.0;

    fuelTextPaint.render(canvas, fuelPercentText, Vector2(textX, textY));
  }

  void _renderScore(Canvas canvas) {
    final scoreText = '${gameRef.score}';
    final labelText = 'PUNTOS:';

    // Posición debajo de la barra de gasolina
    final double barY = size.y * 0.04;
    final double barHeight = size.y * 0.025;

    final double scoreX = size.x * 0.03;
    final double scoreY = barY + barHeight + 15.0;

    // Renderizar etiqueta "PUNTOS:"
    labelTextPaint.render(canvas, labelText, Vector2(scoreX, scoreY));

    // Renderizar el número de puntos (un poco más abajo)
    final pointsY = scoreY + 20.0;
    scoreTextPaint.render(canvas, scoreText, Vector2(scoreX, pointsY));
  }

  Color _getFuelColor(double percent) {
    if (percent > 0.6) {
      return Color(0xFF4CAF50);
    } else if (percent > 0.3) {
      return Color(0xFFFFC107);
    } else {
      return Color(0xFFF44336);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    // El HUD siempre ocupa toda la pantalla
    this.size = size;
    position = Vector2.zero();

    _adjustTextSizes();
  }

  void _adjustTextSizes() {
    // Tamaño base responsivo - se hace más grande en pantallas pequeñas
    final double baseSize = _calculateBaseFontSize();

    scoreTextPaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: baseSize * 1.2,
        fontFamily: 'Arial',
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: BasicPalette.black.color,
            blurRadius: 4.0,
            offset: Offset(2.0, 2.0),
          ),
        ],
      ),
    );

    fuelTextPaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: baseSize * 0.9,
        fontFamily: 'Arial',
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: BasicPalette.black.color,
            blurRadius: 3.0,
            offset: Offset(1.0, 1.0),
          ),
        ],
      ),
    );

    labelTextPaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: baseSize,
        fontFamily: 'Arial',
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: BasicPalette.black.color,
            blurRadius: 2.0,
            offset: Offset(1.0, 1.0),
          ),
        ],
      ),
    );
  }

  double _calculateBaseFontSize() {
    // En pantallas pequeñas, usar un tamaño mínimo más grande
    final double screenDiagonal = size.length;

    if (screenDiagonal < 600) {
      // Pantallas muy pequeñas
      return 28.0;
    } else if (screenDiagonal < 800) {
      // Pantallas medianas
      return 26.0;
    } else if (screenDiagonal < 1200) {
      // Pantallas grandes
      return 24.0;
    } else {
      // Pantallas muy grandes
      return 22.0;
    }
  }
}
