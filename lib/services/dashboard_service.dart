import '../core/utils.dart';
import 'api_client.dart';
import '../models/dashboard_stats.dart';

class DashboardService {
  final ApiClient _client = ApiClient();

  Future<DashboardStats> get({DateTime? date}) async {
    final target = date ?? DateTime.now();
    final dateStr = AppUtils.formatDateApi(target);
    final tzOffsetMinutes = target.timeZoneOffset.inMinutes;

    final response = await _client.get(
      '/dashboard',
      queryParameters: {
        'date': dateStr,
        'tzOffset': tzOffsetMinutes,
      },
    );
    return DashboardStats.fromJson(response.data['data']);
  }
}
