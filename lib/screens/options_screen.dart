import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../components/ui/custom_button.dart';
import '../components/ui/text_input_mobile.dart';
import '../components/ui/text_input_desktop.dart';
import '../utils/platform_detector.dart';

class OptionsScreen extends PositionComponent
    with HasGameRef<MyGame>, TapCallbacks, DragCallbacks {
  final List<PositionComponent> _uiComponents = [];
  bool _showingUserInput = false;

  // Usar PositionComponent como tipo base para ambos inputs
  PositionComponent? _textInput;

  // Variables para scroll
  double scrollOffset = 0.0;
  double maxScrollOffset = 0.0;
  double contentHeight = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    position = Vector2.zero();

    _showMainOptions();
  }

  void _showMainOptions() {
    _clearComponents();
    _textInput = null;

    final screenCenterX = size.x / 2;
    final isHorizontal = size.x > size.y;

    // Espaciado adaptativo
    final double startY = isHorizontal ? 60 : 100;
    final double spacing = isHorizontal ? 50 : 70;
    double currentY = startY;

    // Título
    _addComponent(_createTitle('OPCIONES', Vector2(screenCenterX, currentY)));
    currentY += spacing;

    // Información de usuario
    final userInfo = gameRef.usuarioManager.hayUsuario
        ? 'Usuario: ${gameRef.usuarioManager.nombreUsuario}'
        : 'Modo: Invitado';

    _addComponent(_createInfoText(userInfo, Vector2(screenCenterX, currentY)));
    currentY += spacing - 20;

    // Botón de usuario
    final buttonWidth = isHorizontal ? 280.0 : 300.0;
    _addComponent(
      CustomButton(
        text: gameRef.usuarioManager.hayUsuario
            ? 'CAMBIAR USUARIO'
            : 'INICIAR SESIÓN',
        backgroundColor: const Color(0xFF333333),
        position: Vector2(screenCenterX - buttonWidth / 2, currentY),
        width: buttonWidth,
        height: 50,
        onPressed: _showUserInputScreen,
      ),
    );
    currentY += spacing + 10;

    // Información de orientación
    final orientationText =
        'Orientación: ${gameRef.isHorizontalMode ? 'Horizontal' : 'Vertical'}';
    _addComponent(
      _createInfoText(orientationText, Vector2(screenCenterX, currentY)),
    );
    currentY += spacing - 20;

    // Botón de orientación
    _addComponent(
      CustomButton(
        text: 'CAMBIAR ORIENTACIÓN',
        backgroundColor: const Color(0xFF444444),
        position: Vector2(screenCenterX - buttonWidth / 2, currentY),
        width: buttonWidth,
        height: 50,
        onPressed: _toggleOrientation,
      ),
    );
    currentY += spacing + 10;

    // Botón volver
    _addComponent(
      CustomButton(
        text: 'VOLVER AL MENÚ',
        backgroundColor: const Color(0xFF555555),
        position: Vector2(screenCenterX - buttonWidth / 2, currentY),
        width: buttonWidth,
        height: 50,
        onPressed: _goBack,
      ),
    );
    currentY += 60;

    // Calcular altura total del contenido
    contentHeight = currentY;
    _calcularMaxScroll();
  }

  void _showUserInputScreen() {
    _clearComponents();
    _showingUserInput = true;

    final screenCenterX = size.x / 2;
    final isHorizontal = size.x > size.y;

    // Espaciado adaptativo
    final double startY = isHorizontal ? 50 : 100;
    final double spacing = isHorizontal ? 55 : 70;
    final double buttonWidth = isHorizontal ? 280.0 : 300.0;
    double currentY = startY;

    // Título
    _addComponent(
      _createTitle('INGRESA TU NOMBRE', Vector2(screenCenterX, currentY)),
    );
    currentY += spacing;

    // Input de texto - SELECCIONAR SEGÚN PLATAFORMA
    if (PlatformDetector.isMobile) {
      // Android/iOS - Usa TextInputMobile
      _textInput = TextInputMobile(
        onSubmitted: _acceptUser,
        onCancel: _showMainOptions,
        position: Vector2(screenCenterX - buttonWidth / 2, currentY),
        size: Vector2(buttonWidth, 50),
      );
    } else {
      // Desktop/Web - Usa TextInputDesktop
      _textInput = TextInputDesktop(
        onSubmitted: _acceptUser,
        onCancel: _showMainOptions,
        position: Vector2(screenCenterX - buttonWidth / 2, currentY),
        size: Vector2(buttonWidth, 50),
      );
    }
    _addComponent(_textInput!);
    currentY += spacing;

    // Botón aceptar
    _addComponent(
      CustomButton(
        text: 'ACEPTAR',
        backgroundColor: const Color(0xFF2E7D32),
        position: Vector2(screenCenterX - buttonWidth / 2, currentY),
        width: buttonWidth,
        height: 50,
        onPressed: _submitInput,
      ),
    );
    currentY += spacing;

    // Botón cancelar
    _addComponent(
      CustomButton(
        text: 'CANCELAR',
        backgroundColor: const Color(0xFF555555),
        position: Vector2(screenCenterX - buttonWidth / 2, currentY),
        width: buttonWidth,
        height: 50,
        onPressed: _showMainOptions,
      ),
    );
    currentY += spacing;

    // Instrucciones
    _addComponent(
      _createInstructionText(
        'Mínimo 3 caracteres, máximo 20',
        Vector2(screenCenterX, currentY),
      ),
    );
    currentY += 50;

    // Calcular altura total del contenido
    contentHeight = currentY;
    _calcularMaxScroll();
  }

  // Método helper para llamar submit en el input correcto
  void _submitInput() {
    if (_textInput is TextInputMobile) {
      (_textInput as TextInputMobile).submit();
    } else if (_textInput is TextInputDesktop) {
      (_textInput as TextInputDesktop).submit();
    }
  }

  // Método helper para verificar si el input está enfocado
  bool _isInputFocused() {
    if (_textInput is TextInputMobile) {
      return (_textInput as TextInputMobile).isFocused;
    } else if (_textInput is TextInputDesktop) {
      return (_textInput as TextInputDesktop).isFocused;
    }
    return false;
  }

  // Método helper para desenfocar el input
  void _unfocusInput() {
    if (_textInput is TextInputMobile) {
      (_textInput as TextInputMobile).unfocus();
    } else if (_textInput is TextInputDesktop) {
      (_textInput as TextInputDesktop).unfocus();
    }
  }

  void _calcularMaxScroll() {
    final visibleHeight = size.y;
    maxScrollOffset = (contentHeight - visibleHeight + 40).clamp(
      0.0,
      double.infinity,
    );
    scrollOffset = scrollOffset.clamp(0.0, maxScrollOffset);
  }

  PositionComponent _createTitle(String text, Vector2 center) {
    final isHorizontal = size.x > size.y;
    final fontSize = isHorizontal ? 24.0 : 28.0;

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      fontFamily: 'Arial',
    );

    final textPaint = TextPaint(style: textStyle);
    final textWidth = _measureTextWidth(text, textStyle);

    return PositionComponent(
      position: Vector2(center.x - textWidth / 2, center.y),
      size: Vector2(textWidth, fontSize + 2),
    )..add(
      TextComponent(
        text: text,
        textRenderer: textPaint,
        anchor: Anchor.topLeft,
      ),
    );
  }

  PositionComponent _createInfoText(String text, Vector2 center) {
    final isHorizontal = size.x > size.y;
    final fontSize = isHorizontal ? 18.0 : 20.0;

    final textStyle = TextStyle(
      color: const Color(0xFFCCCCCC),
      fontSize: fontSize,
      fontFamily: 'Arial',
    );

    final textPaint = TextPaint(style: textStyle);
    final textWidth = _measureTextWidth(text, textStyle);

    return PositionComponent(
      position: Vector2(center.x - textWidth / 2, center.y),
      size: Vector2(textWidth, fontSize + 5),
    )..add(
      TextComponent(
        text: text,
        textRenderer: textPaint,
        anchor: Anchor.topLeft,
      ),
    );
  }

  PositionComponent _createInstructionText(String text, Vector2 center) {
    final isHorizontal = size.x > size.y;
    final fontSize = isHorizontal ? 14.0 : 16.0;

    final textStyle = TextStyle(
      color: const Color(0xFF888888),
      fontSize: fontSize,
      fontFamily: 'Arial',
    );

    final textPaint = TextPaint(style: textStyle);
    final textWidth = _measureTextWidth(text, textStyle);

    return PositionComponent(
      position: Vector2(center.x - textWidth / 2, center.y),
      size: Vector2(textWidth, fontSize + 4),
    )..add(
      TextComponent(
        text: text,
        textRenderer: textPaint,
        anchor: Anchor.topLeft,
      ),
    );
  }

  double _measureTextWidth(String text, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }

  void _addComponent(PositionComponent component) {
    _uiComponents.add(component);
    add(component);
  }

  void _clearComponents() {
    for (final component in _uiComponents) {
      component.removeFromParent();
    }
    _uiComponents.clear();
    _showingUserInput = false;
    scrollOffset = 0.0;
  }

  void _toggleOrientation() {
    gameRef.setHorizontalMode(!gameRef.isHorizontalMode);
    gameRef.saveOrientationPreference();
    _showMainOptions();
  }

  void _acceptUser(String username) async {
    if (username.trim().length < 3) {
      return;
    }

    final success = await gameRef.usuarioManager.iniciarSesionOCrear(
      username.trim(),
    );

    if (success) {
      _showMainOptions();
    }
  }

  void _goBack() {
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    // Fondo
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.black.withOpacity(0.9),
    );

    // Guardar estado del canvas para aplicar scroll
    canvas.save();
    canvas.translate(0, -scrollOffset);

    // Los componentes se renderizan automáticamente por Flame
    super.render(canvas);

    canvas.restore();

    // Indicador de scroll si hay contenido que no cabe
    if (maxScrollOffset > 0) {
      _renderScrollIndicator(canvas);
    }
  }

  void _renderScrollIndicator(Canvas canvas) {
    final indicatorHeight = 50.0;
    final indicatorWidth = 5.0;
    final trackHeight = size.y - 40;

    // Track del scroll
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x - 15, 20, indicatorWidth, trackHeight),
        Radius.circular(2.5),
      ),
      Paint()..color = Colors.white24,
    );

    // Posición del indicador
    final scrollPercentage = maxScrollOffset > 0
        ? scrollOffset / maxScrollOffset
        : 0.0;
    final indicatorY =
        20 + (scrollPercentage * (trackHeight - indicatorHeight));

    // Indicador
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x - 15, indicatorY, indicatorWidth, indicatorHeight),
        Radius.circular(2.5),
      ),
      Paint()..color = Colors.cyan,
    );
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
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    position = Vector2.zero();

    if (_showingUserInput) {
      _showUserInputScreen();
    } else {
      _showMainOptions();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    // Si hay un input activo y se toca fuera de él, desenfocar
    if (_textInput != null && _isInputFocused()) {
      final tapPosition = event.localPosition;
      final inputRect = Rect.fromLTWH(
        _textInput!.position.x,
        _textInput!.position.y - scrollOffset,
        _textInput!.size.x,
        _textInput!.size.y,
      );

      if (!inputRect.contains(tapPosition.toOffset())) {
        _unfocusInput();
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
  }
}
