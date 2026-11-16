class PatientModel {
  final int id;
  final int clienteId;
  final String? nombres;
  final String? apellidos;
  final String? telefono;
  final String? fechaNacimiento;
  final String? antecedentes;
  final String? alergias;
  final String? observaciones;
  final String? fechaRegistro;

  PatientModel({
    required this.id,
    required this.clienteId,
    this.nombres,
    this.apellidos,
    this.telefono,
    this.fechaNacimiento,
    this.antecedentes,
    this.alergias,
    this.observaciones,
    this.fechaRegistro,
  });

  String get nombreCompleto =>
      apellidos != null && apellidos!.isNotEmpty ? '$nombres $apellidos' : (nombres ?? 'Paciente #$id');

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as int,
      clienteId: json['cliente_id'] as int,
      nombres: json['nombres'] as String?,
      apellidos: json['apellidos'] as String?,
      telefono: json['telefono'] as String?,
      fechaNacimiento: json['fecha_nacimiento']?.toString(),
      antecedentes: json['antecedentes'] as String?,
      alergias: json['alergias'] as String?,
      observaciones: json['observaciones'] as String?,
      fechaRegistro: json['fecha_registro']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'cliente_id': clienteId,
        if (fechaNacimiento != null) 'fecha_nacimiento': fechaNacimiento,
        if (antecedentes != null) 'antecedentes': antecedentes,
        if (alergias != null) 'alergias': alergias,
        if (observaciones != null) 'observaciones': observaciones,
      };
}
