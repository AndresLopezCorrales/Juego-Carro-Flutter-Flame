import 'package:carreando/screens/game_over_screen.dart';
import 'package:carreando/screens/start_screen.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/widgets.dart';

import 'components/player.dart';
import 'game/fuel_manager.dart';
import 'game/pickup_manager.dart';
import 'game/obstacle_manager.dart';

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

  double scrollSpeed = 150; // Hacer no-final para poder modificarlo

  // Fondos laterales - NULLABLE
  SpriteComponent? leftBg1, leftBg2;
  SpriteComponent? rightBg1, rightBg2;
  SpriteComponent? centerBg1, centerBg2;

  int score = 0;
  double _scoreTimer = 0;

  bool _gameStarted = false;
  bool _gameOver = false;

  bool get isGameOver => _gameOver;

  // Referencias a las pantallas
  StartScreen? startScreen;
  GameOverScreen? gameOverScreen;
  GameHUD? gameHUD;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
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
    // PRIMERO: Resetear el estado del juego
    _resetGameState();
    // Remover todas las pantallas y componentes del juego
    children.whereType<StartScreen>().forEach((c) => c.removeFromParent());
    children.whereType<GameOverScreen>().forEach((c) => c.removeFromParent());
    children.whereType<GameHUD>().forEach((c) => c.removeFromParent());
    children.whereType<Player>().forEach((c) => c.removeFromParent());
    children.whereType<FuelManager>().forEach((c) => c.removeFromParent());
    children.whereType<PickupManager>().forEach((c) => c.removeFromParent());
    children.whereType<ObstacleManager>().forEach((c) => c.removeFromParent());

    // Limpiar fondos y resetear a null
    children.whereType<SpriteComponent>().forEach((c) => c.removeFromParent());
    leftBg1 = leftBg2 = rightBg1 = rightBg2 = centerBg1 = centerBg2 = null;

    // Resetear managers a null
    fuelManager = pickupManager = obstacleManager = player = null;
    gameHUD = gameOverScreen = startScreen = null;
  }

  void _resetGameState() {
    score = 0;
    difficultyMultiplier = 1.0;
    timePassed = 0.0;
    _scoreTimer = 0.0;
    scrollSpeed = 150; // Restaurar velocidad del background
    difficultyIncreaseRate = 0.015; // Restaurar aumento de dificultad
    _gameStarted = false; // AGREGAR ESTO
    _gameOver = false; // AGREGAR ESTO

    // Reiniciar el movimiento del jugador si existe
    if (player != null) {
      player!.canMove = true;
    }
  }

  Future<void> _initializeGame() async {
    await Future.delayed(Duration.zero);

    final Sprite sideSprite = await Sprite.load("escenarios/side.png");
    sideWidth = size.x * 0.18;

    await _createScrollingSideBackground(sideSprite);
    await _createScrollingCenterBackground();

    double minLaneWidth = 90;
    double centerWidth = size.x - (sideWidth * 2);
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

    // INICIALIZAR MANAGERS
    fuelManager = FuelManager();
    add(fuelManager!);

    player = Player();
    await add(player!);
    player!.setLanePositions(lanes);
    player!.position = Vector2(
      lanes[player!.lane],
      size.y - player!.height - 20,
    );

    pickupManager = PickupManager(
      lanes: lanes,
      fuelManager: fuelManager!,
      player: player!,
    );
    add(pickupManager!);

    obstacleManager = ObstacleManager(
      lanes: lanes,
      fuelManager: fuelManager!,
      player: player!,
    );
    add(obstacleManager!);

    gameHUD = GameHUD();
    await add(gameHUD!);
    gameHUD!.position = Vector2.zero();
    gameHUD!.size = size;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_gameStarted && !_gameOver) {
      // ACTUALIZAR SOLO SI LOS FONDOS EXISTEN
      if (leftBg1 != null) _scrollSide(leftBg1!, dt);
      if (leftBg2 != null) _scrollSide(leftBg2!, dt);
      if (rightBg1 != null) _scrollSide(rightBg1!, dt);
      if (rightBg2 != null) _scrollSide(rightBg2!, dt);
      if (centerBg1 != null) _scrollSide(centerBg1!, dt);
      if (centerBg2 != null) _scrollSide(centerBg2!, dt);

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

      // VERIFICAR SI SE ACABÓ EL JUEGO - SOLO SI fuelManager EXISTE
      if (fuelManager != null && fuelManager!.isEmpty && !_gameOver) {
        _gameOver = true;
        _showGameOverScreen();
      }
    }
  }

  void _showGameOverScreen() {
    // Detener la lógica del juego pero mantener el background moviéndose
    _stopGameLogic();

    // Mostrar pantalla de Game Over
    gameOverScreen = GameOverScreen();
    add(gameOverScreen!);
  }

  void _stopGameLogic() {
    // Detener spawn de pickups y obstáculos
    if (pickupManager != null) {
      pickupManager!.removeFromParent();
      pickupManager = null;
    }

    if (obstacleManager != null) {
      obstacleManager!.removeFromParent();
      obstacleManager = null;
    }

    // Detener aumento de dificultad y puntos
    difficultyIncreaseRate = 0;

    _scoreTimer = 0;

    // El jugador sigue en pantalla pero no puede moverse
    if (player != null) {
      // Opcional: hacer que el jugador sea inmóvil
      player!.canMove = false;
    }
  }

  Future<void> _createScrollingSideBackground(Sprite sprite) async {
    final bgSize = Vector2(sideWidth, size.y);

    leftBg1 = SpriteComponent(sprite: sprite, size: bgSize);
    leftBg2 = SpriteComponent(sprite: sprite, size: bgSize);
    rightBg1 = SpriteComponent(sprite: sprite, size: bgSize);
    rightBg2 = SpriteComponent(sprite: sprite, size: bgSize);

    leftBg1!.position = Vector2(0, 0);
    leftBg2!.position = Vector2(0, -size.y);
    rightBg1!.position = Vector2(size.x - sideWidth, 0);
    rightBg2!.position = Vector2(size.x - sideWidth, -size.y);

    add(leftBg1!);
    add(leftBg2!);
    add(rightBg1!);
    add(rightBg2!);
  }

  void _scrollSide(SpriteComponent bg, double dt) {
    bg.y += scrollSpeed * dt;

    if (bg.y >= size.y) {
      bg.y = bg.y - (2 * size.y);
    }

    if (bg.y <= -2 * size.y) {
      bg.y += 2 * size.y;
    }
  }

  Future<void> _createScrollingCenterBackground() async {
    final Sprite centerSprite = await Sprite.load("carreteras/calle.png");

    double centerWidth = size.x - (sideWidth * 2);
    final bgSize = Vector2(centerWidth, size.y);

    centerBg1 = SpriteComponent(sprite: centerSprite, size: bgSize);
    centerBg2 = SpriteComponent(sprite: centerSprite, size: bgSize);

    centerBg1!.position = Vector2(sideWidth, 0);
    centerBg2!.position = Vector2(sideWidth, -size.y);

    add(centerBg1!);
    add(centerBg2!);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    // Verificar si el tamaño es válido
    if (size.x == 0 || size.y == 0 || !isLoaded) {
      return;
    }

    // ACTUALIZAR START SCREEN SI EXISTE
    if (startScreen != null && startScreen!.isLoaded) {
      startScreen!.size = size;
      startScreen!.position = Vector2.zero();
    }

    // ACTUALIZAR GAME OVER SCREEN SI EXISTE
    if (gameOverScreen != null && gameOverScreen!.isLoaded) {
      gameOverScreen!.size = size;
      gameOverScreen!.position = Vector2.zero();
    }

    // ACTUALIZAR GAME HUD SI EXISTE
    if (gameHUD != null && gameHUD!.isLoaded) {
      gameHUD!.size = size;
      gameHUD!.position = Vector2.zero();
    }

    // SOLO PROCESAR RESIZE DEL JUEGO SI ESTÁ INICIADO
    if (!_gameStarted) {
      return;
    }

    final Vector2 oldSize = this.size;

    sideWidth = size.x * 0.18;
    double centerWidth = size.x - (sideWidth * 2);

    double minLaneWidth = 90;
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

    // ACTUALIZAR FONDOS SOLO SI EXISTEN
    if (leftBg1 != null) _resizeSideBackgrounds(oldSize);
    if (centerBg1 != null) _resizeCenterBackground(oldSize);

    // ACTUALIZAR JUGADOR SOLO SI EXISTE
    if (player != null && player!.isLoaded) {
      player!.setLanePositions(lanes);
      double targetWidth = laneWidth * 0.7;
      double currentWidth = player!.width;
      double scale = targetWidth / currentWidth;
      player!.scale = Vector2.all(scale);
      player!.position = Vector2(
        lanes[player!.lane],
        size.y - player!.height - 20,
      );
    }

    // ACTUALIZAR MANAGERS SOLO SI EXISTEN
    if (pickupManager != null) {
      pickupManager!.updateLanes(lanes);
    }
    if (obstacleManager != null) {
      obstacleManager!.updateLanes(lanes);
    }
  }

  void _resizeSideBackgrounds(Vector2 oldSize) {
    final bgSize = Vector2(sideWidth, size.y);

    leftBg1!.size = bgSize;
    leftBg2!.size = bgSize;
    rightBg1!.size = bgSize;
    rightBg2!.size = bgSize;

    _repositionScrollingBackground(leftBg1!, leftBg2!, oldSize);
    _repositionScrollingBackground(rightBg1!, rightBg2!, oldSize);

    leftBg1!.position.x = 0;
    leftBg2!.position.x = 0;
    rightBg1!.position.x = size.x - sideWidth;
    rightBg2!.position.x = size.x - sideWidth;
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
