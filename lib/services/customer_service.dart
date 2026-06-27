import 'api_client.dart';
import '../models/customer.dart';

class CustomerService {
  final ApiClient _client = ApiClient();

  Future<({List<Customer> data, Map<String, dynamic>? meta})> getAll({
    String? search, int page = 1, int limit = 20, String sort = 'name', String order = 'asc',
  }) async {
    final response = await _client.get('/customers', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page, 'limit': limit, 'sort': sort, 'order': order,
    });
    final body = response.data;
    final list = (body['data'] as List).map((e) => Customer.fromJson(e)).toList();
    return (data: list, meta: body['meta'] as Map<String, dynamic>?);
  }

  Future<Customer> getById(String id) async {
    final response = await _client.get('/customers/$id');
    return Customer.fromJson(response.data['data']);
  }

  Future<String> create(Map<String, dynamic> data) async {
    final response = await _client.post('/customers', data: data);
    return response.data['data']['id'] as String;
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _client.put('/customers/$id', data: data);
  }

  Future<void> delete(String id) async {
    await _client.delete('/customers/$id');
  }
}
