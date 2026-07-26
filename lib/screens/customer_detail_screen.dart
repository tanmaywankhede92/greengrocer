import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../core/params.dart';
import '../providers/customer_provider.dart';
import '../services/api_client.dart';
import '../providers/ledger_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/breadcrumb.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String id;
  const CustomerDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(id));
    final ledgerAsync = ref.watch(ledgerProvider(LedgerParams(customerId: id)));

    return customerAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(child: Text(ApiClient.humanizeError(e), style: const TextStyle(color: AppTheme.error))),
      data: (customer) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/customers')),
            title: Text(customer.name),
            actions: [
              TextButton(
                onPressed: () => context.go('/customers/$id/statement'),
                child: const Text('Statement'),
              ),
              IconButton(
                icon: const Icon(Icons.payment),
                onPressed: () => context.go('/payments'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Customers', route: '/customers'), Crumb('Customer Detail')]),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.primaryRed.withAlpha(20),
                          child: Text(AppUtils.initials(customer.name), style: const TextStyle(color: AppTheme.primaryRed, fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(customer.mobile, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                              if (customer.address != null && customer.address!.isNotEmpty) Text(customer.address!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Current Due', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(AppUtils.formatCurrency(customer.currentDue), style: TextStyle(color: customer.currentDue > 0 ? AppTheme.warning : AppTheme.success, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Ledger', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ledgerAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => Center(child: Text(ApiClient.humanizeError(e))),
                  data: (entries) {
                    if (entries.isEmpty) return const Center(child: Text('No ledger entries', style: TextStyle(color: AppTheme.textSecondary)));
                    return Card(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final e = entries[index];
                          return ListTile(
                            dense: true,
                            title: Text(e.description, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                            subtitle: Text(AppUtils.formatDate(e.entryDate), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (e.debit > 0) Text(AppUtils.formatCurrency(e.debit), style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
                                if (e.credit > 0) Text(AppUtils.formatCurrency(e.credit), style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
