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

  // Movimiento por teclado
  bool holdingLeft = false;
  bool holdingRight = false;
  double holdTimer = 0;
  double holdDelay = 0.15; // tiempo entre saltos de carril al dejar presionado

  @override
  Future<void> onLoad() async {
    // Cargar sprite y configurar tamaño
    sprite = await Sprite.load('cars/white_car.png');

    double maxWidth = gameRef.laneWidth * 0.7;
    double ratio = sprite!.srcSize.y / sprite!.srcSize.x;

    width = maxWidth;
    height = maxWidth * ratio;

    add(RectangleHitbox());
  }

  void setLanePositions(List<double> lanes) {
    // Configurar posiciones de carril
    lanePositions = lanes;
    lane = (lanes.length / 2).floor(); // carril central
    x = lanePositions[lane];
  }

  @override
  void update(double dt) {
    // Actualizar posición y manejo de hold
    super.update(dt);

    x = lanePositions[lane]; // siempre centrado

    if (holdingLeft || holdingRight) {
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
    // KEY DOWN
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        holdingLeft = true;
        holdingRight = false;
        moveLeft(); // primer movimiento instantáneo
        holdTimer = 0;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        holdingRight = true;
        holdingLeft = false;
        moveRight(); // primer movimiento instantáneo
        holdTimer = 0;
      }
    }

    // KEY UP
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
    if (lane > 0) lane--;
  }

  void moveRight() {
    if (lane < lanePositions.length - 1) lane++;
  }

  // Manejo de toques en pantalla móvil
  @override
  void onTapDown(TapDownEvent event) {
    final touchX = event.localPosition.x;
    final mid = gameRef.size.x / 2;

    if (touchX < mid) {
      moveLeft();
    } else {
      moveRight();
    }
  }
}
