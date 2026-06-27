import 'api_client.dart';
import '../models/business_settings.dart';

class SettingsService {
  final ApiClient _client = ApiClient();

  Future<BusinessSettings> get() async {
    final response = await _client.get('/settings');
    return BusinessSettings.fromJson(response.data['data']);
  }

  Future<void> update(Map<String, dynamic> data) async {
    await _client.put('/settings', data: data);
  }
}
