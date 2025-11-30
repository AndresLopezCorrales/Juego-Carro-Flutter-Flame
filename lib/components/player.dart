import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
import '../main.dart';

class Player extends SpriteComponent
    with HasGameRef<MyGame>, TapCallbacks, KeyboardHandler {
  Player() : super(anchor: Anchor.center);

  int lane = 0;
  late List<double> lanePositions;

  // AGREGAR ESTA PROPIEDAD
  bool canMove = true;

  // Movimiento por teclado
  bool holdingLeft = false;
  bool holdingRight = false;
  double holdTimer = 0;
  double holdDelay = 0.15;

  bool get isOnLeftExtremeLane => lane == 0;
  bool get isOnRightExtremeLane => lane == game.lanes.length - 1;
  bool get isOnExtremeLane => isOnLeftExtremeLane || isOnRightExtremeLane;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('cars/white_car.png');

    double maxWidth = gameRef.laneWidth * 0.7;
    double ratio = sprite!.srcSize.y / sprite!.srcSize.x;

    width = maxWidth;
    height = maxWidth * ratio;

    add(RectangleHitbox());
  }

  void setLanePositions(List<double> lanes) {
    lanePositions = lanes;
    lane = (lanes.length / 2).floor();
    x = lanePositions[lane];
  }

  @override
  void update(double dt) {
    super.update(dt);

    x = lanePositions[lane];

    // AGREGAR ESTA VERIFICACIÓN
    if (canMove && (holdingLeft || holdingRight)) {
      holdTimer += dt;

      if (holdTimer >= holdDelay) {
        holdTimer = 0;

        if (holdingLeft) moveLeft();
        if (holdingRight) moveRight();
      }
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // AGREGAR ESTA VERIFICACIÓN
    if (!canMove) return true;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        holdingLeft = true;
        holdingRight = false;
        moveLeft();
        holdTimer = 0;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        holdingRight = true;
        holdingLeft = false;
        moveRight();
        holdTimer = 0;
      }
    }

    if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        holdingLeft = false;
        holdTimer = 0;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        holdingRight = false;
        holdTimer = 0;
      }
    }

    return true;
  }

  void moveLeft() {
    // AGREGAR ESTA VERIFICACIÓN
    if (canMove && lane > 0) lane--;
  }

  void moveRight() {
    // AGREGAR ESTA VERIFICACIÓN
    if (canMove && lane < lanePositions.length - 1) lane++;
  }

  @override
  void onTapDown(TapDownEvent event) {
    // AGREGAR ESTA VERIFICACIÓN
    if (!canMove) return;

    final touchX = event.localPosition.x;
    final mid = gameRef.size.x / 2;

    if (touchX < mid) {
      moveLeft();
    } else {
      moveRight();
    }
  }
}
