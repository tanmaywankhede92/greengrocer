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
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Record Payment'),
              onPressed: () => context.go('/payments/new'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Payments')]),
          Expanded(child: paymentsAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: AppTheme.error))),
            data: (result) {
              if (result.data.isEmpty) return const EmptyState(icon: Icons.payments_outlined, title: 'No payments recorded');
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: result.data.length,
                itemBuilder: (context, index) {
                  final p = result.data[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: p.isCancelled ? AppTheme.error.withAlpha(20) : AppTheme.success.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(p.isCancelled ? Icons.cancel : Icons.payment, color: p.isCancelled ? AppTheme.error : AppTheme.success, size: 22),
                      ),
                      title: Text(p.receiptNumber, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      subtitle: Text('${p.customer?.name ?? ''}  •  ${AppUtils.formatDate(p.paymentDate)}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(AppUtils.formatCurrency(p.amount), style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                          Text(p.mode.displayName, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
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
