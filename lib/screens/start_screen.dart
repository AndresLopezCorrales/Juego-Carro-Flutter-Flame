import 'package:carreando/data/vehicle.dart';
import 'package:carreando/screens/credits_screen.dart';
import 'package:carreando/screens/leaderboard_screen.dart';
import 'package:carreando/screens/options_screen.dart';
import 'package:carreando/utils/platform_detector.dart'; // AGREGADO
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import '../main.dart';

class StartScreen extends PositionComponent
    with HasGameRef<MyGame>, TapCallbacks {
  late TextPaint titlePaint;
  late TextPaint subtitlePaint;
  late TextPaint buttonPaint;
  late TextPaint arrowPaint;
  late TextPaint audioHintPaint; // AGREGADO: para mensaje de audio en web

  // Lista para almacenar los sprites de los vehículos
  List<Sprite> vehicleSprites = [];
  bool spritesLoaded = false;

  // Áreas definidas para cada sección
  late Rect _titleArea;
  late Rect _vehicleSelectorArea;
  late Rect _playButtonArea;
  late Rect _leaderboardButtonArea;
  late Rect _optionsButtonArea;
  late Rect _creditsButtonArea;

  // AGREGADO: Bandera para mostrar mensaje de audio en web
  bool _showAudioHint = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    position = Vector2.zero();
    _setupTextPaints();
    _calculateAreas();
    await _loadVehicleSprites();

    // AGREGADO: Verificar si necesita mostrar mensaje de audio (solo web)
    _checkAudioStatus();
  }

  // AGREGADO: Método para verificar estado del audio
  void _checkAudioStatus() {
    if (PlatformDetector.isWeb && !gameRef.audioManager.userInteracted) {
      _showAudioHint = true;
      print('Web: Mostrando mensaje de activación de audio');
    } else {
      _showAudioHint = false;
    }
  }

  void _calculateAreas() {
    final double screenHeight = size.y;
    final double screenWidth = size.x;
    final bool isHorizontal = screenWidth > screenHeight;

    // AGREGADO: Si hay mensaje de audio, ajustar áreas
    final double audioHintHeight = _showAudioHint ? screenHeight * 0.08 : 0;
    final double startY = audioHintHeight;

    // Título: 12% de la pantalla
    _titleArea = Rect.fromLTWH(
      0,
      startY + screenHeight * 0.05,
      screenWidth,
      screenHeight * 0.12,
    );

    // Selector de vehículos: 35% de la pantalla (más grande)
    _vehicleSelectorArea = Rect.fromLTWH(
      0,
      _titleArea.bottom,
      screenWidth,
      screenHeight * 0.35,
    );

    // Calcular altura para cada botón - más separación en horizontal
    final double totalButtonsHeight = screenHeight * 0.35;
    final double buttonHeight = totalButtonsHeight * 0.18;
    final double buttonSpacing = isHorizontal
        ? totalButtonsHeight *
              0.06 // Más separación en horizontal
        : totalButtonsHeight * 0.04;
    final double buttonsStartY =
        _vehicleSelectorArea.bottom + (screenHeight * 0.02);

    // Botón JUGAR
    _playButtonArea = Rect.fromLTWH(
      0,
      buttonsStartY,
      screenWidth,
      buttonHeight,
    );

    // Botón LEADERBOARD
    _leaderboardButtonArea = Rect.fromLTWH(
      0,
      _playButtonArea.bottom + buttonSpacing,
      screenWidth,
      buttonHeight,
    );

    // Botón OPCIONES
    _optionsButtonArea = Rect.fromLTWH(
      0,
      _leaderboardButtonArea.bottom + buttonSpacing,
      screenWidth,
      buttonHeight,
    );

    // Botón CRÉDITOS
    _creditsButtonArea = Rect.fromLTWH(
      0,
      _optionsButtonArea.bottom + buttonSpacing,
      screenWidth,
      buttonHeight,
    );
  }

  Future<void> _loadVehicleSprites() async {
    for (var vehicle in availableVehicles) {
      final sprite = await Sprite.load(vehicle.spritePath);
      vehicleSprites.add(sprite);
    }
    spritesLoaded = true;
  }

  void _setupTextPaints() {
    final double baseSize = _calculateBaseFontSize();
    final bool isHorizontal = size.x > size.y;

    titlePaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: baseSize * 2.0,
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

    // Texto de botones más pequeño en horizontal
    buttonPaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: isHorizontal ? baseSize * 0.85 : baseSize * 1.2,
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

    arrowPaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.white.color,
        fontSize: baseSize * 2.2,
        fontFamily: 'Arial',
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: BasicPalette.black.color,
            blurRadius: 6.0,
            offset: Offset(3.0, 3.0),
          ),
        ],
      ),
    );

    // AGREGADO: Texto para mensaje de audio en web
    audioHintPaint = TextPaint(
      style: TextStyle(
        color: Colors.yellow, // Color amarillo para destacar
        fontSize: baseSize * 0.9,
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

    // AGREGADO: Renderizar mensaje de audio si es necesario
    if (_showAudioHint) {
      _renderAudioHint(canvas);
    }

    // Renderizar cada sección en su área correspondiente
    _renderTitleSection(canvas);
    _renderVehicleSelectorSection(canvas);
    _renderPlayButtonSection(canvas);
    _renderLeaderboardButtonSection(canvas);
    _renderOptionsButtonSection(canvas);
    _renderCreditsButtonSection(canvas);
  }

  // AGREGADO: Método para renderizar mensaje de audio
  void _renderAudioHint(Canvas canvas) {
    final message = 'TOCA LA PANTALLA PARA ACTIVAR EL AUDIO';
    final textSize = _measureText(message, audioHintPaint);

    // Posicionar en la parte superior
    final double x = size.x / 2 - textSize.x / 2;
    final double y = size.y * 0.03;

    // Fondo para el mensaje
    final backgroundRect = Rect.fromLTWH(
      x - 15,
      y - 8,
      textSize.x + 30,
      textSize.y + 16,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, Radius.circular(20)),
      Paint()
        ..color = Colors.black.withOpacity(0.7)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    // Texto del mensaje
    audioHintPaint.render(canvas, message, Vector2(x, y));
  }

  void _renderTitleSection(Canvas canvas) {
    final titleText = 'SLIDE ROAD';
    final titleSize = _measureText(titleText, titlePaint);
    final titleX = _titleArea.center.dx - (titleSize.x / 2);
    final titleY = _titleArea.top + (_titleArea.height * 0.4);

    titlePaint.render(canvas, titleText, Vector2(titleX, titleY));
  }

  void _renderVehicleSelectorSection(Canvas canvas) {
    // Texto "Seleccionar carro"
    final selectorText = 'SELECCIONAR CARRO';
    final selectorSize = _measureText(selectorText, subtitlePaint);
    final selectorX = _vehicleSelectorArea.center.dx - (selectorSize.x / 2);
    final selectorY =
        _vehicleSelectorArea.top + (_vehicleSelectorArea.height * 0.12);

    subtitlePaint.render(canvas, selectorText, Vector2(selectorX, selectorY));

    // Renderizar el sprite del carro seleccionado
    if (spritesLoaded && vehicleSprites.isNotEmpty) {
      final currentSprite = vehicleSprites[gameRef.selectedVehicleIndex];

      // Tamaño del sprite del carro - MÁS GRANDE (45% del área)
      final double maxCarWidth = _vehicleSelectorArea.width * 0.45;
      final double maxCarHeight = _vehicleSelectorArea.height * 0.6;

      // Calcular tamaño manteniendo proporción
      double carWidth = maxCarWidth;
      double carHeight =
          carWidth * (currentSprite.srcSize.y / currentSprite.srcSize.x);

      // Si es muy alto, ajustar al máximo permitido
      if (carHeight > maxCarHeight) {
        carHeight = maxCarHeight;
        carWidth =
            carHeight * (currentSprite.srcSize.x / currentSprite.srcSize.y);
      }

      final carX = _vehicleSelectorArea.center.dx - (carWidth / 2);
      final carY =
          _vehicleSelectorArea.top + (_vehicleSelectorArea.height * 0.35);

      // Renderizar el sprite del carro
      currentSprite.render(
        canvas,
        position: Vector2(carX, carY),
        size: Vector2(carWidth, carHeight),
      );

      // Flecha izquierda
      final leftArrow = '‹';
      final leftArrowSize = _measureText(leftArrow, arrowPaint);
      final leftArrowX = carX - leftArrowSize.x - 20;
      final leftArrowY = carY + (carHeight / 2) - (leftArrowSize.y / 2);

      // Solo renderizar flecha si está dentro del área
      if (leftArrowX >= _vehicleSelectorArea.left) {
        // Fondo flecha izquierda con blur
        final leftArrowBg = Rect.fromLTWH(
          leftArrowX - 10,
          leftArrowY - 10,
          leftArrowSize.x + 20,
          leftArrowSize.y + 20,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(leftArrowBg, Radius.circular(12)),
          Paint()
            ..color = Color(0xFF444444)
                .withOpacity(0.6) // Más transparente
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              4.0,
            ), // Efecto blur
        );

        arrowPaint.render(canvas, leftArrow, Vector2(leftArrowX, leftArrowY));
      }

      // Flecha derecha
      final rightArrow = '›';
      final rightArrowSize = _measureText(rightArrow, arrowPaint);
      final rightArrowX = carX + carWidth + 20;
      final rightArrowY = carY + (carHeight / 2) - (rightArrowSize.y / 2);

      // Solo renderizar flecha si está dentro del área
      if (rightArrowX + rightArrowSize.x <= _vehicleSelectorArea.right) {
        // Fondo flecha derecha con blur
        final rightArrowBg = Rect.fromLTWH(
          rightArrowX - 10,
          rightArrowY - 10,
          rightArrowSize.x + 20,
          rightArrowSize.y + 20,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rightArrowBg, Radius.circular(12)),
          Paint()
            ..color = Color(0xFF444444)
                .withOpacity(0.6) // Más transparente
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              4.0,
            ), // Efecto blur
        );

        arrowPaint.render(
          canvas,
          rightArrow,
          Vector2(rightArrowX, rightArrowY),
        );
      }

      // Indicador de selección (puntos debajo del carro)
      _renderVehicleIndicator(canvas, carX, carWidth);
    }
  }

  void _renderVehicleIndicator(Canvas canvas, double carX, double carWidth) {
    final double dotSize = 6.0;
    final double dotSpacing = 12.0;
    final int totalVehicles = availableVehicles.length;
    final double totalWidth =
        (totalVehicles * dotSize) + ((totalVehicles - 1) * dotSpacing);

    final double startX = carX + (carWidth - totalWidth) / 2;
    final double dotY =
        _vehicleSelectorArea.top + (_vehicleSelectorArea.height * 0.82);

    for (int i = 0; i < totalVehicles; i++) {
      final double dotX = startX + (i * (dotSize + dotSpacing));
      final bool isSelected = i == gameRef.selectedVehicleIndex;

      canvas.drawCircle(
        Offset(dotX + dotSize / 2, dotY),
        dotSize / 2,
        Paint()
          ..color = isSelected
              ? Color(0xFFFFD700)
              : BasicPalette.white.color.withOpacity(0.5),
      );
    }
  }

  void _renderPlayButtonSection(Canvas canvas) {
    _renderButtonInArea(canvas, 'JUGAR', _playButtonArea);
  }

  void _renderLeaderboardButtonSection(Canvas canvas) {
    _renderButtonInArea(canvas, 'LEADERBOARD', _leaderboardButtonArea);
  }

  void _renderOptionsButtonSection(Canvas canvas) {
    _renderButtonInArea(canvas, 'OPCIONES', _optionsButtonArea);
  }

  void _renderCreditsButtonSection(Canvas canvas) {
    _renderButtonInArea(canvas, 'CRÉDITOS', _creditsButtonArea);
  }

  void _renderButtonInArea(Canvas canvas, String text, Rect area) {
    final buttonTextSize = _measureText(text, buttonPaint);

    // Botón ocupa 50% del ancho del área (más estrecho) y 100% del alto del área
    final double buttonWidth = area.width * 0.50;
    final double buttonHeight = area.height;

    final buttonX = area.center.dx - (buttonWidth / 2);
    final buttonY = area.top;

    // Fondo del botón con blur y transparencia
    final buttonRect = Rect.fromLTWH(
      buttonX,
      buttonY,
      buttonWidth,
      buttonHeight,
    );

    // Botón con bordes redondeados y efecto blur
    final buttonRadius = Radius.circular(
      buttonHeight * 0.3,
    ); // Bordes más redondeados

    // Fondo con blur
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, buttonRadius),
      Paint()
        ..color =
            Color(0x80111111) // Negro muy transparente
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          8.0,
        ), // Efecto blur más pronunciado
    );

    // Borde del botón más sutil
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, buttonRadius),
      Paint()
        ..color = BasicPalette.white.color
            .withOpacity(0.3) // Borde más transparente
        ..style = PaintingStyle.stroke
        ..strokeWidth = buttonHeight * 0.03, // Borde más delgado
    );

    // Texto del botón - Centrado con más padding
    final double horizontalPadding =
        buttonWidth * 0.1; // 10% de padding horizontal
    final double verticalPadding =
        buttonHeight * 0.2; // 20% de padding vertical

    final buttonTextY = buttonY + verticalPadding;
    final double availableTextWidth = buttonWidth - (horizontalPadding * 2);

    // Asegurar que el texto no sea más ancho que el espacio disponible
    if (buttonTextSize.x <= availableTextWidth) {
      // Centrar texto si cabe
      final centeredTextX = buttonX + (buttonWidth - buttonTextSize.x) / 2;
      buttonPaint.render(canvas, text, Vector2(centeredTextX, buttonTextY));
    } else {
      // Renderizar normalmente con padding
      final buttonTextX = buttonX + horizontalPadding;
      buttonPaint.render(canvas, text, Vector2(buttonTextX, buttonTextY));
    }
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

    // AGREGADO: PRIMERO manejar la activación del audio si es web
    if (PlatformDetector.isWeb && !gameRef.audioManager.userInteracted) {
      _handleFirstWebInteraction();

      // Si el tap fue en el mensaje de audio, no procesar botones
      final double audioHintHeight = size.y * 0.08;
      final Rect audioHintArea = Rect.fromLTWH(0, 0, size.x, audioHintHeight);

      if (audioHintArea.contains(tapPosition.toOffset())) {
        return; // Solo activar audio, no procesar botones
      }
    }

    // Luego verificar en qué área se hizo tap para las funcionalidades
    if (_playButtonArea.contains(tapPosition.toOffset())) {
      _onPlayButtonPressed();
    } else if (_leaderboardButtonArea.contains(tapPosition.toOffset())) {
      _onLeaderboardButtonPressed();
    } else if (_optionsButtonArea.contains(tapPosition.toOffset())) {
      _onOptionsButtonPressed();
    } else if (_creditsButtonArea.contains(tapPosition.toOffset())) {
      _onCreditsButtonPressed();
    } else if (_vehicleSelectorArea.contains(tapPosition.toOffset())) {
      _handleVehicleSelectorTap(tapPosition);
    }
  }

  // AGREGADO: Manejar primera interacción en web
  void _handleFirstWebInteraction() {
    print('🎵 Web: Primer tap detectado - activando audio');

    // Activar el audio
    gameRef.audioManager.markUserInteraction();

    // Ocultar mensaje de audio
    _showAudioHint = false;

    // Recalcular áreas sin el mensaje
    _calculateAreas();

    print('✅ Audio activado correctamente');
  }

  void _onPlayButtonPressed() {
    gameRef.startGame();
  }

  void _onLeaderboardButtonPressed() {
    _goToLeaderboardScreen();
  }

  void _onOptionsButtonPressed() {
    _goToOptionsScreen();
  }

  void _onCreditsButtonPressed() {
    _goToCreditsScreen();
  }

  void _goToCreditsScreen() {
    final creditsScreen = CreditsScreen();
    gameRef.add(creditsScreen);
  }

  void _goToOptionsScreen() {
    final optionsScreen = OptionsScreen();
    gameRef.add(optionsScreen);
  }

  void _goToLeaderboardScreen() {
    final leaderboardScreen = LeaderboardScreen();
    gameRef.add(leaderboardScreen);
  }

  void _handleVehicleSelectorTap(Vector2 tapPosition) {
    if (spritesLoaded && vehicleSprites.isNotEmpty) {
      final currentSprite = vehicleSprites[gameRef.selectedVehicleIndex];

      final double maxCarWidth = _vehicleSelectorArea.width * 0.45;
      final double maxCarHeight = _vehicleSelectorArea.height * 0.6;

      double carWidth = maxCarWidth;
      double carHeight =
          carWidth * (currentSprite.srcSize.y / currentSprite.srcSize.x);

      if (carHeight > maxCarHeight) {
        carHeight = maxCarHeight;
        carWidth =
            carHeight * (currentSprite.srcSize.x / currentSprite.srcSize.y);
      }

      final double carX = _vehicleSelectorArea.center.dx - (carWidth / 2);
      final double carY =
          _vehicleSelectorArea.top + (_vehicleSelectorArea.height * 0.35);

      // Área flecha izquierda
      final leftArrowArea = Rect.fromLTWH(
        _vehicleSelectorArea.left,
        carY,
        carX - _vehicleSelectorArea.left,
        carHeight,
      );

      // Área flecha derecha
      final rightArrowArea = Rect.fromLTWH(
        carX + carWidth,
        carY,
        _vehicleSelectorArea.right - (carX + carWidth),
        carHeight,
      );

      if (leftArrowArea.contains(tapPosition.toOffset())) {
        gameRef.selectPreviousVehicle();
      } else if (rightArrowArea.contains(tapPosition.toOffset())) {
        gameRef.selectNextVehicle();
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    position = Vector2.zero();

    // Re-verificar estado del audio
    _checkAudioStatus();

    _calculateAreas();
    _setupTextPaints();
  }
}
