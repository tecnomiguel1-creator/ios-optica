// Modelos Clínicos, Administrativos y Financieros de ONLY EYES 360
// Conectados directamente a los routers FastAPI de Codex (clinical, finance, reports).

class AppointmentModel {
  final int id;
  final int pacienteId;
  final String? pacienteNombre;
  final String? telefono;
  final String fechaHora;
  final String motivo;
  final String
      estado; // pendiente | confirmada | completada | cancelada | no_asistio
  final String? profesional;
  final String? observaciones;
  final bool isMock;

  AppointmentModel({
    required this.id,
    required this.pacienteId,
    this.pacienteNombre,
    this.telefono,
    required this.fechaHora,
    required this.motivo,
    required this.estado,
    this.profesional,
    this.observaciones,
    this.isMock = false,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final nombres = json['nombres'] as String?;
    final apellidos = json['apellidos'] as String?;
    final nombreCompleto = (nombres != null && apellidos != null)
        ? '$nombres $apellidos'
        : (nombres ?? 'Paciente #${json['paciente_id']}');

    return AppointmentModel(
      id: json['id'] as int,
      pacienteId: json['paciente_id'] as int,
      pacienteNombre: nombreCompleto,
      telefono: json['telefono'] as String?,
      fechaHora: json['fecha_hora']?.toString() ?? '',
      motivo: json['motivo'] as String? ?? 'Consulta',
      estado: json['estado'] as String? ?? 'pendiente',
      profesional: json['profesional'] as String?,
      observaciones: json['observaciones'] as String?,
      isMock: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'paciente_id': pacienteId,
        'fecha_hora': fechaHora,
        'motivo': motivo,
        if (profesional != null) 'profesional': profesional,
        if (observaciones != null) 'observaciones': observaciones,
      };
}

class LabOrderModel {
  final int id;
  final String? codigo;
  final int clienteId;
  final String? clienteNombre;
  final int? recetaId;
  final int? ventaId;
  final String? tipoMontura;
  final String? tipoCristal;
  final String? laboratorio;
  final String? fechaPedido;
  final String? fechaEstimada;
  final String? fechaEntrega;
  final String
      estado; // pendiente | en_preparacion | en_laboratorio | listo | entregado | cancelado
  final String? observaciones;
  final double precio;
  final double abono;
  final String? responsable;
  final bool isMock;

  LabOrderModel({
    required this.id,
    this.codigo,
    required this.clienteId,
    this.clienteNombre,
    this.recetaId,
    this.ventaId,
    this.tipoMontura,
    this.tipoCristal,
    this.laboratorio,
    this.fechaPedido,
    this.fechaEstimada,
    this.fechaEntrega,
    required this.estado,
    this.observaciones,
    this.precio = 0.0,
    this.abono = 0.0,
    this.responsable,
    this.isMock = false,
  });

  double get saldo => (precio - abono) > 0 ? (precio - abono) : 0.0;

  factory LabOrderModel.fromJson(Map<String, dynamic> json,
      {String? clienteNombreFallback}) {
    return LabOrderModel(
      id: json['id'] as int,
      codigo: json['codigo'] as String?,
      clienteId: json['cliente_id'] as int,
      clienteNombre: clienteNombreFallback ??
          ('${json['nombres'] ?? ''} ${json['apellidos'] ?? ''}'
                  .trim()
                  .isNotEmpty
              ? '${json['nombres'] ?? ''} ${json['apellidos'] ?? ''}'.trim()
              : 'Cliente #${json['cliente_id']}'),
      recetaId: json['receta_id'] as int?,
      ventaId: json['venta_id'] as int?,
      tipoMontura: json['tipo_montura'] as String?,
      tipoCristal: json['tipo_cristal'] as String?,
      laboratorio: json['laboratorio'] as String?,
      fechaPedido: json['fecha_pedido']?.toString(),
      fechaEstimada: json['fecha_estimada']?.toString(),
      fechaEntrega: json['fecha_entrega']?.toString(),
      estado: json['estado'] as String? ?? 'pendiente',
      observaciones: json['observaciones'] as String?,
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      abono: (json['abono'] as num?)?.toDouble() ?? 0.0,
      responsable:
          json['responsable'] as String? ?? json['laboratorio'] as String?,
      isMock: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'cliente_id': clienteId,
        if (recetaId != null) 'receta_id': recetaId,
        if (ventaId != null) 'venta_id': ventaId,
        if (tipoMontura != null) 'tipo_montura': tipoMontura,
        if (tipoCristal != null) 'tipo_cristal': tipoCristal,
        if (laboratorio != null) 'laboratorio': laboratorio,
        if (fechaEstimada != null) 'fecha_estimada': fechaEstimada,
        if (observaciones != null) 'observaciones': observaciones,
        if (precio > 0) 'precio': precio,
        if (abono > 0) 'abono': abono,
      };
}

class RepairModel {
  final int id;
  final String? codigo;
  final int clienteId;
  final String? clienteNombre;
  final int? ventaId;
  final String tipo; // reparacion | garantia
  final String descripcion;
  final double costo;
  final double abono;
  final String? responsable;
  final String? fechaIngreso;
  final String? fechaEstimada;
  final String? fechaEntrega;
  final String
      estado; // recibido | en_revision | en_reparacion | listo | entregado | cancelado
  final String? observaciones;
  final bool isMock;

  RepairModel({
    required this.id,
    this.codigo,
    required this.clienteId,
    this.clienteNombre,
    this.ventaId,
    required this.tipo,
    required this.descripcion,
    required this.costo,
    this.abono = 0.0,
    this.responsable,
    this.fechaIngreso,
    this.fechaEstimada,
    this.fechaEntrega,
    required this.estado,
    this.observaciones,
    this.isMock = false,
  });

  double get saldo => (costo - abono) > 0 ? (costo - abono) : 0.0;

  factory RepairModel.fromJson(Map<String, dynamic> json,
      {String? clienteNombreFallback}) {
    return RepairModel(
      id: json['id'] as int,
      codigo: json['codigo'] as String?,
      clienteId: json['cliente_id'] as int,
      clienteNombre: clienteNombreFallback ??
          ('${json['nombres'] ?? ''} ${json['apellidos'] ?? ''}'
                  .trim()
                  .isNotEmpty
              ? '${json['nombres'] ?? ''} ${json['apellidos'] ?? ''}'.trim()
              : 'Cliente #${json['cliente_id']}'),
      ventaId: json['venta_id'] as int?,
      tipo: json['tipo'] as String? ?? 'reparacion',
      descripcion: json['descripcion'] as String? ?? '',
      costo: (json['costo'] as num?)?.toDouble() ?? 0.0,
      abono: (json['abono'] as num?)?.toDouble() ?? 0.0,
      responsable: json['responsable'] as String? ?? 'Taller Central ONLY EYES',
      fechaIngreso:
          (json['fecha_recepcion'] ?? json['fecha_ingreso'])?.toString(),
      fechaEstimada: json['fecha_estimada']?.toString(),
      fechaEntrega: json['fecha_entrega']?.toString(),
      estado: json['estado'] as String? ?? 'recibido',
      observaciones: json['observaciones'] as String?,
      isMock: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'cliente_id': clienteId,
        if (ventaId != null) 'venta_id': ventaId,
        'tipo': tipo,
        'descripcion': descripcion,
        'costo': costo,
        if (fechaEstimada != null) 'fecha_estimada': fechaEstimada,
        if (observaciones != null) 'observaciones': observaciones,
      };
}

class AccountPayableModel {
  final int compraId;
  final int proveedorId;
  final String proveedor;
  final String fechaCompra;
  final double total;
  final double montoPagado;
  final double saldo;
  final String estado;

  AccountPayableModel({
    required this.compraId,
    required this.proveedorId,
    required this.proveedor,
    required this.fechaCompra,
    required this.total,
    required this.montoPagado,
    required this.saldo,
    required this.estado,
  });

  factory AccountPayableModel.fromJson(Map<String, dynamic> json) {
    return AccountPayableModel(
      compraId: json['compra_id'] as int,
      proveedorId: json['proveedor_id'] as int,
      proveedor: json['proveedor_nombre'] as String? ??
          json['proveedor'] as String? ??
          'Proveedor',
      fechaCompra: json['fecha_compra']?.toString() ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      montoPagado: (json['monto_pagado'] as num?)?.toDouble() ?? 0.0,
      saldo: (json['saldo'] as num?)?.toDouble() ?? 0.0,
      estado: json['estado'] as String? ?? 'pendiente',
    );
  }
}

class FinancialReportSummary {
  final int cantidadVentas;
  final double totalVendido;
  final double cobrado;
  final double pendiente;
  final int citasTotal;
  final int productosBajoStock;
  final bool isMock;

  FinancialReportSummary({
    required this.cantidadVentas,
    required this.totalVendido,
    required this.cobrado,
    required this.pendiente,
    this.citasTotal = 0,
    this.productosBajoStock = 0,
    this.isMock = false,
  });

  factory FinancialReportSummary.fromJson(Map<String, dynamic> json,
      {int citas = 0, int bajoStock = 0}) {
    return FinancialReportSummary(
      cantidadVentas: (json['cantidad_ventas'] as num?)?.toInt() ?? 0,
      totalVendido: (json['total_vendido'] as num?)?.toDouble() ?? 0.0,
      cobrado: (json['cobrado'] as num?)?.toDouble() ?? 0.0,
      pendiente: (json['pendiente'] as num?)?.toDouble() ?? 0.0,
      citasTotal: citas,
      productosBajoStock: bajoStock,
      isMock: false,
    );
  }
}

class CashRegisterModel {
  final int id;
  final String fechaApertura;
  final double montoInicial;
  final double totalIngresos;
  final double totalEgresos;
  final double saldoActual;
  final String estado; // abierta | cerrada
  final String usuario;
  final bool isMock;

  CashRegisterModel({
    required this.id,
    required this.fechaApertura,
    required this.montoInicial,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.saldoActual,
    required this.estado,
    required this.usuario,
    this.isMock = true,
  });
}
