import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../core/params.dart';
import '../providers/customer_provider.dart';
import '../providers/statement_provider.dart';
import '../widgets/breadcrumb.dart';
import '../widgets/loading_widget.dart';

class StatementScreen extends ConsumerStatefulWidget {
  final String customerId;
  const StatementScreen({super.key, required this.customerId});
  @override
  ConsumerState<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends ConsumerState<StatementScreen> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerDetailProvider(widget.customerId));
    final params = StatementParams(customerId: widget.customerId, from: AppUtils.formatDateApi(_from), to: AppUtils.formatDateApi(_to));
    final statementAsync = ref.watch(statementProvider(params));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/customers/${widget.customerId}')),
        title: const Text('Customer Statement'),
      ),
      body: customerAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
        data: (customer) {
          return Column(
            children: [
              const Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Customers', route: '/customers'), Crumb('Statement')]),
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(customer.mobile, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(context: context, initialDate: _from, firstDate: DateTime(2020), lastDate: DateTime.now());
                                if (picked != null) setState(() => _from = picked);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'From', isDense: true),
                                child: Text(AppUtils.formatDate(_from), style: const TextStyle(color: AppTheme.textPrimary)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(context: context, initialDate: _to, firstDate: DateTime(2020), lastDate: DateTime.now());
                                if (picked != null) setState(() => _to = picked);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'To', isDense: true),
                                child: Text(AppUtils.formatDate(_to), style: const TextStyle(color: AppTheme.textPrimary)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: statementAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (data) {
                    final rows = data['rows'] as List<dynamic>? ?? [];
                    final openingBalance = (data['openingBalance'] ?? 0).toDouble();
                    final closingBalance = (data['closingBalance'] ?? 0).toDouble();
                    final totalDebit = (data['totalDebit'] ?? 0).toDouble();
                    final totalCredit = (data['totalCredit'] ?? 0).toDouble();

                    return Column(
                      children: [
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _stat('Opening', openingBalance),
                                _stat('Debit', totalDebit, AppTheme.error),
                                _stat('Credit', totalCredit, AppTheme.success),
                                _stat('Closing', closingBalance, AppTheme.warning),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: rows.length,
                            itemBuilder: (context, index) {
                              final r = rows[index] as Map<String, dynamic>;
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(r['description'] ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                                            Text(AppUtils.formatDate(DateTime.parse(r['date'])), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 80, child: Text((r['debit'] ?? 0) > 0 ? AppUtils.formatCurrency((r['debit'] as num).toDouble()) : '', style: const TextStyle(color: AppTheme.error), textAlign: TextAlign.right)),
                                      SizedBox(width: 80, child: Text((r['credit'] ?? 0) > 0 ? AppUtils.formatCurrency((r['credit'] as num).toDouble()) : '', style: const TextStyle(color: AppTheme.success), textAlign: TextAlign.right)),
                                      SizedBox(width: 80, child: Text(AppUtils.formatCurrency((r['balance'] as num).toDouble()), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, double amount, [Color? color]) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(AppUtils.formatCurrency(amount), style: TextStyle(color: color ?? AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
