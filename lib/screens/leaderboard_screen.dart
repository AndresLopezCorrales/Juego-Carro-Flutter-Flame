import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/supabase_service.dart';
import '../models/puntaje.dart';

class LeaderboardScreen extends PositionComponent
    with HasGameRef<MyGame>, TapCallbacks, DragCallbacks {
  late TextPaint titlePaint;
  late TextPaint headerPaint;
  late TextPaint scorePaint;
  late TextPaint userScorePaint;

  late List<Puntaje> topPuntajes = [];
  bool cargando = true;

  // Variables para scroll
  double scrollOffset = 0.0;
  double maxScrollOffset = 0.0;

  // Área scrolleable
  late double scrollAreaStartY;
  late double scrollAreaEndY;

  @override
  Future<void> onLoad() async {
    size = gameRef.size;
    position = Vector2.zero();

    _setupTextPaints();
    _cargarLeaderboard();
  }

  void _setupTextPaints() {
    final double baseSize = _calcularTamanioBaseFuente();

    titlePaint = TextPaint(
      style: TextStyle(
        fontSize: baseSize * 1.8,
        fontWeight: FontWeight.bold,
        color: Colors.yellow,
        fontFamily: 'Arial',
        shadows: [
          Shadow(color: Colors.black, blurRadius: 6, offset: Offset(2, 2)),
        ],
      ),
    );

    headerPaint = TextPaint(
      style: TextStyle(
        fontSize: baseSize * 1.2,
        fontWeight: FontWeight.bold,
        color: Colors.cyan,
        fontFamily: 'Arial',
      ),
    );

    scorePaint = TextPaint(
      style: TextStyle(
        fontSize: baseSize * 1.1,
        color: Colors.white,
        fontFamily: 'Arial',
      ),
    );

    userScorePaint = TextPaint(
      style: TextStyle(
        fontSize: baseSize * 1.1,
        color: Colors.green,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
    );
  }

  double _calcularTamanioBaseFuente() {
    final double screenMin = size.x < size.y ? size.x : size.y;

    if (screenMin < 400) {
      return 14.0;
    } else if (screenMin < 600) {
      return 16.0;
    } else if (screenMin < 800) {
      return 18.0;
    } else if (screenMin < 1200) {
      return 20.0;
    } else {
      return 22.0;
    }
  }

  Future<void> _cargarLeaderboard() async {
    try {
      final supabaseService = SupabaseService();

      topPuntajes = await supabaseService.obtenerTopPuntajesEficiente(
        limite: 10,
      );

      if (topPuntajes.isEmpty) {
        topPuntajes = await supabaseService.obtenerTopPuntajes(limite: 10);
      }

      cargando = false;
      _calcularMaxScroll();
    } catch (e) {
      cargando = false;
    }
  }

  void _calcularMaxScroll() {
    final rowHeight = 40.0;
    scrollAreaStartY = 170.0; // Después de encabezados
    scrollAreaEndY = size.y - 120; // Antes del botón volver

    final totalContentHeight = topPuntajes.length * rowHeight;
    final visibleHeight = scrollAreaEndY - scrollAreaStartY;

    maxScrollOffset = (totalContentHeight - visibleHeight).clamp(
      0.0,
      double.infinity,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Fondo
    final backgroundRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      backgroundRect,
      Paint()..color = Colors.black.withOpacity(0.95),
    );

    // Título
    _renderTextoCentrado(
      canvas,
      'TOP 10 PUNTAJES',
      titlePaint,
      Vector2(size.x / 2, 50),
    );

    if (cargando) {
      _renderTextoCentrado(
        canvas,
        'Cargando...',
        scorePaint,
        Vector2(size.x / 2, size.y / 2),
      );
    } else {
      _renderLeaderboard(canvas);
    }

    // Botón volver
    _renderBotonVolver(canvas);
  }

  void _renderLeaderboard(Canvas canvas) {
    final startY = 120.0;
    final rowHeight = 40.0;

    // Encabezados (fijos, no se mueven con el scroll)
    _renderTexto(canvas, 'POS', headerPaint, Vector2(50, startY));
    _renderTexto(canvas, 'JUGADOR', headerPaint, Vector2(120, startY));
    _renderTexto(canvas, 'PUNTOS', headerPaint, Vector2(size.x - 160, startY));

    // Línea separadora
    canvas.drawLine(
      Offset(50, startY + 30),
      Offset(size.x - 50, startY + 30),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 2.0,
    );

    // Guardar el estado del canvas
    canvas.save();

    // Crear área de recorte para el contenido scrolleable
    scrollAreaStartY = startY + 50;
    scrollAreaEndY = size.y - 120;

    final clipRect = Rect.fromLTWH(
      0,
      scrollAreaStartY,
      size.x,
      scrollAreaEndY - scrollAreaStartY,
    );
    canvas.clipRect(clipRect);

    // Puntajes con offset de scroll
    for (int i = 0; i < topPuntajes.length; i++) {
      final puntaje = topPuntajes[i];
      final yPos = scrollAreaStartY + (i * rowHeight) - scrollOffset;

      // Solo renderizar si está visible
      if (yPos >= scrollAreaStartY - rowHeight &&
          yPos <= scrollAreaEndY + rowHeight) {
        final esUsuarioActual =
            gameRef.usuarioManager.hayUsuario &&
            gameRef.usuarioManager.usuarioActual?.id == puntaje.usuarioId;

        final paint = esUsuarioActual ? userScorePaint : scorePaint;

        _renderTexto(canvas, '${i + 1}.', paint, Vector2(50, yPos));

        String nombre = puntaje.nombreUsuario;
        if (nombre.length > 15) {
          nombre = '${nombre.substring(0, 12)}...';
        }

        if (esUsuarioActual) {
          nombre = '$nombre (TÚ)';
        }

        _renderTexto(canvas, nombre, paint, Vector2(120, yPos));
        _renderTexto(
          canvas,
          '${puntaje.puntos}',
          paint,
          Vector2(size.x - 150, yPos),
        );
      }
    }

    // Restaurar el canvas
    canvas.restore();

    // Indicador de scroll si hay más contenido
    if (maxScrollOffset > 0) {
      _renderScrollIndicator(canvas);
    }

    // Si no hay puntajes
    if (topPuntajes.isEmpty) {
      _renderTextoCentrado(
        canvas,
        '¡Sé el primero en jugar!',
        scorePaint,
        Vector2(size.x / 2, size.y / 2),
      );
    }
  }

  void _renderScrollIndicator(Canvas canvas) {
    final indicatorHeight = 50.0;
    final indicatorWidth = 5.0;
    final trackHeight = scrollAreaEndY - scrollAreaStartY - 20;

    // Track del scroll
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x - 20,
          scrollAreaStartY + 10,
          indicatorWidth,
          trackHeight,
        ),
        Radius.circular(2.5),
      ),
      Paint()..color = Colors.white24,
    );

    // Posición del indicador
    final scrollPercentage = maxScrollOffset > 0
        ? scrollOffset / maxScrollOffset
        : 0.0;
    final indicatorY =
        scrollAreaStartY +
        10 +
        (scrollPercentage * (trackHeight - indicatorHeight));

    // Indicador
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x - 20, indicatorY, indicatorWidth, indicatorHeight),
        Radius.circular(2.5),
      ),
      Paint()..color = Colors.cyan,
    );
  }

  void _renderBotonVolver(Canvas canvas) {
    final buttonRect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y - 60),
      width: 200,
      height: 50,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, Radius.circular(25)),
      Paint()..color = Color(0x80666666),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, Radius.circular(25)),
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    _renderTextoCentrado(
      canvas,
      'VOLVER',
      scorePaint,
      Vector2(size.x / 2, size.y - 65),
    );
  }

  void _renderTexto(
    Canvas canvas,
    String texto,
    TextPaint paint,
    Vector2 position,
  ) {
    paint.render(canvas, texto, position);
  }

  void _renderTextoCentrado(
    Canvas canvas,
    String texto,
    TextPaint paint,
    Vector2 center,
  ) {
    final textSize = _medirTexto(texto, paint);
    final x = center.x - (textSize.x / 2);
    final y = center.y - (textSize.y / 2);
    paint.render(canvas, texto, Vector2(x, y));
  }

  Vector2 _medirTexto(String texto, TextPaint paint) {
    final textStyle = paint.style;
    final textSpan = TextSpan(text: texto, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return Vector2(textPainter.width, textPainter.height);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // El delta.y es negativo cuando arrastras hacia arriba
    // y positivo cuando arrastras hacia abajo
    // Restamos porque queremos que el contenido se mueva en dirección opuesta al dedo
    scrollOffset = (scrollOffset - event.localDelta.y).clamp(
      0.0,
      maxScrollOffset,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    final tapPosition = event.localPosition;

    // Verificar si se tocó el botón volver
    final buttonCenter = Offset(size.x / 2, size.y - 60);
    final buttonRect = Rect.fromCenter(
      center: buttonCenter,
      width: 200,
      height: 50,
    );

    if (buttonRect.contains(tapPosition.toOffset())) {
      _volver();
    }
  }

  void _volver() {
    removeFromParent();
    gameRef.goToStartScreen();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    position = Vector2.zero();
    _calcularMaxScroll();
    scrollOffset = scrollOffset.clamp(0.0, maxScrollOffset);
  }
}
