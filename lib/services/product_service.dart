import 'api_client.dart';
import '../models/product.dart';

class ProductService {
  final ApiClient _client = ApiClient();

  Future<List<Product>> getAll({bool activeOnly = false, String? search}) async {
    final response = await _client.get('/products', queryParameters: {
      if (activeOnly) 'activeOnly': 'true',
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return (response.data['data'] as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<String> create(Map<String, dynamic> data) async {
    final response = await _client.post('/products', data: data);
    return response.data['data']['id'] as String;
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _client.put('/products/$id', data: data);
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await _client.patch('/products/$id/toggle', data: {'isActive': isActive});
  }

  Future<void> delete(String id) async {
    await _client.delete('/products/$id');
  }
}
