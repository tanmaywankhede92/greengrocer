import 'api_client.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';

class BillService {
  final ApiClient _client = ApiClient();

  Future<({List<Bill> data, Map<String, dynamic>? meta})> getAll({
    String? search, String? status, String? from, String? to,
    int page = 1, int limit = 50,
  }) async {
    final response = await _client.get('/bills', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status != 'all') 'status': status,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      'page': page, 'limit': limit,
    });
    final body = response.data;
    final list = (body['data'] as List).map((e) => Bill.fromJson(e)).toList();
    return (data: list, meta: body['meta'] as Map<String, dynamic>?);
  }

  Future<({Bill bill, List<BillItem> items})> getById(String id) async {
    final response = await _client.get('/bills/$id');
    final data = response.data['data'];
    final bill = Bill.fromJson(data['bill']);
    final items = (data['items'] as List).map((e) => BillItem.fromJson(e)).toList();
    return (bill: bill, items: items);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _client.post('/bills', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> cancel(String id) async {
    await _client.post('/bills/$id/cancel');
  }
}
