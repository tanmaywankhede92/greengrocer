import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../core/params.dart';
import '../providers/payment_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/breadcrumb.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});
  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final params = PaymentListParams(page: _page, limit: 50);
    final paymentsAsync = ref.watch(paymentListProvider(params));

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: Column(
        children: [
          const Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Payments')]),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Record Payment'),
                onPressed: () => context.go('/payments/new'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ),
          Expanded(child: paymentsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.error))),
        data: (result) {
          if (result.data.isEmpty) return const EmptyState(icon: Icons.payments_outlined, title: 'No payments recorded');
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: result.data.length,
            itemBuilder: (context, index) {
              final p = result.data[index];
              return Card(
                child: ListTile(
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: p.isCancelled ? AppTheme.error.withAlpha(40) : AppTheme.success.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(p.isCancelled ? Icons.cancel : Icons.payment, color: p.isCancelled ? AppTheme.error : AppTheme.success, size: 22),
                  ),
                  title: Text(p.receiptNumber, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('${p.customer?.name ?? ''}  •  ${AppUtils.formatDate(p.paymentDate)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(AppUtils.formatCurrency(p.amount), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                      Text(p.mode.displayName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
          ),
        ],
      ),
    );
  }
}
