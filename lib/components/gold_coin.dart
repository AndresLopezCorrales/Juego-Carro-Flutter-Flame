import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';

import '../main.dart';
import 'player.dart';

class GoldCoin extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  static const double fallSpeed = 230;

  GoldCoin({required Vector2 position})
    : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('power_ups/oro.png');

    // Tamaño proporcional al ancho del carril
    double maxWidth = gameRef.laneWidth * 0.40;
    double ratio = sprite!.srcSize.y / sprite!.srcSize.x;

    size = Vector2(maxWidth, maxWidth * ratio);

    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Caída acelerada por dificultad
    y += fallSpeed * gameRef.difficultyMultiplier * dt;

    // Eliminar si sale de la pantalla
    if (y > gameRef.size.y + height) removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    if (other is Player) {
      // Aumentar puntuación al recoger
      gameRef.score += 20;

      // Subir velocidad del juego al recolectar
      gameRef.difficultyMultiplier += 0.15;

      removeFromParent();
    }

    super.onCollisionStart(points, other);
  }
}
