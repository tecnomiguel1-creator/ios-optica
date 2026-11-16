class ProductModel {
  final int id;
  final String codigo;
  final String nombre;
  final String categoria; // montura | cristal | medicamento | accesorio | otro
  final String? marca;
  final String? descripcion;
  final double precioCompra;
  final double precioVenta;
  final int stockActual;
  final int stockMinimo;
  final bool activo;
  final String? fechaRegistro;
  /// Tasa decimal: 0.18 equivale a ITBIS 18 %. El backend es la fuente final.
  final double itbisRate;

  ProductModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.categoria,
    this.marca,
    this.descripcion,
    required this.precioCompra,
    required this.precioVenta,
    required this.stockActual,
    this.stockMinimo = 5,
    this.activo = true,
    this.fechaRegistro,
    this.itbisRate = 0.18,
  });

  bool get isLowStock => stockActual <= stockMinimo;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      categoria: json['categoria'] as String? ?? 'otro',
      marca: json['marca'] as String?,
      descripcion: json['descripcion'] as String?,
      precioCompra: (json['precio_compra'] as num?)?.toDouble() ?? 0.0,
      precioVenta: (json['precio_venta'] as num?)?.toDouble() ?? 0.0,
      stockActual: (json['stock_actual'] as num?)?.toInt() ?? 0,
      stockMinimo: (json['stock_minimo'] as num?)?.toInt() ?? 5,
      activo: json['activo'] as bool? ?? true,
      fechaRegistro: json['fecha_registro']?.toString(),
      itbisRate: ((json['itbis_tasa'] as num?)?.toDouble() ?? 18.0) / 100.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'nombre': nombre,
        'categoria': categoria,
        if (marca != null) 'marca': marca,
        if (descripcion != null) 'descripcion': descripcion,
        'precio_compra': precioCompra,
        'precio_venta': precioVenta,
        'stock_minimo': stockMinimo,
      };
}
