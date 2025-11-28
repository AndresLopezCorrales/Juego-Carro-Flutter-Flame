import 'dart:math';
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

  double spawnTimer = 0;
  double spawnInterval = 0.25; // intervalo inicial de spawneo de obstáculos

  ObstacleManager({
    required this.lanes,
    required this.fuelManager,
    required this.player,
  });

  @override
  void update(double dt) {
    // Actualizar temporizador y spawnear obstáculos
    super.update(dt);

    if (gameRef.paused) return;

    spawnTimer += dt;

    if (spawnTimer >= spawnInterval) {
      spawnTimer = 0;
      _spawnObstacle();
    }
  }

  void _spawnObstacle() {
    // Crear un nuevo obstáculo en un carril aleatorio
    double x = lanes[_rand.nextInt(lanes.length)];

    // Si el carril no está libre, NO intentar acumular spawns
    if (!_laneIsFree(x)) return;

    final spawnPos = Vector2(x, -100);

    final obstacle = Obstacle(
      fuelManager: fuelManager,
      player: player,
      startPosition: spawnPos,
    );

    gameRef.add(obstacle);

    // flujo constante y dinámico
    double baseRate = max(0.20, 0.7 - (gameRef.difficultyMultiplier * 0.03));
    spawnInterval = baseRate + _rand.nextDouble() * 0.15;
  }

  bool _laneIsFree(double laneX) {
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
