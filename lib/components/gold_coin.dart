import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';

import '../main.dart';
import 'player.dart';

class GoldCoin extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  static const double fallSpeed = 230;
  final bool isHorizontalMode;

  // Agregar parámetro para el path del sprite
  final String moneySpritePath;

  GoldCoin({
    required Vector2 position,
    this.isHorizontalMode = false,
    required this.moneySpritePath,
  }) : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Usar el sprite del vehículo seleccionado
    sprite = await gameRef.loadSprite(moneySpritePath);

    priority = 50;

    double maxWidth = gameRef.laneWidth * 0.40;
    double ratio = sprite!.srcSize.y / sprite!.srcSize.x;

    size = Vector2(maxWidth, maxWidth * ratio);

    add(CircleHitbox());
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
      if (gameRef.isGameOver) {
        removeFromParent();
        return;
      }

      gameRef.score += 20;
      gameRef.difficultyMultiplier += 0.15;
      removeFromParent();
    }

    super.onCollisionStart(points, other);
  }
}
