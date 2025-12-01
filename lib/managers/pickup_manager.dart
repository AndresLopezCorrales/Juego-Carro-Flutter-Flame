import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../components/fuel_pickup.dart';
import '../components/obstacle.dart';
import '../components/player.dart';
import '../main.dart';
import 'fuel_manager.dart';
import '../components/gold_coin.dart';

class PickupManager extends Component with HasGameRef<MyGame> {
  final Random _rand = Random();

  List<double> lanes;
  final Player player;
  final FuelManager fuelManager;

  double spawnTimer = 0;
  double spawnInterval;

  final bool isHorizontalMode;

  PickupManager({
    required this.lanes,
    required this.player,
    required this.fuelManager,
    this.isHorizontalMode = false,
    this.spawnInterval = 1.4,
  });

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.isGameOver) {
      return;
    }

    spawnTimer += dt;

    if (spawnTimer >= spawnInterval) {
      spawnTimer = 0;
      _spawnFuelPickup();
      _spawnCoin();
    }
  }

  void _spawnFuelPickup() {
    if (gameRef.isGameOver) return;
    if (lanes.isEmpty) return;

    final laneIndex = _rand.nextInt(lanes.length);

    if (isHorizontalMode) {
      // MODO HORIZONTAL: Spawn desde la derecha, posición Y según lane
      final spawnY = lanes[laneIndex];

      if (!_laneIsFree(spawnY, true)) {
        spawnTimer = spawnInterval - 0.1;
        return;
      }

      final pickup = FuelPickup(
        position: Vector2(gameRef.size.x + 50, spawnY),
        fuelManager: fuelManager,
        isHorizontalMode: true,
        gasSpritePath:
            gameRef.selectedVehicle.gasSpritePath, // Usar sprite del vehículo
      );
      gameRef.add(pickup);
    } else {
      // MODO VERTICAL: Spawn desde arriba, posición X según lane
      final laneX = lanes[laneIndex];
      if (!_laneIsFree(laneX, false)) {
        spawnTimer = spawnInterval - 0.1;
        return;
      }
      final pickup = FuelPickup(
        position: Vector2(laneX, -50),
        fuelManager: fuelManager,
        isHorizontalMode: false,
        gasSpritePath:
            gameRef.selectedVehicle.gasSpritePath, // Usar sprite del vehículo
      );
      gameRef.add(pickup);
    }

    spawnInterval = 1.2 + _rand.nextDouble() * 0.9;
  }

  void _spawnCoin() {
    if (gameRef.isGameOver) return;
    if (lanes.isEmpty) return;

    final laneIndex = _rand.nextInt(lanes.length);

    if (isHorizontalMode) {
      // MODO HORIZONTAL: Spawn desde la derecha
      final spawnY = lanes[laneIndex];

      if (!_laneIsFree(spawnY, true)) {
        spawnTimer = spawnInterval - 0.1;
        return;
      }

      final coin = GoldCoin(
        position: Vector2(gameRef.size.x + 50, spawnY),
        isHorizontalMode: true,
        moneySpritePath:
            gameRef.selectedVehicle.moneySpritePath, // Usar sprite del vehículo
      );
      gameRef.add(coin);
    } else {
      // MODO VERTICAL: Spawn desde arriba
      final laneX = lanes[laneIndex];
      if (!_laneIsFree(laneX, false)) {
        spawnTimer = spawnInterval - 0.1;
        return;
      }
      final coin = GoldCoin(
        position: Vector2(laneX, -50),
        isHorizontalMode: false,
        moneySpritePath:
            gameRef.selectedVehicle.moneySpritePath, // Usar sprite del vehículo
      );
      gameRef.add(coin);
    }

    spawnInterval = 1.0 + _rand.nextDouble() * 0.6;
  }

  bool _laneIsFree(double lanePos, bool isHorizontal) {
    if (gameRef.isGameOver) return false;

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
