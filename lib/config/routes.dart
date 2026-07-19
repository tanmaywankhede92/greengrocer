import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/customer_detail_screen.dart';
import '../screens/products_screen.dart';
import '../screens/daily_rates_screen.dart';
import '../screens/new_bill_screen.dart';
import '../screens/bills_screen.dart';
import '../screens/bill_detail_screen.dart';
import '../screens/payments_screen.dart';
import '../screens/statement_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/layout.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
        parentNavigatorKey: _rootNavigatorKey,
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
        parentNavigatorKey: _rootNavigatorKey,
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => Layout(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/customers', builder: (context, state) => const CustomersScreen()),
          GoRoute(path: '/customers/:id', builder: (context, state) => CustomerDetailScreen(id: state.pathParameters['id']!)),
          GoRoute(path: '/products', builder: (context, state) => const ProductsScreen()),
          GoRoute(path: '/rates', builder: (context, state) => const DailyRatesScreen()),
          GoRoute(path: '/bills', builder: (context, state) => const BillsScreen()),
          GoRoute(path: '/bills/new', builder: (context, state) => const NewBillScreen()),
          GoRoute(path: '/bills/:id', builder: (context, state) => BillDetailScreen(id: state.pathParameters['id']!)),
          GoRoute(path: '/payments', builder: (context, state) => const PaymentsScreen()),
          GoRoute(path: '/customers/:id/statement', builder: (context, state) => StatementScreen(customerId: state.pathParameters['id']!)),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
