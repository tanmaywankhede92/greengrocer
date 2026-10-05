import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../models/customer.dart';
import '../widgets/bill_item_row.dart';
import '../screens/dashboard_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/customer_detail_screen.dart';
import '../screens/products_screen.dart';
import '../screens/daily_rates_screen.dart';
import '../screens/new_bill/new_bill_screen.dart';
import '../screens/bills_screen.dart';
import '../screens/draft_bills_screen.dart';
import '../screens/bill_detail_screen.dart';
import '../screens/bill_preview_screen.dart';
import '../models/draft_bill.dart';
import '../screens/payments_screen.dart';
import '../screens/add_payment_screen.dart';
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
      final isAuthRoute = state.matchedLocation == '/login';

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
        path: '/bills/preview',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BillPreviewScreen(
            customer: extra['customer'] as Customer,
            items: List<LineItem>.from(extra['items'] as List),
            deliveryCharge: extra['deliveryCharge'] as double? ?? 0,
            draftId: extra['draftId'] as String?,
            billDate: extra['billDate'] as DateTime?,
            editingBillId: extra['editingBillId'] as String?,
            editingBillNumber: extra['editingBillNumber'] as String?,
          );
        },
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
          GoRoute(path: '/bills/drafts', builder: (context, state) => const DraftBillsScreen()),
          GoRoute(
            path: '/bills/new',
            builder: (context, state) {
              final extra = state.extra;
              DraftBill? draft;
              String? editBillId;
              if (extra is DraftBill) {
                draft = extra;
              } else if (extra is Map<String, dynamic>) {
                if (extra['draft'] != null) draft = extra['draft'] as DraftBill;
                if (extra['editBillId'] != null) editBillId = extra['editBillId'] as String;
              }
              return NewBillScreen(initialDraft: draft, editBillId: editBillId);
            },
          ),
          GoRoute(
            path: '/bills/:id/edit',
            builder: (context, state) => NewBillScreen(editBillId: state.pathParameters['id']),
          ),
          GoRoute(path: '/bills/:id', builder: (context, state) => BillDetailScreen(id: state.pathParameters['id']!)),
          GoRoute(path: '/payments', builder: (context, state) => const PaymentsScreen()),
          GoRoute(path: '/payments/add', builder: (context, state) => const AddPaymentScreen()),
          GoRoute(path: '/customers/:id/statement', builder: (context, state) => StatementScreen(customerId: state.pathParameters['id']!)),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
