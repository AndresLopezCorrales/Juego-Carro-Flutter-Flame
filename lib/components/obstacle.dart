import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

import '../managers/fuel_manager.dart';
import '../main.dart';
import 'player.dart';

class Obstacle extends SpriteComponent
    with CollisionCallbacks, HasGameRef<MyGame> {
  double speed = 250;
  final FuelManager fuelManager;
  final Player player;
  final bool isHorizontalMode;

  bool hit = false;

  Obstacle({
    required this.fuelManager,
    required this.player,
    required Vector2 startPosition,
    this.isHorizontalMode = false,
  }) : super(anchor: Anchor.center, position: startPosition);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('obstaculos/cono.png');

    double maxWidth = gameRef.laneWidth * 0.55;
    double ratio = sprite!.srcSize.y / sprite!.srcSize.x;

    size = Vector2(maxWidth, maxWidth * ratio);

    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isHorizontalMode) {
      // MODO HORIZONTAL: Mover de derecha a izquierda
      x -= speed * gameRef.difficultyMultiplier * dt;
      if (x < -width) removeFromParent();
    } else {
      // MODO VERTICAL: Mover de arriba a abajo
      y += speed * gameRef.difficultyMultiplier * dt;
      if (y > gameRef.size.y + height) removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    if (hit) return;
    if (other is Player) {
      hit = true;
      fuelManager.loseFuel(20);
      removeFromParent();
    }
    super.onCollision(points, other);
  }
}
