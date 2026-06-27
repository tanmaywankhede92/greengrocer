import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/params.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) => PaymentService());

final paymentListProvider = FutureProvider.family<({List<Payment> data, Map<String, dynamic>? meta}), PaymentListParams>((ref, params) async {
  final service = ref.read(paymentServiceProvider);
  return service.getAll(
    customerId: params.customerId,
    page: params.page,
    limit: params.limit,
  );
});
