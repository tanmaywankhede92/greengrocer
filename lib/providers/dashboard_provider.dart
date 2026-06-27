import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) => DashboardService());

final dashboardProvider = FutureProvider<DashboardStats>((ref) async {
  final service = ref.read(dashboardServiceProvider);
  return service.get();
});

final dashboardRefreshProvider = Provider<void>((ref) {
  ref.invalidate(dashboardProvider);
});
