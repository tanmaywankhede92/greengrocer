import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business_settings.dart';
import '../services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) => SettingsService());

final settingsProvider = FutureProvider<BusinessSettings>((ref) async {
  final service = ref.read(settingsServiceProvider);
  return service.get();
});
