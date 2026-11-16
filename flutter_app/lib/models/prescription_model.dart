class PrescriptionModel {
  final int id;
  final int pacienteId;
  final String? fechaReceta;
  // Ojo Derecho (OD)
  final double? odEsfera;
  final double? odCilindro;
  final int? odEje;
  // Ojo Izquierdo (OI)
  final double? oiEsfera;
  final double? oiCilindro;
  final int? oiEje;
  // Adición y Distancia Pupilar
  final double? adicion;
  final double? distanciaPupilar;
  final String? diagnostico;
  final String? observaciones;
  final String? profesional;

  PrescriptionModel({
    required this.id,
    required this.pacienteId,
    this.fechaReceta,
    this.odEsfera,
    this.odCilindro,
    this.odEje,
    this.oiEsfera,
    this.oiCilindro,
    this.oiEje,
    this.adicion,
    this.distanciaPupilar,
    this.diagnostico,
    this.observaciones,
    this.profesional,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'] as int,
      pacienteId: json['paciente_id'] as int,
      fechaReceta: json['fecha_receta']?.toString(),
      odEsfera: (json['od_esfera'] as num?)?.toDouble(),
      odCilindro: (json['od_cilindro'] as num?)?.toDouble(),
      odEje: (json['od_eje'] as num?)?.toInt(),
      oiEsfera: (json['oi_esfera'] as num?)?.toDouble(),
      oiCilindro: (json['oi_cilindro'] as num?)?.toDouble(),
      oiEje: (json['oi_eje'] as num?)?.toInt(),
      adicion: (json['adicion'] as num?)?.toDouble(),
      distanciaPupilar: (json['distancia_pupilar'] as num?)?.toDouble(),
      diagnostico: json['diagnostico'] as String?,
      observaciones: json['observaciones'] as String?,
      profesional: json['profesional'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'paciente_id': pacienteId,
        if (fechaReceta != null) 'fecha_receta': fechaReceta,
        if (odEsfera != null) 'od_esfera': odEsfera,
        if (odCilindro != null) 'od_cilindro': odCilindro,
        if (odEje != null) 'od_eje': odEje,
        if (oiEsfera != null) 'oi_esfera': oiEsfera,
        if (oiCilindro != null) 'oi_cilindro': oiCilindro,
        if (oiEje != null) 'oi_eje': oiEje,
        if (adicion != null) 'adicion': adicion,
        if (distanciaPupilar != null) 'distancia_pupilar': distanciaPupilar,
        if (diagnostico != null) 'diagnostico': diagnostico,
        if (observaciones != null) 'observaciones': observaciones,
        if (profesional != null) 'profesional': profesional,
      };
}
