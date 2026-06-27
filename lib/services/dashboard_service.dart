import 'api_client.dart';
import '../models/dashboard_stats.dart';

class DashboardService {
  final ApiClient _client = ApiClient();

  Future<DashboardStats> get() async {
    final response = await _client.get('/dashboard');
    return DashboardStats.fromJson(response.data['data']);
  }
}
