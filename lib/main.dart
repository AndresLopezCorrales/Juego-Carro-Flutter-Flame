import 'package:carreando/data/vehicle.dart';
import 'package:carreando/models/vehicle.dart';
import 'package:carreando/screens/game_over_screen.dart';
import 'package:carreando/screens/start_screen.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/player.dart';
import 'managers/fuel_manager.dart';
import 'managers/pickup_manager.dart';
import 'managers/obstacle_manager.dart';

import 'hud/game_hud.dart';

void main() {
  final game = MyGame();
  runApp(GameWidget(game: game, autofocus: true));
}

class MyGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  late double laneWidth;
  late double sideWidth;
  late List<double> lanes;

  // Dificultad Velocidad
  double difficultyMultiplier = 1.0;
  double difficultyIncreaseRate = 0.015;
  double timePassed = 0.0;

  // Managers - NULLABLE
  FuelManager? fuelManager;
  PickupManager? pickupManager;
  ObstacleManager? obstacleManager;
  Player? player;

  double scrollSpeed = 150;

  // Fondos verticales
  SpriteComponent? leftBg1, leftBg2;
  SpriteComponent? centerBg1, centerBg2;

  // Fondos horizontales
  SpriteComponent? topBg1, topBg2;
  SpriteComponent? centerHorizontalBg1, centerHorizontalBg2;

  int score = 0;
  double _scoreTimer = 0;

  bool _gameStarted = false;
  bool _gameOver = false;

  bool get isGameOver => _gameOver;

  bool _isHorizontalMode = false;
  bool get isHorizontalMode => _isHorizontalMode;

  // Referencias a las pantallas
  StartScreen? startScreen;
  GameOverScreen? gameOverScreen;
  GameHUD? gameHUD;

  // Vehículos disponibles y seleccionado
  int selectedVehicleIndex = 0;
  Vehicle get selectedVehicle => availableVehicles[selectedVehicleIndex];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadOrientationPreference();
    await _loadVehiclePreference();
    print('Orientación cargada al iniciar: $_isHorizontalMode');
    print('Vehículo cargado al iniciar: $selectedVehicleIndex');
    await _showStartScreen();
  }

  Future<void> _showStartScreen() async {
    _clearAllScreens();
    startScreen = StartScreen();
    await add(startScreen!);
    _gameStarted = false;
    _gameOver = false;
  }

  void startGame() {
    _clearAllScreens();
    _initializeGame();
    _gameStarted = true;
    _gameOver = false;
  }

  void restartGame() {
    _clearAllScreens();
    _resetGameState();
    _initializeGame();
    _gameStarted = true;
    _gameOver = false;
  }

  void goToStartScreen() {
    _clearAllScreens();
    _resetGameState();
    _showStartScreen();
  }

  void _clearAllScreens() {
    _resetGameState();

    // Limpiar managers primero
    children.whereType<FuelManager>().forEach((c) => c.removeFromParent());
    children.whereType<PickupManager>().forEach((c) => c.removeFromParent());
    children.whereType<ObstacleManager>().forEach((c) => c.removeFromParent());
    children.whereType<Player>().forEach((c) => c.removeFromParent());

    // Luego limpiar pantallas
    children.whereType<StartScreen>().forEach((c) => c.removeFromParent());
    children.whereType<GameOverScreen>().forEach((c) => c.removeFromParent());
    children.whereType<GameHUD>().forEach((c) => c.removeFromParent());

    // Limpiar fondos (todos los SpriteComponents que no sean jugador o managers)
    children.whereType<SpriteComponent>().forEach((c) {
      if (c != player) {
        c.removeFromParent();
      }
    });

    // Limpiar referencias - MODIFICADO: solo leftBg y topBg como fondos completos
    leftBg1 = leftBg2 = null;
    centerBg1 = centerBg2 = null;
    topBg1 = topBg2 = null;
    centerHorizontalBg1 = centerHorizontalBg2 = null;

    fuelManager = pickupManager = obstacleManager = player = null;
    gameHUD = gameOverScreen = startScreen = null;
  }

  void _resetGameState() {
    score = 0;
    difficultyMultiplier = 1.0;
    timePassed = 0.0;
    _scoreTimer = 0.0;
    scrollSpeed = 150;
    difficultyIncreaseRate = 0.015;
    _gameStarted = false;
    _gameOver = false;

    if (player != null) {
      player!.canMove = true;
    }
  }

  Future<void> _loadOrientationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isHorizontalMode = prefs.getBool('orientation_horizontal') ?? false;
    } catch (e) {
      print('Error loading orientation preference: $e');
      _isHorizontalMode = false;
    }
  }

  Future<void> saveOrientationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('orientation_horizontal', _isHorizontalMode);
    } catch (e) {
      print('Error saving orientation preference: $e');
    }
  }

  void setHorizontalMode(bool horizontal) {
    _isHorizontalMode = horizontal;
    saveOrientationPreference();
  }

  Future<void> _initializeGame() async {
    await Future.delayed(Duration.zero);

    if (_isHorizontalMode) {
      await _initializeHorizontalGame();
    } else {
      await _initializeVerticalGame();
    }
  }

  Future<void> _initializeVerticalGame() async {
    final Sprite sideSprite = await Sprite.load(selectedVehicle.sideSpritePath);
    sideWidth = size.x * 0.18;

    await _createScrollingSideBackground(sideSprite);
    await _createScrollingCenterBackground();

    _calculateLanes();
    _initializeManagers();
  }

  Future<void> _initializeHorizontalGame() async {
    await _createScrollingHorizontalBackgrounds();
    _calculateLanes();
    _initializeManagers();
  }

  void _calculateLanes() {
    if (_isHorizontalMode) {
      // En modo horizontal: calcular carriles basados en la altura
      sideWidth = size.y * 0.18;
      double centerHeight = size.y - (sideWidth * 2);

      // Usar un ancho de carril más pequeño para pantallas grandes
      double minLaneWidth = 70; // Reducido de 90 a 70
      int numCentralLanes = (centerHeight / minLaneWidth).floor();
      numCentralLanes = numCentralLanes.clamp(3, 5);
      laneWidth = centerHeight / numCentralLanes;

      // Lanes verticales en modo horizontal (para movimiento arriba/abajo)
      lanes = [];
      lanes.add(sideWidth * 0.35);
      for (int i = 0; i < numCentralLanes; i++) {
        double cy = sideWidth + (laneWidth * i) + (laneWidth / 2);
        lanes.add(cy);
      }
      lanes.add(size.y - (sideWidth * 0.35));
    } else {
      // En modo vertical: calcular carriles basados en el ancho
      sideWidth = size.x * 0.18;
      double centerWidth = size.x - (sideWidth * 2);

      // Usar un ancho de carril más pequeño para pantallas grandes
      double minLaneWidth = 70; // Reducido de 90 a 70
      int numCentralLanes = (centerWidth / minLaneWidth).floor();
      numCentralLanes = numCentralLanes.clamp(3, 5);
      laneWidth = centerWidth / numCentralLanes;

      lanes = [];
      lanes.add(sideWidth * 0.35);
      for (int i = 0; i < numCentralLanes; i++) {
        double cx = sideWidth + (laneWidth * i) + (laneWidth / 2);
        lanes.add(cx);
      }
      lanes.add(size.x - (sideWidth * 0.35));
    }
  }

  Future<void> _loadVehiclePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? savedVehicleIndex = prefs.getInt('selected_vehicle_index');

      if (savedVehicleIndex != null &&
          savedVehicleIndex >= 0 &&
          savedVehicleIndex < availableVehicles.length) {
        selectedVehicleIndex = savedVehicleIndex;
      } else {
        selectedVehicleIndex = 0; // Valor por defecto
      }
    } catch (e) {
      print('Error loading vehicle preference: $e');
      selectedVehicleIndex = 0;
    }
  }

  Future<void> saveVehiclePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_vehicle_index', selectedVehicleIndex);
    } catch (e) {
      print('Error saving vehicle preference: $e');
    }
  }

  // Modifica los métodos existentes para que guarden automáticamente:
  void selectNextVehicle() {
    selectedVehicleIndex =
        (selectedVehicleIndex + 1) % availableVehicles.length;
    saveVehiclePreference(); // ← Agregar esta línea
  }

  void selectPreviousVehicle() {
    selectedVehicleIndex =
        (selectedVehicleIndex - 1) % availableVehicles.length;
    if (selectedVehicleIndex < 0) {
      selectedVehicleIndex = availableVehicles.length - 1;
    }
    saveVehiclePreference(); // ← Agregar esta línea
  }

  void _initializeManagers() {
    fuelManager = FuelManager();
    add(fuelManager!);

    player = Player(vehicle: selectedVehicle);

    // PRIORIDAD MÁS ALTA para el jugador (encima de todo)
    player!.priority = 100;
    add(player!);

    player!.setLanePositions(lanes);

    if (_isHorizontalMode) {
      player!.position = Vector2(size.x * 0.15, lanes[player!.lane]);
    } else {
      player!.position = Vector2(lanes[player!.lane], size.y * 0.85);
    }

    // Escalar el jugador
    double targetWidth = laneWidth * 0.7;
    if (player!.width > 0) {
      player!.scale = Vector2.all(targetWidth / player!.width);
    } else {
      player!.size = Vector2(targetWidth, targetWidth * 1.5);
    }

    pickupManager = PickupManager(
      lanes: lanes,
      fuelManager: fuelManager!,
      player: player!,
      isHorizontalMode: _isHorizontalMode,
    );
    // PRIORIDAD ALTA para pickups (encima de la calle)
    pickupManager!.priority = 50;
    add(pickupManager!);

    obstacleManager = ObstacleManager(
      lanes: lanes,
      fuelManager: fuelManager!,
      player: player!,
      isHorizontalMode: _isHorizontalMode,
    );
    // PRIORIDAD ALTA para obstáculos (encima de la calle)
    obstacleManager!.priority = 50;
    add(obstacleManager!);

    gameHUD = GameHUD();
    // HUD con la prioridad MÁS ALTA (encima de todo)
    gameHUD!.priority = 200;
    add(gameHUD!);
    gameHUD!.position = Vector2.zero();
    gameHUD!.size = size;
  }

  Future<void> _createScrollingHorizontalBackgrounds() async {
    final Sprite sideSprite = await Sprite.load(
      selectedVehicle.sideHorizontalSpritePath,
    );
    final Sprite centerSprite = await Sprite.load(
      selectedVehicle.roadHorizontalSpritePath,
    );

    sideWidth = size.y * 0.18;
    double centerHeight = size.y - (sideWidth * 2);

    // FONDOS COMPLETOS (side)
    final fullBgSize = Vector2(size.x, size.y);

    topBg1 = SpriteComponent(sprite: sideSprite, size: fullBgSize);
    topBg2 = SpriteComponent(sprite: sideSprite, size: fullBgSize);

    topBg1!.position = Vector2(0, 0);
    topBg2!.position = Vector2(size.x, 0);

    // PRIORIDAD MÁS BAJA para el fondo side
    topBg1!.priority = 0;
    topBg2!.priority = 0;

    add(topBg1!);
    add(topBg2!);

    // CARRETERA CENTRAL
    final centerSize = Vector2(size.x, centerHeight);

    centerHorizontalBg1 = SpriteComponent(
      sprite: centerSprite,
      size: centerSize,
    );
    centerHorizontalBg2 = SpriteComponent(
      sprite: centerSprite,
      size: centerSize,
    );

    centerHorizontalBg1!.position = Vector2(0, sideWidth);
    centerHorizontalBg2!.position = Vector2(size.x, sideWidth);

    // PRIORIDAD BAJA para la calle (debajo de jugador y objetos)
    centerHorizontalBg1!.priority = 10;
    centerHorizontalBg2!.priority = 10;

    add(centerHorizontalBg1!);
    add(centerHorizontalBg2!);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_gameStarted && !_gameOver) {
      // Scroll según el modo
      if (_isHorizontalMode) {
        _scrollHorizontalBackgrounds(dt);
      } else {
        _scrollVerticalBackgrounds(dt);
      }

      // Dificultad
      timePassed += dt;
      if (timePassed >= 1.0) {
        difficultyMultiplier += difficultyIncreaseRate;
        timePassed = 0.0;
      }

      // Puntos por tiempo
      _scoreTimer += dt;
      if (_scoreTimer >= 1.0) {
        score += 10;
        _scoreTimer = 0;
      }

      if (fuelManager != null && fuelManager!.isEmpty && !_gameOver) {
        _gameOver = true;
        _showGameOverScreen();
      }
    }
  }

  // MODIFICADO: Solo topBg y centerHorizontalBg
  void _scrollHorizontalBackgrounds(double dt) {
    // Scroll para fondos horizontales
    if (topBg1 != null) _scrollHorizontal(topBg1!, dt);
    if (topBg2 != null) _scrollHorizontal(topBg2!, dt);
    if (centerHorizontalBg1 != null)
      _scrollHorizontal(centerHorizontalBg1!, dt);
    if (centerHorizontalBg2 != null)
      _scrollHorizontal(centerHorizontalBg2!, dt);
  }

  void _scrollHorizontal(SpriteComponent bg, double dt) {
    // Mover de derecha a izquierda
    bg.x -= scrollSpeed * dt;

    // Manejo mejorado de bordes
    if (bg.x <= -size.x) {
      bg.x += size.x * 2;
    }

    // También manejar el caso contrario por si acaso
    if (bg.x >= size.x * 2) {
      bg.x -= size.x * 2;
    }
  }

  // MODIFICADO: Solo leftBg y centerBg
  void _scrollVerticalBackgrounds(double dt) {
    if (leftBg1 != null) _scrollVertical(leftBg1!, dt);
    if (leftBg2 != null) _scrollVertical(leftBg2!, dt);
    if (centerBg1 != null) _scrollVertical(centerBg1!, dt);
    if (centerBg2 != null) _scrollVertical(centerBg2!, dt);
  }

  void _scrollVertical(SpriteComponent bg, double dt) {
    bg.y += scrollSpeed * dt;

    if (bg.y >= size.y) {
      bg.y = bg.y - (2 * size.y);
    }

    if (bg.y <= -2 * size.y) {
      bg.y += 2 * size.y;
    }
  }

  void _showGameOverScreen() {
    _stopGameLogic();
    gameOverScreen = GameOverScreen();
    add(gameOverScreen!);
  }

  void _stopGameLogic() {
    if (pickupManager != null) {
      pickupManager!.removeFromParent();
      pickupManager = null;
    }

    if (obstacleManager != null) {
      obstacleManager!.removeFromParent();
      obstacleManager = null;
    }

    difficultyIncreaseRate = 0;
    _scoreTimer = 0;

    if (player != null) {
      player!.canMove = false;
    }
  }

  Future<void> _createScrollingSideBackground(Sprite sprite) async {
    // El side ahora ocupa toda la pantalla de fondo
    final bgSize = Vector2(size.x, size.y);

    leftBg1 = SpriteComponent(sprite: sprite, size: bgSize);
    leftBg2 = SpriteComponent(sprite: sprite, size: bgSize);

    leftBg1!.position = Vector2(0, 0);
    leftBg2!.position = Vector2(0, -size.y);

    // PRIORIDAD MÁS BAJA para el fondo side
    leftBg1!.priority = 0;
    leftBg2!.priority = 0;

    add(leftBg1!);
    add(leftBg2!);
  }

  // MODIFICADO: Calle superpuesta en modo vertical
  Future<void> _createScrollingCenterBackground() async {
    final Sprite centerSprite = await Sprite.load(
      selectedVehicle.roadSpritePath,
    );

    double centerWidth = size.x - (sideWidth * 2);
    final bgSize = Vector2(centerWidth, size.y);

    centerBg1 = SpriteComponent(sprite: centerSprite, size: bgSize);
    centerBg2 = SpriteComponent(sprite: centerSprite, size: bgSize);

    centerBg1!.position = Vector2(sideWidth, 0);
    centerBg2!.position = Vector2(sideWidth, -size.y);

    // PRIORIDAD BAJA para la calle (debajo de jugador y objetos)
    centerBg1!.priority = 10;
    centerBg2!.priority = 10;

    add(centerBg1!);
    add(centerBg2!);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    if (size.x == 0 || size.y == 0 || !isLoaded) {
      return;
    }

    if (startScreen != null && startScreen!.isLoaded) {
      startScreen!.size = size;
      startScreen!.position = Vector2.zero();
    }

    if (gameOverScreen != null && gameOverScreen!.isLoaded) {
      gameOverScreen!.size = size;
      gameOverScreen!.position = Vector2.zero();
    }

    if (gameHUD != null && gameHUD!.isLoaded) {
      gameHUD!.size = size;
      gameHUD!.position = Vector2.zero();
    }

    if (!_gameStarted) {
      return;
    }

    if (_isHorizontalMode) {
      _resizeHorizontalGame();
    } else {
      _resizeVerticalGame();
    }
  }

  void _resizeVerticalGame() {
    final Vector2 oldSize = this.size;

    sideWidth = size.x * 0.18;
    double centerWidth = size.x - (sideWidth * 2);

    double minLaneWidth = 70; // Reducido para pantallas grandes
    int numCentralLanes = (centerWidth / minLaneWidth).floor();
    numCentralLanes = numCentralLanes.clamp(3, 5);
    laneWidth = centerWidth / numCentralLanes;

    lanes = [];
    lanes.add(sideWidth * 0.35);
    for (int i = 0; i < numCentralLanes; i++) {
      double cx = sideWidth + (laneWidth * i) + (laneWidth / 2);
      lanes.add(cx);
    }
    lanes.add(size.x - (sideWidth * 0.35));

    // MODIFICADO: Solo leftBg y centerBg
    if (leftBg1 != null) _resizeSideBackgrounds(oldSize);
    if (centerBg1 != null) _resizeCenterBackground(oldSize);

    if (player != null && player!.isLoaded) {
      player!.setLanePositions(lanes);
      double targetWidth = laneWidth * 0.7;
      double currentWidth = player!.width;
      double scale = targetWidth / currentWidth;
      player!.scale = Vector2.all(scale);
      player!.position = Vector2(
        lanes[player!.lane],
        size.y * 0.85, // ← CAMBIADO a porcentaje como en horizontal
      );
    }

    if (pickupManager != null) pickupManager!.updateLanes(lanes);
    if (obstacleManager != null) obstacleManager!.updateLanes(lanes);
  }

  void _resizeHorizontalGame() {
    final Vector2 oldSize = this.size;

    sideWidth = size.y * 0.18;
    double centerHeight = size.y - (sideWidth * 2);

    double minLaneWidth = 70; // Reducido para pantallas grandes
    int numCentralLanes = (centerHeight / minLaneWidth).floor();
    numCentralLanes = numCentralLanes.clamp(3, 5);
    laneWidth = centerHeight / numCentralLanes;

    lanes = [];
    lanes.add(sideWidth * 0.35);
    for (int i = 0; i < numCentralLanes; i++) {
      double cy = sideWidth + (laneWidth * i) + (laneWidth / 2);
      lanes.add(cy);
    }
    lanes.add(size.y - (sideWidth * 0.35));

    // MODIFICADO: Solo topBg y centerHorizontalBg
    final fullBgSize = Vector2(size.x, size.y);
    final centerSize = Vector2(size.x, centerHeight);

    // Actualizar fondos completos
    if (topBg1 != null && topBg2 != null) {
      _resizeHorizontalBackgroundPair(
        topBg1!,
        topBg2!,
        oldSize,
        fullBgSize,
        0, // Y position 0 porque ahora ocupa toda la pantalla
      );
    }

    // Actualizar carretera central
    if (centerHorizontalBg1 != null && centerHorizontalBg2 != null) {
      _resizeHorizontalBackgroundPair(
        centerHorizontalBg1!,
        centerHorizontalBg2!,
        oldSize,
        centerSize,
        sideWidth,
      );
    }

    // Actualizar jugador para modo horizontal
    if (player != null && player!.isLoaded) {
      player!.setLanePositions(lanes);
      double targetWidth = laneWidth * 0.7;
      double currentWidth = player!.width;
      double scale = targetWidth / currentWidth;
      player!.scale = Vector2.all(scale);
      player!.position = Vector2(size.x * 0.15, lanes[player!.lane]);
    }

    if (pickupManager != null) pickupManager!.updateLanes(lanes);
    if (obstacleManager != null) obstacleManager!.updateLanes(lanes);
  }

  void _resizeHorizontalBackgroundPair(
    SpriteComponent bg1,
    SpriteComponent bg2,
    Vector2 oldSize,
    Vector2 newSize,
    double yPosition,
  ) {
    // Guardar el progreso del scroll antes de cambiar el tamaño
    double scrollProgress1 = (bg1.x % oldSize.x) / oldSize.x;
    double scrollProgress2 = (bg2.x % oldSize.x) / oldSize.x;

    // Actualizar tamaño
    bg1.size = newSize;
    bg2.size = newSize;

    // Mantener la posición Y
    bg1.position.y = yPosition;
    bg2.position.y = yPosition;

    // Aplicar el progreso del scroll al nuevo tamaño
    bg1.position.x = scrollProgress1 * size.x;
    bg2.position.x = scrollProgress2 * size.x;

    // Asegurar la posición relativa correcta
    if (bg1.x < bg2.x) {
      // bg1 está a la izquierda de bg2
      if (bg2.x - bg1.x != size.x) {
        bg2.x = bg1.x + size.x;
      }
    } else {
      // bg2 está a la izquierda de bg1
      if (bg1.x - bg2.x != size.x) {
        bg1.x = bg2.x + size.x;
      }
    }

    // Asegurar que estén dentro de los límites
    if (bg1.x <= -size.x) bg1.x = size.x;
    if (bg2.x <= -size.x) bg2.x = size.x;
    if (bg1.x >= size.x * 2) bg1.x = -size.x;
    if (bg2.x >= size.x * 2) bg2.x = -size.x;
  }

  // MODIFICADO: Solo leftBg (fondo completo)
  void _resizeSideBackgrounds(Vector2 oldSize) {
    final bgSize = Vector2(size.x, size.y);

    leftBg1!.size = bgSize;
    leftBg2!.size = bgSize;

    _repositionScrollingBackground(leftBg1!, leftBg2!, oldSize);

    leftBg1!.position.x = 0;
    leftBg2!.position.x = 0;
  }

  void _resizeCenterBackground(Vector2 oldSize) {
    double centerWidth = size.x - (sideWidth * 2);
    final bgSize = Vector2(centerWidth, size.y);

    centerBg1!.size = bgSize;
    centerBg2!.size = bgSize;

    _repositionScrollingBackground(centerBg1!, centerBg2!, oldSize);

    centerBg1!.position.x = sideWidth;
    centerBg2!.position.x = sideWidth;
  }

  void _repositionScrollingBackground(
    SpriteComponent bg1,
    SpriteComponent bg2,
    Vector2 oldSize,
  ) {
    double scrollProgress1 = (bg1.position.y % oldSize.y) / oldSize.y;
    double scrollProgress2 = (bg2.position.y % oldSize.y) / oldSize.y;

    bg1.position.y = scrollProgress1 * size.y;
    bg2.position.y = scrollProgress2 * size.y;

    if (bg2.position.y >= bg1.position.y) {
      bg2.position.y = bg1.position.y - size.y;
    } else {
      bg1.position.y = bg2.position.y + size.y;
    }

    if (bg1.position.y >= size.y) {
      bg1.position.y = bg2.position.y - size.y;
    }
    if (bg2.position.y >= size.y) {
      bg2.position.y = bg1.position.y - size.y;
    }
    if (bg1.position.y < -size.y) {
      bg1.position.y = bg2.position.y + size.y;
    }
    if (bg2.position.y < -size.y) {
      bg2.position.y = bg1.position.y + size.y;
    }
  }
}
