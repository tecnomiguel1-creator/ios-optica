class SupplierModel {
  static const categoryMarker = '[TIPO_PROVEEDOR:';
  static const categories = <String>[
    'Laboratorio óptico',
    'Distribuidor de monturas',
    'Distribuidor de lentes oftálmicos',
    'Accesorios y soluciones',
    'Servicios y mantenimiento',
    'Proveedor general',
  ];

  final int id;
  final String nombre;
  final String? rnc;
  final String? contacto;
  final String? telefono;
  final String? correo;
  final String? direccion;
  final String? observaciones;
  final String categoria;
  final bool activo;
  final String? fechaRegistro;

  SupplierModel({
    required this.id,
    required this.nombre,
    this.rnc,
    this.contacto,
    this.telefono,
    this.correo,
    this.direccion,
    this.observaciones,
    this.categoria = 'Proveedor general',
    this.activo = true,
    this.fechaRegistro,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    final data = _splitObservations(json['observaciones'] as String?);
    return SupplierModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      rnc: json['rnc'] as String?,
      contacto: json['contacto'] as String?,
      telefono: json['telefono'] as String?,
      correo: json['correo'] as String?,
      direccion: json['direccion'] as String?,
      observaciones: data.$2,
      categoria: data.$1,
      activo: json['activo'] as bool? ?? true,
      fechaRegistro: json['fecha_registro']?.toString(),
    );
  }

  static (String, String?) _splitObservations(String? raw) {
    if (raw == null || !raw.startsWith(categoryMarker)) {
      return ('Proveedor general', raw);
    }
    final end = raw.indexOf(']');
    if (end < 0) return ('Proveedor general', raw);
    final category = raw.substring(categoryMarker.length, end).trim();
    final notes = raw.substring(end + 1).trim();
    return (categories.contains(category) ? category : 'Proveedor general',
        notes.isEmpty ? null : notes);
  }

  String? get _storedObservations {
    final notes = observaciones?.trim();
    return '$categoryMarker$categoria]${notes == null || notes.isEmpty ? '' : ' $notes'}';
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        if (rnc != null) 'rnc': rnc,
        if (contacto != null) 'contacto': contacto,
        if (telefono != null) 'telefono': telefono,
        if (correo != null) 'correo': correo,
        if (direccion != null) 'direccion': direccion,
        if (_storedObservations != null) 'observaciones': _storedObservations,
      };
}
