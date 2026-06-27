import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/product_service.dart';

final productServiceProvider = Provider<ProductService>((ref) => ProductService());

final productListProvider = FutureProvider<List<Product>>((ref) async {
  final service = ref.read(productServiceProvider);
  return service.getAll(activeOnly: true);
});

final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  final service = ref.read(productServiceProvider);
  return service.getAll();
});
