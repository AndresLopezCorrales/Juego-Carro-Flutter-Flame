import 'package:carreando/models/vehicle.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
import '../main.dart';

class Player extends SpriteComponent with HasGameRef<MyGame>, KeyboardHandler {
  final Vehicle vehicle;
  Player({required this.vehicle}) : super(anchor: Anchor.center) {
    priority = 100;
  }

  int lane = 0;
  late List<double> lanePositions;

  bool canMove = true;

  // Movimiento por teclado
  bool holdingLeft = false;
  bool holdingRight = false;
  bool holdingUp = false;
  bool holdingDown = false;
  double holdTimer = 0;
  double holdDelay = 0.15;

  bool get isOnLeftExtremeLane => lane == 0;
  bool get isOnRightExtremeLane => lane == game.lanes.length - 1;
  bool get isOnExtremeLane => isOnLeftExtremeLane || isOnRightExtremeLane;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load(vehicle.spritePath);

    double maxWidth = gameRef.laneWidth * 0.7;
    double ratio = sprite!.srcSize.y / sprite!.srcSize.x;

    width = maxWidth;
    height = maxWidth * ratio;

    // ROTAR EL COCHE EN MODO HORIZONTAL
    if (gameRef.isHorizontalMode) {
      angle = 1.5708; // 90 grados en radianes (π/2)
    }

    add(RectangleHitbox());
  }

  void setLanePositions(List<double> lanes) {
    lanePositions = lanes;
    lane = (lanes.length / 2).floor();

    if (gameRef.isHorizontalMode) {
      y = lanePositions[lane];
    } else {
      x = lanePositions[lane];
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.isHorizontalMode) {
      y = lanePositions[lane];
    } else {
      x = lanePositions[lane];
    }

    if (canMove) {
      holdTimer += dt;

      if (holdTimer >= holdDelay) {
        holdTimer = 0;

        if (gameRef.isHorizontalMode) {
          if (holdingUp) moveUp();
          if (holdingDown) moveDown();
        } else {
          if (holdingLeft) moveLeft();
          if (holdingRight) moveRight();
        }
      }
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!canMove) return true;

    if (event is KeyDownEvent) {
      if (gameRef.isHorizontalMode) {
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          holdingUp = true;
          holdingDown = false;
          moveUp();
          holdTimer = 0;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          holdingDown = true;
          holdingUp = false;
          moveDown();
          holdTimer = 0;
        }
      } else {
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
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        holdingUp = false;
        holdTimer = 0;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        holdingDown = false;
        holdTimer = 0;
      }
    }

    return true;
  }

  void moveLeft() {
    if (canMove && lane > 0) lane--;
  }

  void moveRight() {
    if (canMove && lane < lanePositions.length - 1) lane++;
  }

  void moveUp() {
    if (canMove && lane > 0) lane--;
  }

  void moveDown() {
    if (canMove && lane < lanePositions.length - 1) lane++;
  }

  // Método público para manejar toques desde el juego
  void handleTap(double touchX, double touchY) {
    if (!canMove) return;

    if (gameRef.isHorizontalMode) {
      // En horizontal: arriba/abajo de la pantalla
      final midY = gameRef.size.y / 2;

      if (touchY < midY) {
        moveUp();
      } else {
        moveDown();
      }
    } else {
      // En vertical: izquierda/derecha de la pantalla
      final midX = gameRef.size.x / 2;

      if (touchX < midX) {
        moveLeft();
      } else {
        moveRight();
      }
    }
  }
}
