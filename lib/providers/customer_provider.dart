import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/params.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

final customerServiceProvider = Provider<CustomerService>((ref) => CustomerService());

final customerListProvider = FutureProvider.family<({List<Customer> data, Map<String, dynamic>? meta}), CustomerListParams>((ref, params) async {
  final service = ref.read(customerServiceProvider);
  return service.getAll(
    search: params.search.isNotEmpty ? params.search : null,
    page: params.page,
    limit: params.limit,
    sort: params.sort,
    order: params.order,
  );
});

final customerDetailProvider = FutureProvider.family<Customer, String>((ref, id) async {
  final service = ref.read(customerServiceProvider);
  return service.getById(id);
});

final customerSearchProvider = FutureProvider.family<List<Customer>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final service = ref.read(customerServiceProvider);
  final result = await service.getAll(search: query, limit: 10);
  return result.data;
});
