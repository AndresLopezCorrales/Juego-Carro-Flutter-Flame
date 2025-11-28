import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

import '../game/fuel_manager.dart';
import '../main.dart';
import 'player.dart';

class Obstacle extends SpriteComponent
    with CollisionCallbacks, HasGameRef<MyGame> {
  double speed = 250; // velocidad de caída
  final FuelManager fuelManager;
  final Player player;

  bool hit = false;

  Obstacle({
    required this.fuelManager,
    required this.player,
    required Vector2 startPosition,
  }) : super(anchor: Anchor.center, position: startPosition);

  @override
  Future<void> onLoad() async {
    // Cargar sprite y configurar tamaño
    sprite = await Sprite.load('obstaculos/cono.png');

    double maxWidth = gameRef.laneWidth * 0.55;
    double ratio = sprite!.srcSize.y / sprite!.srcSize.x;

    size = Vector2(maxWidth, maxWidth * ratio);

    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    // Mover obstáculo hacia abajo
    super.update(dt);

    y += speed * gameRef.difficultyMultiplier * dt;

    if (y > gameRef.size.y + height) removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    // Manejar colisión con el jugador
    if (hit) return;
    if (other is Player) {
      hit = true;
      fuelManager.loseFuel(20);
      removeFromParent();
    }
    super.onCollision(points, other);
  }
}
