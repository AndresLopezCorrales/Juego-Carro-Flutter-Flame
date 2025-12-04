import 'package:carreando/config/supabase_config.dart';
import 'package:carreando/data/vehicle.dart';
import 'package:carreando/managers/audio_manager.dart';
import 'package:carreando/managers/usuario_manager.dart';
import 'package:carreando/models/vehicle.dart';
import 'package:carreando/screens/game_over_screen.dart';
import 'package:carreando/screens/start_screen.dart';
import 'package:carreando/services/supabase_service.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'components/player.dart';
import 'managers/fuel_manager.dart';
import 'managers/pickup_manager.dart';
import 'managers/obstacle_manager.dart';

import 'hud/game_hud.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SharedPreferences.getInstance();

  await dotenv.load(fileName: "assets/.env");

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  final game = MyGame();
  runApp(GameWidget(game: game, autofocus: true));
}

class MyGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents, TapCallbacks {
  // Configuración de carriles
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

  // Velocidad de scroll
  double scrollSpeed = 150;

  // Fondos verticales
  SpriteComponent? leftBg1, leftBg2;
  SpriteComponent? centerBg1, centerBg2;

  // Fondos horizontales
  SpriteComponent? topBg1, topBg2;
  SpriteComponent? centerHorizontalBg1, centerHorizontalBg2;

  // Puntaje
  int score = 0;
  double _scoreTimer = 0;

  // Estado del juego
  bool _gameStarted = false;
  bool _gameOver = false;
  bool get isGameOver => _gameOver;

  //Modo Horizontal Bool
  bool _isHorizontalMode = false;
  bool get isHorizontalMode => _isHorizontalMode;

  // Referencias a las pantallas
  StartScreen? startScreen;
  GameOverScreen? gameOverScreen;
  GameHUD? gameHUD;

  // Vehículos disponibles y seleccionado
  int selectedVehicleIndex = 0;
  Vehicle get selectedVehicle => availableVehicles[selectedVehicleIndex];

  // Gestión de usuario
  final UsuarioManager usuarioManager = UsuarioManager();

  final audioManager = AudioManager();

  // Agrega una variable para el high score global
  int globalHighScore = 0;
  final SupabaseService supabaseService = SupabaseService();

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    // Solo manejar toques cuando el juego está activo
    if (_gameStarted && !_gameOver && player != null) {
      final touchPosition = event.localPosition;
      player!.handleTap(touchPosition.x, touchPosition.y);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await usuarioManager.cargarUsuarioGuardado();
    await _loadOrientationPreference();
    await _loadVehiclePreference();

    // Inicializar audio
    await audioManager.initialize();
    audioManager.playBgm('bgm.mp3');

    await _showStartScreen();
  }

  //UPDATE DEL JUEGO

  @override
  void update(double dt) {
    super.update(dt);

    if (_gameStarted && !_gameOver) {
      // Calcular scroll speed actualizado con la dificultad
      double currentScrollSpeed = scrollSpeed * difficultyMultiplier;

      // SCROLLING AHORA FUNCIONA EN TODAS LAS PLATAFORMAS
      if (_isHorizontalMode) {
        _scrollHorizontalBackgrounds(dt, currentScrollSpeed);
      } else {
        _scrollVerticalBackgrounds(dt, currentScrollSpeed);
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

  //MANEJO DE PANTALLAS

  Future<void> _showStartScreen() async {
    _clearAllScreens();
    startScreen = StartScreen();
    await add(startScreen!);
    _gameStarted = false;
    _gameOver = false;
  }

  void goToStartScreen() {
    _clearAllScreens();
    _resetGameState();
    _showStartScreen();
  }

  void _showGameOverScreen() async {
    _stopGameLogic();

    // Obtener el mejor puntaje global
    await _getGlobalHighScore();

    // Guardar puntaje si hay usuario
    if (usuarioManager.hayUsuario) {
      usuarioManager.guardarPuntajeActual(score);
    }

    gameOverScreen = GameOverScreen();
    add(gameOverScreen!);
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

    // Limpiar fondos
    children.whereType<SpriteComponent>().forEach((c) {
      if (c != player) {
        c.removeFromParent();
      }
    });

    // Limpiar referencias
    leftBg1 = leftBg2 = null;
    centerBg1 = centerBg2 = null;
    topBg1 = topBg2 = null;
    centerHorizontalBg1 = centerHorizontalBg2 = null;

    fuelManager = pickupManager = obstacleManager = player = null;
    gameHUD = gameOverScreen = startScreen = null;
  }

  //LLAMADO A SUPABASE
  Future<void> _getGlobalHighScore() async {
    try {
      final topPuntajes = await supabaseService.obtenerTopPuntajes(limite: 1);
      if (topPuntajes.isNotEmpty) {
        globalHighScore = topPuntajes.first.puntos;
      } else {
        globalHighScore = score;
      }
    } catch (e) {
      globalHighScore = score;
    }
  }

  //ACCIONES DE ESTADO DEL JUEGO

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

  //PERSISTENCIA DE CONFIGURACIONES

  Future<void> _loadOrientationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isHorizontalMode = prefs.getBool('orientation_horizontal') ?? false;
    } catch (e) {
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

  Future<void> _loadVehiclePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? savedVehicleIndex = prefs.getInt('selected_vehicle_index');

      if (savedVehicleIndex != null &&
          savedVehicleIndex >= 0 &&
          savedVehicleIndex < availableVehicles.length) {
        selectedVehicleIndex = savedVehicleIndex;
      } else {
        selectedVehicleIndex = 0;
      }
    } catch (e) {
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

  //INICIALIZACIÓN DE MANAGERS

  void _initializeManagers() {
    fuelManager = FuelManager();
    add(fuelManager!);

    player = Player(vehicle: selectedVehicle);
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
    pickupManager!.priority = 50;
    add(pickupManager!);

    obstacleManager = ObstacleManager(
      lanes: lanes,
      fuelManager: fuelManager!,
      player: player!,
      isHorizontalMode: _isHorizontalMode,
    );
    obstacleManager!.priority = 50;
    add(obstacleManager!);

    gameHUD = GameHUD();
    gameHUD!.priority = 200;
    add(gameHUD!);
    gameHUD!.position = Vector2.zero();
    gameHUD!.size = size;
  }

  //INICIALIZACIÓN DEL JUEGO

  Future<void> _initializeGame() async {
    await Future.delayed(Duration.zero);

    if (_isHorizontalMode) {
      await _initializeHorizontalGame();
    } else {
      await _initializeVerticalGame();
    }
  }

  //INICIALIZACIÓN VERTICAL Y HORIZONTAL

  Future<void> _initializeVerticalGame() async {
    try {
      await _createScrollingVerticalBackgrounds();
      _calculateLanes();
      _initializeManagers();
    } catch (e) {
      print('Error en inicialización vertical: $e');
      _isHorizontalMode = !_isHorizontalMode;
      saveOrientationPreference();
      startGame();
    }
  }

  Future<void> _initializeHorizontalGame() async {
    try {
      await _createScrollingHorizontalBackgrounds();
      _calculateLanes();
      _initializeManagers();
    } catch (e) {
      print('Error en inicialización horizontal: $e');
      _isHorizontalMode = !_isHorizontalMode;
      saveOrientationPreference();
      startGame();
    }
  }

  //CÁLCULO DE CARRILES

  void _calculateLanes() {
    if (_isHorizontalMode) {
      sideWidth = size.y * 0.18;
      double centerHeight = size.y - (sideWidth * 2);

      double minLaneWidth = 70;
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
    } else {
      sideWidth = size.x * 0.18;
      double centerWidth = size.x - (sideWidth * 2);

      double minLaneWidth = 70;
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

  // SELECCIÓN DE VEHÍCULO
  void selectNextVehicle() {
    selectedVehicleIndex =
        (selectedVehicleIndex + 1) % availableVehicles.length;
    saveVehiclePreference();
  }

  void selectPreviousVehicle() {
    selectedVehicleIndex =
        (selectedVehicleIndex - 1) % availableVehicles.length;
    if (selectedVehicleIndex < 0) {
      selectedVehicleIndex = availableVehicles.length - 1;
    }
    saveVehiclePreference();
  }

  // FUNCIONES DE FONDO Y SCROLLING - OPTIMIZADAS PARA ANDROID

  Future<void> _createScrollingVerticalBackgrounds() async {
    final Sprite sideSprite = await Sprite.load(selectedVehicle.sideSpritePath);
    final Sprite centerSprite = await Sprite.load(
      selectedVehicle.roadSpritePath,
    );

    sideWidth = size.x * 0.18;
    double centerWidth = size.x - (sideWidth * 2);

    // FONDOS LATERALES - Tamaño optimizado
    final sideBgSize = Vector2(size.x, size.y);
    leftBg1 = SpriteComponent(sprite: sideSprite, size: sideBgSize);
    leftBg2 = SpriteComponent(sprite: sideSprite, size: sideBgSize);

    leftBg1!.position = Vector2(0, 0);
    leftBg2!.position = Vector2(0, -size.y);

    leftBg1!.priority = 0;
    leftBg2!.priority = 0;

    add(leftBg1!);
    add(leftBg2!);

    // CARRETERA CENTRAL - Tamaño optimizado
    final centerBgSize = Vector2(centerWidth, size.y);
    centerBg1 = SpriteComponent(sprite: centerSprite, size: centerBgSize);
    centerBg2 = SpriteComponent(sprite: centerSprite, size: centerBgSize);

    centerBg1!.position = Vector2(sideWidth, 0);
    centerBg2!.position = Vector2(sideWidth, -size.y);

    centerBg1!.priority = 10;
    centerBg2!.priority = 10;

    add(centerBg1!);
    add(centerBg2!);
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

    // TAMAÑO COMPLETO para todas las plataformas
    final fullBgSize = Vector2(size.x, size.y);

    topBg1 = SpriteComponent(sprite: sideSprite, size: fullBgSize);
    topBg2 = SpriteComponent(sprite: sideSprite, size: fullBgSize);

    topBg1!.position = Vector2(0, 0);
    topBg2!.position = Vector2(size.x, 0);

    topBg1!.priority = 0;
    topBg2!.priority = 0;

    add(topBg1!);
    add(topBg2!);

    // CARRETERA CENTRAL - Tamaño completo
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

    centerHorizontalBg1!.priority = 10;
    centerHorizontalBg2!.priority = 10;

    add(centerHorizontalBg1!);
    add(centerHorizontalBg2!);
  }

  void _scrollHorizontalBackgrounds(double dt, double currentSpeed) {
    if (topBg1 != null) _scrollHorizontal(topBg1!, dt, currentSpeed);
    if (topBg2 != null) _scrollHorizontal(topBg2!, dt, currentSpeed);
    if (centerHorizontalBg1 != null)
      _scrollHorizontal(centerHorizontalBg1!, dt, currentSpeed);
    if (centerHorizontalBg2 != null)
      _scrollHorizontal(centerHorizontalBg2!, dt, currentSpeed);
  }

  void _scrollHorizontal(SpriteComponent bg, double dt, double speed) {
    // Obtener el ancho efectivo del fondo
    final bgWidth = bg.size.x;

    // Mover de derecha a izquierda
    bg.x -= speed * dt;

    // Reposicionar cuando sale de la pantalla
    if (bg.x <= -bgWidth) {
      bg.x += bgWidth * 2;
    }

    // Manejar el caso contrario
    if (bg.x >= bgWidth * 2) {
      bg.x -= bgWidth * 2;
    }
  }

  void _scrollVerticalBackgrounds(double dt, double currentSpeed) {
    if (leftBg1 != null) _scrollVertical(leftBg1!, dt, currentSpeed);
    if (leftBg2 != null) _scrollVertical(leftBg2!, dt, currentSpeed);
    if (centerBg1 != null) _scrollVertical(centerBg1!, dt, currentSpeed);
    if (centerBg2 != null) _scrollVertical(centerBg2!, dt, currentSpeed);
  }

  void _scrollVertical(SpriteComponent bg, double dt, double speed) {
    bg.y += speed * dt;

    if (bg.y >= size.y) {
      bg.y = bg.y - (2 * size.y);
    }

    if (bg.y <= -2 * size.y) {
      bg.y += 2 * size.y;
    }
  }

  //ONGAME RESIZE
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    if (size.x == 0 || size.y == 0 || !isLoaded) {
      return;
    }

    // Actualizar pantallas
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

    // Si el juego no ha empezado, solo actualizar pantallas
    if (!_gameStarted) {
      return;
    }

    // Manejar resize según el modo
    if (_isHorizontalMode) {
      _resizeHorizontalGame();
    } else {
      _resizeVerticalGame();
    }
  }

  void _resizeVerticalGame() {
    try {
      final Vector2 oldSize = this.size;

      sideWidth = size.x * 0.18;
      double centerWidth = size.x - (sideWidth * 2);

      double minLaneWidth = 70;
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

      if (leftBg1 != null) _resizeSideBackgrounds(oldSize);
      if (centerBg1 != null) _resizeCenterBackground(oldSize);

      if (player != null && player!.isLoaded) {
        player!.setLanePositions(lanes);
        double targetWidth = laneWidth * 0.7;
        double currentWidth = player!.width;
        double scale = targetWidth / currentWidth;
        player!.scale = Vector2.all(scale);
        player!.position = Vector2(lanes[player!.lane], size.y * 0.85);
      }

      if (pickupManager != null) pickupManager!.updateLanes(lanes);
      if (obstacleManager != null) obstacleManager!.updateLanes(lanes);
    } catch (e) {
      print('ERROR en _resizeVerticalGame: $e');
    }
  }

  void _resizeHorizontalGame() {
    try {
      final Vector2 oldSize = this.size;

      sideWidth = size.y * 0.18;
      double centerHeight = size.y - (sideWidth * 2);

      double minLaneWidth = 70;
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

      // Usar tamaño completo
      final fullBgSize = Vector2(size.x, size.y);
      final centerSize = Vector2(size.x, centerHeight);

      // Actualizar fondos completos
      if (topBg1 != null && topBg2 != null) {
        _resizeHorizontalBackgroundPair(
          topBg1!,
          topBg2!,
          oldSize,
          fullBgSize,
          0,
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
    } catch (e) {
      print('ERROR en _resizeHorizontalGame: $e');
    }
  }

  void _resizeHorizontalBackgroundPair(
    SpriteComponent bg1,
    SpriteComponent bg2,
    Vector2 oldSize,
    Vector2 newSize,
    double yPosition,
  ) {
    // Obtener el ancho anterior del fondo
    final oldBgWidth = bg1.size.x;

    // Guardar el progreso del scroll
    double scrollProgress1 = (bg1.x % oldBgWidth) / oldBgWidth;
    double scrollProgress2 = (bg2.x % oldBgWidth) / oldBgWidth;

    // Actualizar tamaño
    bg1.size = newSize;
    bg2.size = newSize;

    // Mantener la posición Y
    bg1.position.y = yPosition;
    bg2.position.y = yPosition;

    // Aplicar el progreso del scroll al nuevo tamaño
    bg1.position.x = scrollProgress1 * newSize.x;
    bg2.position.x = scrollProgress2 * newSize.x;

    // Asegurar la posición relativa correcta
    if (bg1.x < bg2.x) {
      if (bg2.x - bg1.x != newSize.x) {
        bg2.x = bg1.x + newSize.x;
      }
    } else {
      if (bg1.x - bg2.x != newSize.x) {
        bg1.x = bg2.x + newSize.x;
      }
    }

    // Asegurar que estén dentro de los límites
    if (bg1.x <= -newSize.x) bg1.x = newSize.x;
    if (bg2.x <= -newSize.x) bg2.x = newSize.x;
    if (bg1.x >= newSize.x * 2) bg1.x = -newSize.x;
    if (bg2.x >= newSize.x * 2) bg2.x = -newSize.x;
  }

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
