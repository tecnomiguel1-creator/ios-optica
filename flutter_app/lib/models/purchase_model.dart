class PurchaseItemModel {
  final int? id;
  final int productoId;
  final String? codigo;
  final String? productoNombre;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  PurchaseItemModel({
    this.id,
    required this.productoId,
    this.codigo,
    this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseItemModel(
      id: json['id'] as int?,
      productoId: json['producto_id'] as int,
      codigo: json['codigo'] as String?,
      productoNombre: json['producto_nombre'] as String?,
      cantidad: (json['cantidad'] as num).toInt(),
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'producto_id': productoId,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
      };
}

class PurchaseModel {
  final int id;
  final int proveedorId;
  final String? proveedorNombre;
  final String? fechaCompra;
  final String? numeroFactura;
  final double subtotal;
  final double impuestos;
  final double total;
  final String estado; // pendiente | recibida | anulada
  final String? observaciones;
  final String? fechaRegistro;
  final List<PurchaseItemModel> detalles;

  PurchaseModel({
    required this.id,
    required this.proveedorId,
    this.proveedorNombre,
    this.fechaCompra,
    this.numeroFactura,
    required this.subtotal,
    required this.impuestos,
    required this.total,
    required this.estado,
    this.observaciones,
    this.fechaRegistro,
    this.detalles = const [],
  });

  bool get isPending => estado == 'pendiente';
  bool get isReceived => estado == 'recibida';

  factory PurchaseModel.fromJson(Map<String, dynamic> json, [List<dynamic>? detallesJson]) {
    return PurchaseModel(
      id: json['id'] as int,
      proveedorId: json['proveedor_id'] as int,
      proveedorNombre: json['proveedor_nombre'] as String?,
      fechaCompra: json['fecha_compra']?.toString(),
      numeroFactura: json['numero_factura'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      impuestos: (json['impuestos'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      estado: json['estado'] as String? ?? 'pendiente',
      observaciones: json['observaciones'] as String?,
      fechaRegistro: json['fecha_registro']?.toString(),
      detalles: detallesJson != null
          ? detallesJson
              .map((d) => PurchaseItemModel.fromJson(d as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
