import 'dart:math';
import 'package:carreando/components/gold_coin.dart';
import 'package:flame/components.dart';

import '../components/fuel_pickup.dart';
import '../components/obstacle.dart';
import '../main.dart';
import 'fuel_manager.dart';
import '../components/player.dart';

class ObstacleManager extends Component with HasGameRef<MyGame> {
  final Random _rand = Random();

  List<double> lanes;
  final FuelManager fuelManager;
  final Player player;
  final bool isHorizontalMode;

  double spawnTimer = 0;
  double spawnInterval = 0.25;

  ObstacleManager({
    required this.lanes,
    required this.fuelManager,
    required this.player,
    this.isHorizontalMode = false,
  });

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.paused) return;

    spawnTimer += dt;

    if (spawnTimer >= spawnInterval) {
      spawnTimer = 0;
      _spawnObstacle();
    }
  }

  void _spawnObstacle() {
    if (lanes.isEmpty) return;

    final laneIndex = _rand.nextInt(lanes.length);

    if (isHorizontalMode) {
      // MODO HORIZONTAL: Spawn desde la derecha
      final spawnY = lanes[laneIndex];

      if (!_laneIsFree(spawnY, true)) return;

      final obstacle = Obstacle(
        fuelManager: fuelManager,
        player: player,
        startPosition: Vector2(gameRef.size.x + 50, spawnY),
        isHorizontalMode: true,
        obstacleSpritePath: gameRef
            .selectedVehicle
            .obstacleSpritePath, // Usar sprite del vehículo
      );
      gameRef.add(obstacle);
    } else {
      // MODO VERTICAL: Spawn desde arriba
      final laneX = lanes[laneIndex];
      if (!_laneIsFree(laneX, false)) return;

      final obstacle = Obstacle(
        fuelManager: fuelManager,
        player: player,
        startPosition: Vector2(laneX, -100),
        isHorizontalMode: false,
        obstacleSpritePath: gameRef
            .selectedVehicle
            .obstacleSpritePath, // Usar sprite del vehículo
      );
      gameRef.add(obstacle);
    }

    double baseRate = max(0.20, 0.7 - (gameRef.difficultyMultiplier * 0.03));
    spawnInterval = baseRate + _rand.nextDouble() * 0.15;
  }

  bool _laneIsFree(double lanePos, bool isHorizontal) {
    double minSeparation = gameRef.laneWidth * 0.8;

    for (final c in gameRef.children) {
      if (c is! PositionComponent) continue;
      if (c is! SpriteComponent) continue;

      if (c is Player) continue;
      if (c is FuelPickup || c is GoldCoin) {
        // ok revisar
      } else if (c is! Obstacle) {
        continue;
      }

      if (isHorizontal) {
        // En horizontal: revisar área de spawn a la derecha
        if (c.x > gameRef.size.x - 200) {
          if ((c.y - lanePos).abs() < minSeparation) {
            return false;
          }
        }
      } else {
        // En vertical: revisar área de spawn arriba
        if (c.y < 250) {
          if ((c.x - lanePos).abs() < minSeparation) {
            return false;
          }
        }
      }
    }

    return true;
  }

  void updateLanes(List<double> newLanes) {
    lanes = newLanes;
  }
}
