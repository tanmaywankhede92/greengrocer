import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_rate.dart';
import '../services/rate_service.dart';

final rateServiceProvider = Provider<RateService>((ref) => RateService());

final rateByDateProvider = FutureProvider.family<Map<String, DailyRate>, DateTime>((ref, date) async {
  final service = ref.read(rateServiceProvider);
  return service.getByDate(date);
});

final rateHistoryProvider = FutureProvider.family<List<DailyRate>, String>((ref, productId) async {
  final service = ref.read(rateServiceProvider);
  return service.getHistory(productId);
});

final rateSaveMutationProvider = Provider<RateService>((ref) => ref.read(rateServiceProvider));
