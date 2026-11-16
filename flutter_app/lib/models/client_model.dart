class ClientModel {
  final int id;
  final String nombres;
  final String? apellidos;
  final String? telefono;
  final String? correo;
  final String? direccion;
  final String? fechaRegistro;

  ClientModel({
    required this.id,
    required this.nombres,
    this.apellidos,
    this.telefono,
    this.correo,
    this.direccion,
    this.fechaRegistro,
  });

  String get nombreCompleto =>
      apellidos != null && apellidos!.isNotEmpty ? '$nombres $apellidos' : nombres;

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as int,
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String?,
      telefono: json['telefono'] as String?,
      correo: json['correo'] as String?,
      direccion: json['direccion'] as String?,
      fechaRegistro: json['fecha_registro']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'nombres': nombres,
        if (apellidos != null) 'apellidos': apellidos,
        if (telefono != null) 'telefono': telefono,
        if (correo != null) 'correo': correo,
        if (direccion != null) 'direccion': direccion,
      };
}
