import 'package:carreando/main.dart';
import 'package:flame/components.dart';

class FuelManager extends Component with HasGameRef<MyGame> {
  double maxFuel = 100;
  double fuel = 100;
  double drainRate = 5; // gasolina perdida por segundo

  bool get isEmpty => fuel <= 0;

  double get fuelPercent => fuel / maxFuel;

  @override
  void update(double dt) {
    super.update(dt);

    // Drenaje normal de gasolina
    fuel -= drainRate * dt;

    if (fuel < 0) {
      fuel = 0;
    }
  }

  // Restar gasolina por daño / choque
  void loseFuel(double amount) {
    fuel -= amount;

    if (fuel < 0) {
      fuel = 0;
    }

    print("NO -$amount fuel → $fuel");
  }

  // Sumar gasolina por pickup
  void addFuel(double amount) {
    fuel += amount;

    if (fuel > maxFuel) {
      fuel = maxFuel;
    }

    print("SI +$amount fuel → $fuel");
  }
}
