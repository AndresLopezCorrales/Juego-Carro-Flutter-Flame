class Usuario {
  final String id;
  final String nombre;
  final DateTime creadoEn;

  Usuario({required this.id, required this.nombre, required this.creadoEn});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      creadoEn: DateTime.parse(json['creado_en'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'nombre': nombre};
  }
}
