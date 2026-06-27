import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/params.dart';
import '../models/ledger_entry.dart';
import '../services/ledger_service.dart';

final ledgerServiceProvider = Provider<LedgerService>((ref) => LedgerService());

final ledgerProvider = FutureProvider.family<List<LedgerEntry>, LedgerParams>((ref, params) async {
  final service = ref.read(ledgerServiceProvider);
  return service.getByCustomer(params.customerId, from: params.from, to: params.to);
});
