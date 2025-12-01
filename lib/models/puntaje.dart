class Puntaje {
  final String id;
  final String usuarioId;
  final String nombreUsuario;
  final int puntos;
  final DateTime fecha;

  Puntaje({
    required this.id,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.puntos,
    required this.fecha,
  });

  factory Puntaje.fromJson(Map<String, dynamic> json) {
    return Puntaje(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      nombreUsuario: json['nombre_usuario'] as String,
      puntos: json['puntos'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'usuario_id': usuarioId, 'puntos': puntos};
  }
}
