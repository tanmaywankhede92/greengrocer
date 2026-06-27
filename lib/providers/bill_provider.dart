import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/params.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../services/bill_service.dart';

final billServiceProvider = Provider<BillService>((ref) => BillService());

final billListProvider = FutureProvider.family<({List<Bill> data, Map<String, dynamic>? meta}), BillListParams>((ref, params) async {
  final service = ref.read(billServiceProvider);
  return service.getAll(
    search: params.search.isNotEmpty ? params.search : null,
    status: params.status,
    from: params.from,
    to: params.to,
    page: params.page,
    limit: params.limit,
  );
});

final billDetailProvider = FutureProvider.family<({Bill bill, List<BillItem> items}), String>((ref, id) async {
  final service = ref.read(billServiceProvider);
  return service.getById(id);
});
