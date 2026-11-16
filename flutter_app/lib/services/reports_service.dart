import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/sales_series_point.dart';

class ReportsService {
  final ApiClient _apiClient;

  ReportsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<SalesSeriesPoint>> getSalesSeries(String period) async {
    final response = await _apiClient.get(
      ApiEndpoints.reporteVentasSerie,
      queryParameters: {'periodo': period},
    );
    final series = (response as Map<String, dynamic>)['serie'] as List? ?? [];
    return series
        .map((item) => SalesSeriesPoint.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
