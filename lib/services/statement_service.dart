import 'api_client.dart';

class StatementService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getStatement(String customerId, {required String from, required String to}) async {
    final response = await _client.get('/statements/$customerId', queryParameters: {
      'from': from, 'to': to,
    });
    return response.data['data'] as Map<String, dynamic>;
  }
}
