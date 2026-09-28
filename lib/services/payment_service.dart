import 'api_client.dart';
import '../models/payment.dart';

class PaymentService {
  final ApiClient _client = ApiClient();

  Future<({List<Payment> data, Map<String, dynamic>? meta})> getAll({
    String? customerId,
    String? from,
    String? to,
    String? mode,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _client.get('/payments', queryParameters: {
      if (customerId != null) 'customerId': customerId,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (mode != null) 'mode': mode,
      'page': page, 'limit': limit,
    });
    final body = response.data;
    final list = (body['data'] as List).map((e) => Payment.fromJson(e)).toList();
    return (data: list, meta: body['meta'] as Map<String, dynamic>?);
  }

  Future<List<Payment>> getAllPages({
    String? customerId,
    String? from,
    String? to,
    String? mode,
  }) async {
    const pageSize = 100;
    const maxPages = 50;
    final all = <Payment>[];
    for (var page = 1; page <= maxPages; page++) {
      final result = await getAll(
        customerId: customerId,
        from: from,
        to: to,
        mode: mode,
        page: page,
        limit: pageSize,
      );
      all.addAll(result.data);
      final total = (result.meta?['total'] as num?)?.toInt() ?? 0;
      if (result.data.length < pageSize || all.length >= total) break;
    }
    return all;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _client.post('/payments', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }
}
