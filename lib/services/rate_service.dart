import 'api_client.dart';
import '../models/daily_rate.dart';

class RateService {
  final ApiClient _client = ApiClient();

  Future<Map<String, DailyRate>> getByDate(DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await _client.get('/rates', queryParameters: {'date': dateStr});
    final data = response.data['data'] as Map<String, dynamic>;
    return data.map((key, value) => MapEntry(key, DailyRate.fromJson(value as Map<String, dynamic>)));
  }

  Future<void> upsert(String productId, double rate, DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await _client.put('/rates', data: {
      'productId': productId,
      'rate': rate,
      'rateDate': dateStr,
    });
  }

  Future<List<DailyRate>> getHistory(String productId, {int limit = 60}) async {
    final response = await _client.get('/rates/history/$productId', queryParameters: {'limit': limit});
    return (response.data['data'] as List).map((e) => DailyRate.fromJson(e)).toList();
  }
}
