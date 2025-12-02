import 'dart:ui';

import 'package:flame/components.dart';

class ExplosionSimple extends SpriteAnimationComponent with HasGameRef {
  final VoidCallback? onComplete;

  ExplosionSimple({
    required Vector2 position,
    required Vector2 size,
    this.onComplete,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    try {
      // Cargar sprites
      final sprite1 = await Sprite.load('explosion/explosion1.png');
      final sprite2 = await Sprite.load('explosion/explosion2.png');
      final sprite3 = await Sprite.load('explosion/explosion3.png');

      animation = SpriteAnimation.spriteList(
        [sprite1, sprite2, sprite3],
        stepTime: 0.2,
        loop: false,
      );

      Future.delayed(Duration(milliseconds: 400), () {
        if (isMounted) {
          removeFromParent();
          onComplete?.call();
        }
      });
    } catch (e) {
      removeFromParent();
    }
  }
}
