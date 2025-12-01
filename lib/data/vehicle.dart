import '../models/vehicle.dart';

final List<Vehicle> availableVehicles = [
  Vehicle(
    name: "Carro Normal",
    spritePath: "cars/white_car.png",
    roadSpritePath: "carreteras/normal/calle.png",
    sideSpritePath: "escenarios/normal/side.png",
    roadHorizontalSpritePath: "carreteras/normal/calle_h.png",
    sideHorizontalSpritePath: "escenarios/normal/side_h.png",
    obstacleSpritePath: "obstaculos/normal/obstaculo.png",
    gasSpritePath: "power_ups/normal/gas.png",
    moneySpritePath: "power_ups/normal/dinero.png",
  ),
  Vehicle(
    name: "Carro Bosque",
    spritePath: "cars/carro_bosque.png",
    roadSpritePath: "carreteras/bosque/calle_bosque.png",
    sideSpritePath: "escenarios/bosque/side_bosque.png",
    roadHorizontalSpritePath: "carreteras/bosque/calle_bosque_h.png",
    sideHorizontalSpritePath: "escenarios/bosque/side_bosque_h.png",
    obstacleSpritePath: "obstaculos/bosque/obstaculo.png",
    gasSpritePath: "power_ups/bosque/gas.png",
    moneySpritePath: "power_ups/bosque/dinero.png",
  ),
  Vehicle(
    name: "Nave",
    spritePath: "cars/ship.png",
    roadSpritePath: "carreteras/espacio/calle_espacio.png",
    sideSpritePath: "escenarios/espacio/side_espacio.png",
    roadHorizontalSpritePath: "carreteras/espacio/calle_espacio_h.png",
    sideHorizontalSpritePath: "escenarios/espacio/side_espacio_h.png",
    obstacleSpritePath: "obstaculos/espacio/obstaculo.png",
    gasSpritePath: "power_ups/espacio/gas.png",
    moneySpritePath: "power_ups/espacio/dinero.png",
  ),
];
