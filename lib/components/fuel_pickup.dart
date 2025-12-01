import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';

import '../managers/fuel_manager.dart';
import '../main.dart';
import 'player.dart';

class FuelPickup extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  static const double fallSpeed = 200;

  final FuelManager fuelManager;
  final bool isHorizontalMode;

  // Agregar parámetro para el path del sprite
  final String gasSpritePath;

  FuelPickup({
    required Vector2 position,
    required this.fuelManager,
    this.isHorizontalMode = false,
    required this.gasSpritePath,
  }) : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Usar el sprite del vehículo seleccionado
    sprite = await gameRef.loadSprite(gasSpritePath);

    priority = 50;

    double maxWidth = gameRef.laneWidth * 0.45;
    double ratio = sprite!.srcSize.y / sprite!.srcSize.x;

    size = Vector2(maxWidth, maxWidth * ratio);

    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isHorizontalMode) {
      // MODO HORIZONTAL: Mover de derecha a izquierda
      x -= fallSpeed * gameRef.difficultyMultiplier * dt;
      if (x < -width) removeFromParent();
    } else {
      // MODO VERTICAL: Mover de arriba a abajo
      y += fallSpeed * gameRef.difficultyMultiplier * dt;
      if (y > gameRef.size.y + height) removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    if (other is Player) {
      fuelManager.addFuel(30);
      removeFromParent();
    }
    super.onCollisionStart(points, other);
  }
}
