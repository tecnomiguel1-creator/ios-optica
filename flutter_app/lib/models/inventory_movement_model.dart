class InventoryMovementModel {
  final int id;
  final int productoId;
  final String? codigo;
  final String? productoNombre;
  final String tipo; // entrada | salida | ajuste
  final int cantidad;
  final int stockAnterior;
  final int stockNuevo;
  final String motivo;
  final String? observaciones;
  final String? fechaMovimiento;

  InventoryMovementModel({
    required this.id,
    required this.productoId,
    this.codigo,
    this.productoNombre,
    required this.tipo,
    required this.cantidad,
    required this.stockAnterior,
    required this.stockNuevo,
    required this.motivo,
    this.observaciones,
    this.fechaMovimiento,
  });

  factory InventoryMovementModel.fromJson(Map<String, dynamic> json) {
    return InventoryMovementModel(
      id: json['id'] as int,
      productoId: json['producto_id'] as int,
      codigo: json['codigo'] as String?,
      productoNombre: json['producto_nombre'] as String?,
      tipo: json['tipo'] as String? ?? 'ajuste',
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      stockAnterior: (json['stock_anterior'] as num?)?.toInt() ?? 0,
      stockNuevo: (json['stock_nuevo'] as num?)?.toInt() ?? 0,
      motivo: json['motivo'] as String? ?? '',
      observaciones: json['observaciones'] as String?,
      fechaMovimiento: json['fecha_movimiento']?.toString(),
    );
  }
}
