class SalesSeriesPoint {
  final String label;
  final double total;
  final double collected;
  final int count;

  const SalesSeriesPoint({
    required this.label,
    required this.total,
    required this.collected,
    required this.count,
  });

  factory SalesSeriesPoint.fromJson(Map<String, dynamic> json) =>
      SalesSeriesPoint(
        label: json['etiqueta'] as String? ?? '-',
        total: (json['total'] as num?)?.toDouble() ?? 0,
        collected: (json['cobrado'] as num?)?.toDouble() ?? 0,
        count: (json['cantidad'] as num?)?.toInt() ?? 0,
      );
}
