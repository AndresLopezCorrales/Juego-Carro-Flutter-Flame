import 'package:carreando/config/supabase_config.dart';
import 'package:carreando/data/vehicle.dart';
import 'package:carreando/managers/audio_manager.dart';
import 'package:carreando/managers/usuario_manager.dart';
import 'package:carreando/models/vehicle.dart';
import 'package:carreando/screens/game_over_screen.dart';
import 'package:carreando/screens/start_screen.dart';
import 'package:carreando/services/supabase_service.dart';
import 'package:carreando/utils/platform_detector.dart';
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

    // Precargar assets importantes para Android
    if (PlatformDetector.isAndroid) {
      await _preloadImportantAssets();
    }

    await usuarioManager.cargarUsuarioGuardado();
    await _loadOrientationPreference();
    await _loadVehiclePreference();

    // Inicializar audio
    await audioManager.initialize();
    audioManager.playBgm('bgm.mp3');

    await _showStartScreen();
  }

  Future<void> _preloadImportantAssets() async {
    // Precargar sprites del vehículo seleccionado
    try {
      await Sprite.load(selectedVehicle.sideSpritePath);
      await Sprite.load(selectedVehicle.roadSpritePath);
      await Sprite.load(selectedVehicle.sideHorizontalSpritePath);
      await Sprite.load(selectedVehicle.roadHorizontalSpritePath);
    } catch (e) {
      print('ERROR precargando assets: $e');
    }
  }

  //UPDATE DEL JUEGO

  @override
  void update(double dt) {
    super.update(dt);

    if (_gameStarted && !_gameOver) {
      // Calcular scroll speed actualizado con la dificultad
      double currentScrollSpeed = scrollSpeed * difficultyMultiplier;

      // SOLO HACER SCROLL SI NO ES ANDROID
      // Si es Android, el fondo será estático
      if (!PlatformDetector.isAndroid) {
        // Scroll según el modo
        if (_isHorizontalMode) {
          _scrollHorizontalBackgrounds(dt, currentScrollSpeed);
        } else {
          _scrollVerticalBackgrounds(dt, currentScrollSpeed);
        }
      }

      // Dificultad (siempre se aplica, incluso en Android)
      timePassed += dt;
      if (timePassed >= 1.0) {
        difficultyMultiplier += difficultyIncreaseRate;
        timePassed = 0.0;
      }

      // Puntos por tiempo (siempre se aplica)
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
        selectedVehicleIndex = 0; // Valor por defecto
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

    // Ajustar para Android después de inicializar
    _adjustForAndroid();
  }

  void _adjustForAndroid() {
    if (PlatformDetector.isAndroid) {
      // Reducir velocidad de scroll (aunque no se usará)
      scrollSpeed = 0;

      // Ajustar dificultad si es necesario
      difficultyIncreaseRate = 0.02;

      // Ajustar tamaño del jugador si es necesario y seguro
      if (player != null && player!.isLoaded && laneWidth > 0) {
        double targetWidth = laneWidth * 0.8;
        if (player!.width > 0) {
          player!.scale = Vector2.all(targetWidth / player!.width);
        } else {
          // Fallback si width es 0
          player!.size = Vector2(targetWidth, targetWidth * 1.5);
        }
      }
    }
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
      // Precargar sprites
      final Sprite sideSprite = await Sprite.load(
        selectedVehicle.sideSpritePath,
      );
      final Sprite centerSprite = await Sprite.load(
        selectedVehicle.roadSpritePath,
      );

      sideWidth = size.x * 0.18;

      // EN ANDROID: Usar sprites ya cargados
      if (PlatformDetector.isAndroid) {
        await _createAndroidVerticalBackground(sideSprite, centerSprite);
      } else {
        await _createScrollingSideBackground(sideSprite);
        await _createScrollingCenterBackground();
      }

      _calculateLanes();
      _initializeManagers();
    } catch (e) {
      // Fallback a modo horizontal si falla
      _isHorizontalMode = !_isHorizontalMode;
      saveOrientationPreference();
      startGame();
    }
  }

  Future<void> _createAndroidVerticalBackground(
    Sprite sideSprite,
    Sprite centerSprite,
  ) async {
    sideWidth = size.x * 0.18;
    double centerWidth = size.x - (sideWidth * 2);

    // FONDO LATERAL
    final bgSize = Vector2(size.x, size.y);
    leftBg1 = SpriteComponent(sprite: sideSprite, size: bgSize);
    leftBg1!.position = Vector2(0, 0);
    leftBg1!.priority = 0;
    add(leftBg1!);

    // CARRETERA CENTRAL
    final centerBgSize = Vector2(centerWidth, size.y);
    centerBg1 = SpriteComponent(
      sprite: centerSprite,
      size: centerBgSize,
      position: Vector2(sideWidth, 0),
      priority: 10,
    );
    add(centerBg1!);
  }

  Future<void> _initializeHorizontalGame() async {
    try {
      // Precargar sprites
      final Sprite sideSprite = await Sprite.load(
        selectedVehicle.sideHorizontalSpritePath,
      );
      final Sprite centerSprite = await Sprite.load(
        selectedVehicle.roadHorizontalSpritePath,
      );

      // EN ANDROID: Usar sprites ya cargados
      if (PlatformDetector.isAndroid) {
        await _createAndroidHorizontalBackground(sideSprite, centerSprite);
      } else {
        await _createScrollingHorizontalBackgrounds();
      }

      _calculateLanes();
      _initializeManagers();
    } catch (e) {
      // Fallback a modo vertical si falla
      _isHorizontalMode = !_isHorizontalMode;
      saveOrientationPreference();
      startGame();
    }
  }

  Future<void> _createAndroidHorizontalBackground(
    Sprite sideSprite,
    Sprite centerSprite,
  ) async {
    sideWidth = size.y * 0.18;
    double centerHeight = size.y - (sideWidth * 2);

    // FONDOS SUPERIORES
    final fullBgSize = Vector2(size.x, size.y);
    topBg1 = SpriteComponent(sprite: sideSprite, size: fullBgSize);
    topBg1!.position = Vector2(0, 0);
    topBg1!.priority = 0;
    add(topBg1!);

    // CARRETERA CENTRAL
    final centerSize = Vector2(size.x, centerHeight);
    centerHorizontalBg1 = SpriteComponent(
      sprite: centerSprite,
      size: centerSize,
      position: Vector2(0, sideWidth),
      priority: 10,
    );
    add(centerHorizontalBg1!);
  }

  //CÁLCULO DE CARRILES

  void _calculateLanes() {
    if (_isHorizontalMode) {
      // En modo horizontal: calcular carriles basados en la altura
      sideWidth = size.y * 0.18;
      double centerHeight = size.y - (sideWidth * 2);

      // Usar un ancho de carril más pequeño para pantallas grandes
      double minLaneWidth = 70;
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

  // FUNCIONES DE FONDO Y SCROLLING

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

    // EN ANDROID: Usar solo UN fondo (sin duplicado para scroll)
    if (PlatformDetector.isAndroid) {
      // Solo un fondo estático
      topBg1 = SpriteComponent(sprite: sideSprite, size: fullBgSize);
      topBg1!.position = Vector2(0, 0);
      topBg1!.priority = 0;
      add(topBg1!);
    } else {
      // Para otras plataformas: dos fondos para scroll
      topBg1 = SpriteComponent(sprite: sideSprite, size: fullBgSize);
      topBg2 = SpriteComponent(sprite: sideSprite, size: fullBgSize);

      topBg1!.position = Vector2(0, 0);
      topBg2!.position = Vector2(size.x, 0);

      topBg1!.priority = 0;
      topBg2!.priority = 0;

      add(topBg1!);
      add(topBg2!);
    }

    // CARRETERA CENTRAL
    final centerSize = Vector2(size.x, centerHeight);

    // EN ANDROID: Solo una carretera estática
    if (PlatformDetector.isAndroid) {
      centerHorizontalBg1 = SpriteComponent(
        sprite: centerSprite,
        size: centerSize,
        position: Vector2(0, sideWidth),
        priority: 10,
      );
      add(centerHorizontalBg1!);
    } else {
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
  }

  void _scrollHorizontalBackgrounds(double dt, double currentSpeed) {
    // EN ANDROID: No hacer scroll
    if (PlatformDetector.isAndroid) {
      return;
    }

    // Scroll para fondos horizontales (solo otras plataformas)
    if (topBg1 != null) _scrollHorizontal(topBg1!, dt, currentSpeed);
    if (topBg2 != null) _scrollHorizontal(topBg2!, dt, currentSpeed);
    if (centerHorizontalBg1 != null)
      _scrollHorizontal(centerHorizontalBg1!, dt, currentSpeed);
    if (centerHorizontalBg2 != null)
      _scrollHorizontal(centerHorizontalBg2!, dt, currentSpeed);
  }

  void _scrollHorizontal(SpriteComponent bg, double dt, double speed) {
    // Mover de derecha a izquierda
    bg.x -= speed * dt;

    // Manejo mejorado de bordes
    if (bg.x <= -size.x) {
      bg.x += size.x * 2;
    }

    // También manejar el caso contrario por si acaso
    if (bg.x >= size.x * 2) {
      bg.x -= size.x * 2;
    }
  }

  void _scrollVerticalBackgrounds(double dt, double currentSpeed) {
    // EN ANDROID: No hacer scroll
    if (PlatformDetector.isAndroid) {
      return;
    }

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

  Future<void> _createScrollingSideBackground(Sprite sprite) async {
    // EN ANDROID: Solo un fondo estático
    if (PlatformDetector.isAndroid) {
      final bgSize = Vector2(size.x, size.y);
      leftBg1 = SpriteComponent(sprite: sprite, size: bgSize);
      leftBg1!.position = Vector2(0, 0);
      leftBg1!.priority = 0;
      add(leftBg1!);
    } else {
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
  }

  Future<void> _createScrollingCenterBackground() async {
    final Sprite centerSprite = await Sprite.load(
      selectedVehicle.roadSpritePath,
    );

    double centerWidth = size.x - (sideWidth * 2);
    final bgSize = Vector2(centerWidth, size.y);

    // EN ANDROID: Solo un fondo central estático
    if (PlatformDetector.isAndroid) {
      centerBg1 = SpriteComponent(
        sprite: centerSprite,
        size: bgSize,
        position: Vector2(sideWidth, 0),
        priority: 10,
      );
      add(centerBg1!);
    } else {
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

    // EN ANDROID: Manejo especial para rotación
    if (PlatformDetector.isAndroid) {
      _handleAndroidResize();
    } else {
      // Para otras plataformas, comportamiento normal
      if (_isHorizontalMode) {
        _resizeHorizontalGame();
      } else {
        _resizeVerticalGame();
      }
    }
  }

  void _handleAndroidResize() {
    try {
      // Recalcular lanes primero (esto es seguro)
      _calculateLanes();

      // Actualizar jugador si existe
      if (player != null && player!.isLoaded) {
        player!.setLanePositions(lanes);

        // Recalcular posición según modo
        if (_isHorizontalMode) {
          player!.position = Vector2(size.x * 0.15, lanes[player!.lane]);
        } else {
          player!.position = Vector2(lanes[player!.lane], size.y * 0.85);
        }

        // Recalcular escala
        double targetWidth = laneWidth * 0.8; // Android usa 0.8
        if (player!.width > 0) {
          player!.scale = Vector2.all(targetWidth / player!.width);
        }
      }

      // **EN ANDROID: RECREAR FONDOS COMPLETAMENTE**
      // Los fondos estáticos necesitan ser recreados al rotar

      // Limpiar fondos existentes
      _clearAndroidBackgrounds();

      // Recrear fondos según el modo actual
      if (_isHorizontalMode) {
        _recreateHorizontalBackgroundsForAndroid();
      } else {
        _recreateVerticalBackgroundsForAndroid();
      }

      // Actualizar managers
      if (pickupManager != null) {
        pickupManager!.updateLanes(lanes);
      }

      if (obstacleManager != null) {
        obstacleManager!.updateLanes(lanes);
      }
    } catch (e) {
      // En caso de error, intentar reiniciar el juego
      _recoverFromAndroidResizeError();
    }
  }

  void _clearAndroidBackgrounds() {
    // Crear lista de componentes a remover
    final componentsToRemove = <Component>[];

    // Agregar todos los SpriteComponents que sean fondos
    for (var child in children) {
      if (child is SpriteComponent &&
          child != player &&
          child != fuelManager &&
          child != pickupManager &&
          child != obstacleManager &&
          !(child is GameHUD) &&
          !(child is StartScreen) &&
          !(child is GameOverScreen)) {
        componentsToRemove.add(child);
      }
    }

    // Remover componentes
    for (var component in componentsToRemove) {
      component.removeFromParent();
    }

    // Limpiar referencias
    leftBg1 = leftBg2 = null;
    centerBg1 = centerBg2 = null;
    topBg1 = topBg2 = null;
    centerHorizontalBg1 = centerHorizontalBg2 = null;
  }

  Future<void> _recreateHorizontalBackgroundsForAndroid() async {
    try {
      final Sprite sideSprite = await Sprite.load(
        selectedVehicle.sideHorizontalSpritePath,
      );
      final Sprite centerSprite = await Sprite.load(
        selectedVehicle.roadHorizontalSpritePath,
      );

      sideWidth = size.y * 0.18;
      double centerHeight = size.y - (sideWidth * 2);

      // FONDOS SUPERIORES
      final fullBgSize = Vector2(size.x, size.y);
      topBg1 = SpriteComponent(sprite: sideSprite, size: fullBgSize);
      topBg1!.position = Vector2(0, 0);
      topBg1!.priority = 0;
      add(topBg1!);

      // CARRETERA CENTRAL
      final centerSize = Vector2(size.x, centerHeight);
      centerHorizontalBg1 = SpriteComponent(
        sprite: centerSprite,
        size: centerSize,
        position: Vector2(0, sideWidth),
        priority: 10,
      );
      add(centerHorizontalBg1!);
    } catch (e) {
      print('ERROR recreando fondos horizontales: $e');
      throw e;
    }
  }

  Future<void> _recreateVerticalBackgroundsForAndroid() async {
    try {
      final Sprite sideSprite = await Sprite.load(
        selectedVehicle.sideSpritePath,
      );
      final Sprite centerSprite = await Sprite.load(
        selectedVehicle.roadSpritePath,
      );

      sideWidth = size.x * 0.18;
      double centerWidth = size.x - (sideWidth * 2);

      // FONDO LATERAL
      final bgSize = Vector2(size.x, size.y);
      leftBg1 = SpriteComponent(sprite: sideSprite, size: bgSize);
      leftBg1!.position = Vector2(0, 0);
      leftBg1!.priority = 0;
      add(leftBg1!);

      // CARRETERA CENTRAL
      final centerBgSize = Vector2(centerWidth, size.y);
      centerBg1 = SpriteComponent(
        sprite: centerSprite,
        size: centerBgSize,
        position: Vector2(sideWidth, 0),
        priority: 10,
      );
      add(centerBg1!);
    } catch (e) {
      print('ERROR recreando fondos verticales: $e');
      throw e;
    }
  }

  void _recoverFromAndroidResizeError() {
    // Si hay un error crítico, mostrar pantalla de inicio
    if (_gameStarted && !_gameOver) {
      _gameOver = true;
      Future.delayed(Duration(milliseconds: 500), () {
        goToStartScreen();
      });
    }
  }

  void _resizeVerticalGame() {
    try {
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
      if (bg2.x - bg1.x != size.x) {
        bg2.x = bg1.x + size.x;
      }
    } else {
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
