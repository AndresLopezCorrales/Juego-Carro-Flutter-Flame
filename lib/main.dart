import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/widgets.dart';

import 'components/player.dart';
import 'game/fuel_manager.dart';
import 'game/pickup_manager.dart';
import 'game/obstacle_manager.dart';

void main() {
  final game = MyGame();
  runApp(GameWidget(game: game, autofocus: true));
}

class MyGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  late double laneWidth; // ancho del carril central
  late double sideWidth; // ancho de carril lateral
  late List<double> lanes; // posiciones X de TODOS los carriles

  // Dificultad Velocidad
  double difficultyMultiplier = 1.0;
  double difficultyIncreaseRate = 0.015; // 0.15% más rápido cada segundo
  double timePassed = 0.0;

  // Managers
  late Player player;
  late FuelManager fuelManager;
  late PickupManager pickupManager;
  late ObstacleManager obstacleManager;

  final double scrollSpeed = 150; // velocidad de scroll de fondos

  // Fondos laterales
  late SpriteComponent leftBg1, leftBg2;
  late SpriteComponent rightBg1, rightBg2;

  // Fondos centrales
  late SpriteComponent centerBg1, centerBg2;

  int score = 0;
  double _scoreTimer = 0; // contador interno

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await Future.delayed(Duration.zero);

    // 1. Cargar textura lateral
    final Sprite sideSprite = await Sprite.load("escenarios/side.png");

    // 18% del ancho total para cada lateral
    sideWidth = size.x * 0.18;

    //2. Crear fondos laterales con scroll infinito
    await _createScrollingSideBackground(sideSprite);

    // 2.5 Fondo de carriles centrales
    await _createScrollingCenterBackground();

    //3. Calcular carriles con base en el tamaño de pantalla
    double minLaneWidth = 90; // mínimo razonable para celular

    double centerWidth = size.x - (sideWidth * 2);

    // número de carriles centrales posible
    int numCentralLanes = (centerWidth / minLaneWidth).floor();
    numCentralLanes = numCentralLanes.clamp(3, 5); // nunca menos de 3

    laneWidth = centerWidth / numCentralLanes;

    // 4. Crear lista final de carriles (laterales + centrales)
    lanes = [];

    // carril lateral izquierdo (ancho suficiente)
    lanes.add(sideWidth * 0.35);

    // carriles centrales
    for (int i = 0; i < numCentralLanes; i++) {
      double cx = sideWidth + (laneWidth * i) + (laneWidth / 2);
      lanes.add(cx);
    }

    // carril lateral derecho
    lanes.add(size.x - (sideWidth * 0.35));

    // 5.Managers
    fuelManager = FuelManager();
    add(fuelManager);

    // 6. Jugador
    player = Player();
    await add(player);

    player.setLanePositions(lanes);

    player.position = Vector2(lanes[player.lane], size.y - player.height - 20);

    //7. Spawn managers
    pickupManager = PickupManager(
      lanes: lanes,
      fuelManager: fuelManager,
      player: player,
    );
    add(pickupManager);

    obstacleManager = ObstacleManager(
      lanes: lanes,
      fuelManager: fuelManager,
      player: player,
    );
    add(obstacleManager);
  }

  //Background side scrolling setup
  Future<void> _createScrollingSideBackground(Sprite sprite) async {
    final bgSize = Vector2(sideWidth, size.y);

    leftBg1 = SpriteComponent(sprite: sprite, size: bgSize);
    leftBg2 = SpriteComponent(sprite: sprite, size: bgSize);
    rightBg1 = SpriteComponent(sprite: sprite, size: bgSize);
    rightBg2 = SpriteComponent(sprite: sprite, size: bgSize);

    // posicionamiento
    leftBg1.position = Vector2(0, 0);
    leftBg2.position = Vector2(0, -size.y);

    rightBg1.position = Vector2(size.x - sideWidth, 0);
    rightBg2.position = Vector2(size.x - sideWidth, -size.y);

    add(leftBg1);
    add(leftBg2);
    add(rightBg1);
    add(rightBg2);
  }

  //Update loop
  @override
  void update(double dt) {
    super.update(dt);

    // Laterales
    _scrollSide(leftBg1, dt);
    _scrollSide(leftBg2, dt);
    _scrollSide(rightBg1, dt);
    _scrollSide(rightBg2, dt);

    // Centrales
    _scrollSide(centerBg1, dt);
    _scrollSide(centerBg2, dt);

    // dificultad
    timePassed += dt;
    if (timePassed >= 1.0) {
      difficultyMultiplier += difficultyIncreaseRate;
      timePassed = 0.0;
    }

    _scoreTimer += dt;
    if (_scoreTimer >= 1.0) {
      score += 10; // +10 puntos por segundo
      print("Puntos: $score");
      _scoreTimer = 0; // reiniciar
    }

    if (fuelManager.isEmpty) pauseEngine();
  }

  // Side scrolling helper
  void _scrollSide(SpriteComponent bg, double dt) {
    bg.y += scrollSpeed * dt;

    // Reset cuando sale completamente de pantalla
    if (bg.y >= size.y) {
      bg.y = bg.y - (2 * size.y);
    }

    // Asegurar que nunca haya un vacío mayor al tamaño de pantalla
    if (bg.y <= -2 * size.y) {
      bg.y += 2 * size.y;
    }
  }

  // Center background setup
  Future<void> _createScrollingCenterBackground() async {
    final Sprite centerSprite = await Sprite.load("carreteras/calle.png");

    // zona central (entre laterales)
    double centerWidth = size.x - (sideWidth * 2);
    final bgSize = Vector2(centerWidth, size.y);

    centerBg1 = SpriteComponent(sprite: centerSprite, size: bgSize);
    centerBg2 = SpriteComponent(sprite: centerSprite, size: bgSize);

    // colocar exacto después del lado izquierdo
    centerBg1.position = Vector2(sideWidth, 0);
    centerBg2.position = Vector2(sideWidth, -size.y);

    add(centerBg1);
    add(centerBg2);
  }

  // Resize handling mientras se juega
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    // Solo procesar si el tamaño es válido y los componentes están cargados
    if (size.x == 0 || size.y == 0 || !isLoaded) {
      return;
    }

    // Guardar el tamaño anterior para cálculos
    final Vector2 oldSize = this.size;

    // Recalcular dimensiones de carriles
    sideWidth = size.x * 0.18;
    double centerWidth = size.x - (sideWidth * 2);

    double minLaneWidth = 90;
    int numCentralLanes = (centerWidth / minLaneWidth).floor();
    numCentralLanes = numCentralLanes.clamp(3, 5);
    laneWidth = centerWidth / numCentralLanes;

    // Recalcular posiciones de carriles
    lanes = [];
    lanes.add(sideWidth * 0.35); // Carril lateral izquierdo

    for (int i = 0; i < numCentralLanes; i++) {
      double cx = sideWidth + (laneWidth * i) + (laneWidth / 2);
      lanes.add(cx);
    }

    lanes.add(size.x - (sideWidth * 0.35)); // Carril lateral derecho

    // Actualizar fondos manteniendo la continuidad del scroll
    _resizeSideBackgrounds(oldSize);
    _resizeCenterBackground(oldSize);

    // Actualizar posición del jugador si existe
    if (player.isLoaded) {
      player.setLanePositions(lanes);

      // Hacer que el jugador ocupe un porcentaje fijo del ancho del carril
      double targetWidth = laneWidth * 0.7; // 70% del ancho del carril
      double currentWidth = player.width;
      double scale = targetWidth / currentWidth;

      player.scale = Vector2.all(scale);

      player.position = Vector2(
        lanes[player.lane],
        size.y - player.height - 20,
      );
    }

    // Notificar a los managers sobre el cambio de carriles
    pickupManager.updateLanes(lanes);
    obstacleManager.updateLanes(lanes);
  }

  void _resizeSideBackgrounds(Vector2 oldSize) {
    final bgSize = Vector2(sideWidth, size.y);

    // Actualizar tamaños
    leftBg1.size = bgSize;
    leftBg2.size = bgSize;
    rightBg1.size = bgSize;
    rightBg2.size = bgSize;

    // Reposicionar manteniendo la continuidad del scroll
    _repositionScrollingBackground(leftBg1, leftBg2, oldSize);
    _repositionScrollingBackground(rightBg1, rightBg2, oldSize);

    // Posicionar horizontalmente
    leftBg1.position.x = 0;
    leftBg2.position.x = 0;
    rightBg1.position.x = size.x - sideWidth;
    rightBg2.position.x = size.x - sideWidth;
  }

  void _resizeCenterBackground(Vector2 oldSize) {
    double centerWidth = size.x - (sideWidth * 2);
    final bgSize = Vector2(centerWidth, size.y);

    // Actualizar tamaños
    centerBg1.size = bgSize;
    centerBg2.size = bgSize;

    // Reposicionar manteniendo la continuidad del scroll
    _repositionScrollingBackground(centerBg1, centerBg2, oldSize);

    // Posicionar horizontalmente
    centerBg1.position.x = sideWidth;
    centerBg2.position.x = sideWidth;
  }

  void _repositionScrollingBackground(
    SpriteComponent bg1,
    SpriteComponent bg2,
    Vector2 oldSize,
  ) {
    // Calcular el progreso del scroll basado en la posición Y actual
    double scrollProgress1 = (bg1.position.y % oldSize.y) / oldSize.y;
    double scrollProgress2 = (bg2.position.y % oldSize.y) / oldSize.y;

    // Reposicionar basado en el progreso para mantener continuidad
    bg1.position.y = scrollProgress1 * size.y;
    bg2.position.y = scrollProgress2 * size.y;

    // Asegurar que bg2 esté exactamente una pantalla arriba de bg1
    if (bg2.position.y >= bg1.position.y) {
      bg2.position.y = bg1.position.y - size.y;
    } else {
      bg1.position.y = bg2.position.y + size.y;
    }

    // Ajustar para evitar vacíos - asegurar que estén contiguos
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
