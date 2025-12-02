import 'package:carreando/components/animations/explosion.dart';
import 'package:carreando/main.dart';
import 'package:carreando/managers/audio_manager.dart';
import 'package:flame/components.dart';

class FuelManager extends Component with HasGameRef<MyGame> {
  double maxFuel = 100;
  double fuel = 100;
  double drainRate = 5; // gasolina perdida por segundo

  bool get isEmpty => fuel <= 0;
  double get fuelPercent => fuel / maxFuel;

  // Gasolina que drena por segundo en carriles extremos
  double extremeLaneFuelDrain = 5;

  bool _explosionShown = false; // Para evitar múltiples explosiones

  @override
  void update(double dt) {
    super.update(dt);

    // Drenaje normal de gasolina
    fuel -= drainRate * dt;

    // Drenar gasolina adicional en carriles extremos (CONTINUO)
    if (game.player!.isOnExtremeLane) {
      // Aplica el drenaje adicional continuamente
      fuel -= extremeLaneFuelDrain * dt;
    }

    // Asegurar que no sea negativo
    if (fuel < 0) {
      fuel = 0;
    }

    // Mostrar explosión cuando se acaba la gasolina
    if (isEmpty && !_explosionShown) {
      _showExplosion();
      _explosionShown = true;
    }
  }

  void _showExplosion() {
    if (game.player == null) return;

    final explosion = ExplosionSimple(
      position: game.player!.position,
      size: Vector2(150, 150),
    );

    explosion.priority = 1000;
    AudioManager().playSfx('colision.wav');
    game.add(explosion);
  }

  // Restar gasolina por daño / choque
  void loseFuel(double amount) {
    fuel -= amount;

    if (fuel < 0) {
      fuel = 0;
    }
  }

  // Sumar gasolina por pickup
  void addFuel(double amount) {
    fuel += amount;

    if (fuel > maxFuel) {
      fuel = maxFuel;
    }
  }

  void reset() {
    fuel = maxFuel;
    _explosionShown = false;
  }
}
