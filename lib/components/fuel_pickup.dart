import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';

import '../game/fuel_manager.dart';
import '../main.dart';
import 'player.dart';

class FuelPickup extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  static const double fallSpeed = 200;

  final FuelManager fuelManager;

  FuelPickup({required Vector2 position, required this.fuelManager})
    : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Cargar sprite y configurar tamaño
    sprite = await gameRef.loadSprite('power_ups/bidon.png');

    double maxWidth = gameRef.laneWidth * 0.45; //más pequeño
    double ratio = sprite!.srcSize.y / sprite!.srcSize.x;

    size = Vector2(maxWidth, maxWidth * ratio);

    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    // Mover pickup hacia abajo
    super.update(dt);

    y += fallSpeed * gameRef.difficultyMultiplier * dt;

    if (y > gameRef.size.y + height) removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    // Manejar colisión con el jugador
    if (other is Player) {
      fuelManager.addFuel(30);
      removeFromParent();
    }
    super.onCollisionStart(points, other);
  }
}
