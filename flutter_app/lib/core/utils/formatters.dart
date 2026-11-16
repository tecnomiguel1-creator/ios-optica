/// Formateadores de valores clínicos y comerciales para República Dominicana
class Formatters {
  /// Formato de dioptrías oftalmológicas (+1.25 D, -2.50 D, Plano)
  static String formatDiopter(num? value) {
    if (value == null) return '-';
    if (value == 0) return 'Plano';
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)} D';
  }

  /// Formato de eje (0° a 180°)
  static String formatAxis(num? value) {
    if (value == null) return '-';
    return '${value.toInt()}°';
  }

  /// Formato de distancia pupilar (ej. 62.0 mm)
  static String formatPd(num? value) {
    if (value == null) return '-';
    return '${value.toStringAsFixed(1)} mm';
  }

  /// Formato monetario dominicano estándar (RD$1,500.00, RD$12,500.50, RD$1,000,000.00)
  /// Respeta valores numéricos sin alterar el cálculo matemático subyacente.
  static String formatCurrency(num? value, {String symbol = 'RD\$', bool includeSpace = false}) {
    if (value == null) return '$symbol${includeSpace ? ' ' : ''}0.00';
    final isNegative = value < 0;
    final absVal = value.abs();
    final parts = absVal.toStringAsFixed(2).split('.');
    final wholePart = parts[0];
    final decimalPart = parts[1];

    final buffer = StringBuffer();
    final len = wholePart.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(wholePart[i]);
    }
    final prefix = isNegative ? '-$symbol' : symbol;
    final space = includeSpace ? ' ' : '';
    return '$prefix$space$buffer.$decimalPart';
  }

  /// Formato de fecha legible (DD/MM/AAAA)
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  /// Formato de fecha y hora legible (DD/MM/AAAA hh:mm am/pm)
  static String formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} $hour:$min $period';
    } catch (_) {
      return dateStr;
    }
  }
}
