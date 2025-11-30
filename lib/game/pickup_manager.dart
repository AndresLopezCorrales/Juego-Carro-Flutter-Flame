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

  PickupManager({
    required this.lanes,
    required this.player,
    required this.fuelManager,
    this.spawnInterval = 1.4, // intervalo inicial de spawneo de pickups
  });

  @override
  void update(double dt) {
    super.update(dt);

    // No spawnear pickups si el juego terminó
    if (gameRef.isGameOver) {
      return;
    }

    // Actualizar temporizador y spawnear pickups
    spawnTimer += dt;

    if (spawnTimer >= spawnInterval) {
      spawnTimer = 0;
      _spawnFuelPickup();
      _spawnCoin();
    }
  }

  void _spawnFuelPickup() {
    // No spawnear si el juego terminó
    if (gameRef.isGameOver) return;

    // Crear un nuevo pickup de gasolina
    if (lanes.isEmpty) return;

    // Elegir carril aleatorio
    final laneIndex = _rand.nextInt(lanes.length);
    final laneX = lanes[laneIndex];

    // Evitar generar si hay algo cerca en ese carril
    if (!_laneIsFree(laneX)) {
      // Reintentar en el siguiente ciclo
      spawnTimer = spawnInterval - 0.1;
      return;
    }

    // Crear pickup
    final pickup = FuelPickup(
      position: Vector2(laneX, -50),
      fuelManager: fuelManager,
    );

    gameRef.add(pickup);

    // Ajustar próximo intervalo de spawn
    spawnInterval = 1.2 + _rand.nextDouble() * 0.9;
  }

  void _spawnCoin() {
    // No spawnear si el juego terminó
    if (gameRef.isGameOver) return;

    if (lanes.isEmpty) return;

    final laneIndex = _rand.nextInt(lanes.length);
    final laneX = lanes[laneIndex];

    // mismo bloqueo que bidones
    if (!_laneIsFree(laneX)) {
      spawnTimer = spawnInterval - 0.1;
      return;
    }

    final coin = GoldCoin(position: Vector2(laneX, -50));

    gameRef.add(coin);

    // usa el MISMO sistema de intervalos que tus bidones
    spawnInterval = 1.0 + _rand.nextDouble() * 0.6;
  }

  bool _laneIsFree(double laneX) {
    // No verificar si el juego terminó (aunque esto probablemente no sea necesario)
    if (gameRef.isGameOver) return false;

    // Verificar si el carril está libre de obstáculos cercanos
    double minSeparation = gameRef.laneWidth * 0.8;

    for (final c in gameRef.children) {
      // SOLO revisar obstáculos y pickups
      if (c is! PositionComponent) continue;
      if (c is! SpriteComponent) continue;

      // Ignorar fondo y jugador y otros componentes
      if (c is Player) continue;
      if (c is FuelPickup) {
        // ok revisar
      } else if (c is! Obstacle) {
        continue;
      }

      // Revisar solo cerca del área de spawn
      if (c.y < 250) {
        if ((c.x - laneX).abs() < minSeparation) {
          return false;
        }
      }
    }

    return true;
  }

  void updateLanes(List<double> newLanes) {
    lanes = newLanes;
  }
}
