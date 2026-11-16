/// Modelos para Ventas, Pagos y Cuentas por Cobrar conectados a FastAPI
class SaleItemModel {
  final int? id;
  final int productoId;
  final String codigo;
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  final double descuento;
  final double subtotal;

  SaleItemModel({
    this.id,
    required this.productoId,
    required this.codigo,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    this.descuento = 0.0,
    required this.subtotal,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    final precio = (json['precio_unitario'] as num?)?.toDouble() ?? 0.0;
    final cant = (json['cantidad'] as num?)?.toInt() ?? 1;
    final desc = (json['descuento'] as num?)?.toDouble() ?? 0.0;
    return SaleItemModel(
      id: json['id'] as int?,
      productoId: json['producto_id'] as int,
      codigo: json['codigo'] as String? ?? 'PROD',
      nombre: json['producto_nombre'] as String? ??
          json['nombre'] as String? ??
          'Producto #${json['producto_id']}',
      cantidad: cant,
      precioUnitario: precio,
      descuento: desc,
      subtotal: (cant * precio) - desc,
    );
  }

  Map<String, dynamic> toJson() => {
        'producto_id': productoId,
        'cantidad': cantidad,
        'descuento': descuento,
      };
}

class SalePaymentModel {
  final int id;
  final double monto;

  /// Nulo cuando el cobro histórico no capturó cuánto entregó el cliente.
  final double? montoRecibido;
  final double cambio;
  final String metodoPago;
  final String? referencia;
  final String? observaciones;
  final String? fechaPago;

  SalePaymentModel({
    required this.id,
    required this.monto,
    this.montoRecibido,
    this.cambio = 0.0,
    required this.metodoPago,
    this.referencia,
    this.observaciones,
    this.fechaPago,
  });

  factory SalePaymentModel.fromJson(Map<String, dynamic> json) {
    return SalePaymentModel(
      id: json['id'] as int,
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      montoRecibido: (json['monto_recibido'] as num?)?.toDouble(),
      cambio: (json['cambio'] as num?)?.toDouble() ?? 0.0,
      metodoPago: json['metodo_pago'] as String? ?? 'efectivo',
      referencia: json['referencia'] as String?,
      observaciones: json['observaciones'] as String?,
      fechaPago: json['fecha_pago']?.toString(),
    );
  }
}

class SaleModel {
  final int id;
  final String numeroFactura;
  final String? ncf;
  final int? clienteId;
  final String clienteNombre;
  final String fechaVenta;
  final double subtotal;
  final double descuentoTotal;
  final double impuestos;
  final double total;
  final String metodoPago; // efectivo | tarjeta | transferencia
  final String estadoPago; // pendiente | parcial | pagada | anulada
  final double montoPagado;
  final double balancePendiente;
  final List<SaleItemModel> items;
  final List<SalePaymentModel> pagos;
  final bool isMock;

  SaleModel({
    required this.id,
    required this.numeroFactura,
    this.ncf,
    this.clienteId,
    required this.clienteNombre,
    required this.fechaVenta,
    required this.subtotal,
    this.descuentoTotal = 0.0,
    this.impuestos = 0.0,
    required this.total,
    required this.metodoPago,
    required this.estadoPago,
    required this.montoPagado,
    required this.balancePendiente,
    this.items = const [],
    this.pagos = const [],
    this.isMock = false,
  });

  bool get isPaid => estadoPago == 'pagada';
  bool get isPartial => estadoPago == 'parcial';
  bool get isPending => estadoPago == 'pendiente';
  bool get isCancelled => estadoPago == 'anulada';
  double get cambioTotal =>
      pagos.fold(0.0, (total, payment) => total + payment.cambio);

  factory SaleModel.fromJson(Map<String, dynamic> json,
      {List<dynamic>? detalles,
      List<dynamic>? pagosJson,
      String? clienteNombreFallback}) {
    final tot = (json['total'] as num?)?.toDouble() ?? 0.0;
    final pagado = (json['monto_pagado'] as num?)?.toDouble() ?? 0.0;
    final sal = (json['saldo'] as num?)?.toDouble() ?? (tot - pagado);

    return SaleModel(
      id: json['id'] as int,
      numeroFactura: json['numero_factura'] as String? ??
          json['numero'] as String? ??
          'FAC-${json['id']}',
      ncf: json['ncf'] as String?,
      clienteId: json['cliente_id'] as int?,
      clienteNombre: (() {
        final name =
            (clienteNombreFallback ?? json['cliente_nombre'] as String?)
                ?.trim();
        return name == null || name.isEmpty ? 'Consumidor final' : name;
      })(),
      fechaVenta: json['fecha_venta']?.toString() ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      descuentoTotal: (json['descuento'] as num?)?.toDouble() ?? 0.0,
      impuestos: (json['impuestos'] as num?)?.toDouble() ?? 0.0,
      total: tot,
      metodoPago: pagosJson == null || pagosJson.isEmpty
          ? 'pendiente'
          : pagosJson.length == 1
              ? ((pagosJson.first as Map<String, dynamic>)['metodo_pago']
                      as String? ??
                  'registrado')
              : 'mixto',
      estadoPago: json['estado_pago'] as String? ??
          json['estado'] as String? ??
          'pendiente',
      montoPagado: pagado,
      balancePendiente: sal > 0 ? sal : 0.0,
      items: detalles != null
          ? detalles
              .map((d) => SaleItemModel.fromJson(d as Map<String, dynamic>))
              .toList()
          : [],
      pagos: pagosJson != null
          ? pagosJson
              .map((p) => SalePaymentModel.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
      isMock: false,
    );
  }
}

class AccountReceivableModel {
  final int ventaId;
  final int? clienteId;
  final String? nombres;
  final String? apellidos;
  final String fechaVenta;
  final double total;
  final double montoPagado;
  final double saldo;
  final String estado;

  AccountReceivableModel({
    required this.ventaId,
    this.clienteId,
    this.nombres,
    this.apellidos,
    required this.fechaVenta,
    required this.total,
    required this.montoPagado,
    required this.saldo,
    required this.estado,
  });

  String get clienteNombreCompleto => apellidos != null && apellidos!.isNotEmpty
      ? '$nombres $apellidos'
      : (nombres ?? 'Cliente General');

  factory AccountReceivableModel.fromJson(Map<String, dynamic> json) {
    return AccountReceivableModel(
      ventaId: json['venta_id'] as int,
      clienteId: json['cliente_id'] as int?,
      nombres: json['nombres'] as String?,
      apellidos: json['apellidos'] as String?,
      fechaVenta: json['fecha_venta']?.toString() ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      montoPagado: (json['monto_pagado'] as num?)?.toDouble() ?? 0.0,
      saldo: (json['saldo'] as num?)?.toDouble() ?? 0.0,
      estado: json['estado'] as String? ?? 'pendiente',
    );
  }
}
