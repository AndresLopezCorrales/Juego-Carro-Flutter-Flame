// lib/screens/credits_screen.dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

class CreditsScreen extends PositionComponent
    with HasGameRef<MyGame>, TapCallbacks, DragCallbacks, KeyboardHandler {
  late TextPaint titlePaint;
  late TextPaint sectionTitlePaint;
  late TextPaint contentPaint;
  late TextPaint buttonPaint;

  // Control de scroll
  double scrollOffset = 0.0;
  double maxScrollOffset = 0.0;

  // Contenido de créditos
  final List<CreditSection> sections = [
    CreditSection(
      title: "CREADORES DEL JUEGO",
      items: [
        "Andrés López Corrales",
        "Ingrid Z. Mendoza Dórame",
        "Sebastián Pérez Gonzalez",
      ],
    ),
    CreditSection(
      title: "AGRADECIMIENTOS ESPECIALES",
      items: [
        "Prof. Federico Miguel Cirett Galan",
        "Compañeros de Clase - Por el apoyo",
      ],
    ),
    CreditSection(
      title: "TECNOLOGÍAS UTILIZADAS",
      items: [
        "Flame Game Engine - Motor de juegos",
        "Flutter SDK - Framework multiplataforma",
        "Supabase - Base de datos en la nube",
        "Visual Studio Code - Editor de código",
      ],
    ),
    CreditSection(
      title: "RECURSOS Y REFERENCIAS",
      items: [
        "Documentación oficial de Flame",
        "Tutoriales de desarrollo de juegos",
        "Assets de OpenGameArt.org",
        "Assets de Freepik.com",
        "Assets de Shutterstock.com",
        "Música de Freesound.org",
      ],
    ),
    CreditSection(
      title: "INSPIRACIÓN",
      items: ["Crear un juego en Flutter-Flame"],
    ),
    CreditSection(
      title: "GITHUB",
      items: [
        "Andrés: https://github.com/AndresLopezCorrales",
        "Ingrid: https://github.com/ingridzmendoza",
        "Sebas: https://github.com/SeaBassy4",
      ],
    ),
  ];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    position = Vector2.zero();
    priority = 1000;
    _setupTextPaints();
    _calculateMaxScroll();
  }

  void _setupTextPaints() {
    final double baseSize = _calculateBaseFontSize();
    final bool isHorizontal = size.x > size.y;

    titlePaint = TextPaint(
      style: TextStyle(
        color: Color(0xFF4FC3F7),
        fontSize: isHorizontal ? baseSize * 1.6 : baseSize * 2.0,
        fontFamily: 'Arial',
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 6.0,
            offset: Offset(2.0, 2.0),
          ),
        ],
      ),
    );

    sectionTitlePaint = TextPaint(
      style: TextStyle(
        color: Color(0xFFFF9800),
        fontSize: isHorizontal ? baseSize * 1.1 : baseSize * 1.4,
        fontFamily: 'Arial',
        fontWeight: FontWeight.w700,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4.0,
            offset: Offset(1.0, 1.0),
          ),
        ],
      ),
    );

    contentPaint = TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: isHorizontal ? baseSize * 0.9 : baseSize * 1.1,
        fontFamily: 'Arial',
        fontWeight: FontWeight.w500,
      ),
    );

    buttonPaint = TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: isHorizontal ? baseSize * 1.0 : baseSize * 1.3,
        fontFamily: 'Arial',
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: Colors.black,
            blurRadius: 4.0,
            offset: Offset(2.0, 2.0),
          ),
        ],
      ),
    );
  }

  double _calculateBaseFontSize() {
    final double screenMin = size.x < size.y ? size.x : size.y;

    if (screenMin < 400) return 14.0;
    if (screenMin < 600) return 16.0;
    if (screenMin < 800) return 18.0;
    if (screenMin < 1200) return 20.0;
    return 22.0;
  }

  void _calculateMaxScroll() {
    final bool isHorizontal = size.x > size.y;
    double totalHeight = isHorizontal ? size.y * 0.10 : size.y * 0.15;

    for (final section in sections) {
      totalHeight += isHorizontal ? size.y * 0.12 : size.y * 0.08;
      totalHeight +=
          (section.items.length *
          (isHorizontal ? size.y * 0.08 : size.y * 0.05));
      totalHeight += isHorizontal ? size.y * 0.05 : size.y * 0.03;
    }

    totalHeight += isHorizontal ? size.y * 0.20 : size.y * 0.25;

    final visibleHeight = size.y;
    maxScrollOffset = (totalHeight - visibleHeight).clamp(0.0, double.infinity);
    scrollOffset = scrollOffset.clamp(0.0, maxScrollOffset);
  }

  @override
  void render(Canvas canvas) {
    // Fondo con degradado
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0A0E21), Color(0xFF1A237E), Color(0xFF311B92)],
    );
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Guardar estado del canvas para aplicar scroll
    canvas.save();
    canvas.translate(0, -scrollOffset);

    final bool isHorizontal = size.x > size.y;

    // Título "CRÉDITOS"
    final titleText = 'CRÉDITOS';
    final titleSize = _measureText(titleText, titlePaint);
    final titleX = (size.x - titleSize.x) / 2;
    final titleY = isHorizontal ? size.y * 0.08 : size.y * 0.1;

    titlePaint.render(canvas, titleText, Vector2(titleX, titleY));

    // Línea decorativa bajo el título
    final lineY = titleY + titleSize.y + 10;
    canvas.drawLine(
      Offset(size.x * 0.2, lineY),
      Offset(size.x * 0.8, lineY),
      Paint()
        ..color = Color(0xFF4FC3F7)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Renderizar secciones
    double currentY =
        titleY + titleSize.y + (isHorizontal ? size.y * 0.08 : size.y * 0.05);

    for (final section in sections) {
      // Título de sección
      final sectionTitleSize = _measureText(section.title, sectionTitlePaint);
      final sectionTitleX = (size.x - sectionTitleSize.x) / 2;

      sectionTitlePaint.render(
        canvas,
        section.title,
        Vector2(sectionTitleX, currentY),
      );

      currentY +=
          sectionTitleSize.y + (isHorizontal ? size.y * 0.03 : size.y * 0.02);

      // Items de la sección
      for (final item in section.items) {
        final itemSize = _measureText(item, contentPaint);
        final itemX = (size.x - itemSize.x) / 2;

        contentPaint.render(canvas, item, Vector2(itemX, currentY));
        currentY += itemSize.y + (isHorizontal ? size.y * 0.03 : size.y * 0.02);
      }

      currentY += isHorizontal ? size.y * 0.05 : size.y * 0.03;

      // Línea separadora
      if (section != sections.last) {
        canvas.drawLine(
          Offset(size.x * 0.3, currentY),
          Offset(size.x * 0.7, currentY),
          Paint()
            ..color = Colors.white.withOpacity(0.3)
            ..strokeWidth = 1.0,
        );
        currentY += isHorizontal ? size.y * 0.03 : size.y * 0.02;
      }
    }

    // Mensaje final
    final finalText = '¡Gracias por jugar!';
    final finalTextSize = _measureText(finalText, sectionTitlePaint);
    final finalTextX = (size.x - finalTextSize.x) / 2;

    sectionTitlePaint.render(
      canvas,
      finalText,
      Vector2(
        finalTextX,
        currentY + (isHorizontal ? size.y * 0.08 : size.y * 0.05),
      ),
    );

    canvas.restore();

    // Botón VOLVER - Siempre visible
    _renderButton(canvas);

    // Indicador de scroll
    if (maxScrollOffset > 0) {
      _renderScrollIndicator(canvas);
    }
  }

  void _renderButton(Canvas canvas) {
    final bool isHorizontal = size.x > size.y;
    final buttonText = '← VOLVER';
    final buttonTextSize = _measureText(buttonText, buttonPaint);

    final buttonWidth = isHorizontal ? 140.0 : 160.0;
    final buttonHeight = isHorizontal ? 45.0 : 55.0;
    final buttonX = 20.0;
    final buttonY = 20.0;

    final buttonRect = Rect.fromLTWH(
      buttonX,
      buttonY,
      buttonWidth,
      buttonHeight,
    );
    final buttonRadius = Radius.circular(buttonHeight * 0.3);

    // Fondo del botón
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, buttonRadius),
      Paint()..color = Color(0xFF2196F3),
    );

    // Borde del botón
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, buttonRadius),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Texto del botón
    final buttonTextX = buttonX + (buttonWidth - buttonTextSize.x) / 2;
    final buttonTextY = buttonY + (buttonHeight - buttonTextSize.y) / 2;
    buttonPaint.render(canvas, buttonText, Vector2(buttonTextX, buttonTextY));
  }

  void _renderScrollIndicator(Canvas canvas) {
    final double indicatorHeight = 60.0;
    final double indicatorWidth = 6.0;
    final double trackHeight = size.y - 100;

    // Track del scroll
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x - 15, 50, indicatorWidth, trackHeight),
        Radius.circular(3.0),
      ),
      Paint()..color = Colors.white.withOpacity(0.2),
    );

    // Posición del indicador
    final scrollPercentage = maxScrollOffset > 0
        ? scrollOffset / maxScrollOffset
        : 0.0;
    final indicatorY =
        50 + (scrollPercentage * (trackHeight - indicatorHeight));

    // Indicador
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x - 15, indicatorY, indicatorWidth, indicatorHeight),
        Radius.circular(3.0),
      ),
      Paint()..color = Color(0xFF4FC3F7),
    );
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
    final tapPosition = event.localPosition;

    // Verificar botón VOLVER
    final buttonWidth = size.x > size.y ? 140.0 : 160.0;
    final buttonHeight = size.x > size.y ? 45.0 : 55.0;
    final buttonRect = Rect.fromLTWH(20, 20, buttonWidth, buttonHeight);

    if (buttonRect.contains(tapPosition.toOffset())) {
      removeFromParent();
      gameRef.goToStartScreen();
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (maxScrollOffset > 0) {
      scrollOffset = (scrollOffset - event.localDelta.y).clamp(
        0.0,
        maxScrollOffset,
      );
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        scrollOffset = (scrollOffset + 30).clamp(0.0, maxScrollOffset);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        scrollOffset = (scrollOffset - 30).clamp(0.0, maxScrollOffset);
      } else if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.backspace) {
        removeFromParent();
        gameRef.goToStartScreen();
      }
    }
    return true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    position = Vector2.zero();
    _setupTextPaints();
    _calculateMaxScroll();
  }
}

class CreditSection {
  final String title;
  final List<String> items;

  CreditSection({required this.title, required this.items});
}
