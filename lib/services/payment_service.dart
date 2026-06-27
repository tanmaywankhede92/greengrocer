import 'api_client.dart';
import '../models/payment.dart';

class PaymentService {
  final ApiClient _client = ApiClient();

  Future<({List<Payment> data, Map<String, dynamic>? meta})> getAll({
    String? customerId, int page = 1, int limit = 50,
  }) async {
    final response = await _client.get('/payments', queryParameters: {
      if (customerId != null) 'customerId': customerId,
      'page': page, 'limit': limit,
    });
    final body = response.data;
    final list = (body['data'] as List).map((e) => Payment.fromJson(e)).toList();
    return (data: list, meta: body['meta'] as Map<String, dynamic>?);
  }

  Future<String> create(Map<String, dynamic> data) async {
    final response = await _client.post('/payments', data: data);
    return response.data['data']['id'] as String;
  }
}
