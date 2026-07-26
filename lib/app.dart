import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'core/constants.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'services/api_client.dart';

class GreengrocerApp extends ConsumerStatefulWidget {
  const GreengrocerApp({super.key});

  @override
  ConsumerState<GreengrocerApp> createState() => _GreengrocerAppState();
}

class _GreengrocerAppState extends ConsumerState<GreengrocerApp> {
  @override
  void initState() {
    super.initState();
    ApiClient().setOnUnauthorized(() {
      if (mounted) {
        ref.read(authProvider.notifier).logout();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
