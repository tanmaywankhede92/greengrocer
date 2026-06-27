import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/params.dart';
import '../services/statement_service.dart';

final statementServiceProvider = Provider<StatementService>((ref) => StatementService());

final statementProvider = FutureProvider.family<Map<String, dynamic>, StatementParams>((ref, params) async {
  final service = ref.read(statementServiceProvider);
  return service.getStatement(params.customerId, from: params.from, to: params.to);
});
