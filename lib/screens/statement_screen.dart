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
                      Text(customer.name, style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(customer.mobile, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 500;
                          if (isNarrow) {
                            return Column(
                              children: [
                                _datePickerField('From', _from, (picked) => setState(() => _from = picked)),
                                const SizedBox(height: 8),
                                _datePickerField('To', _to, (picked) => setState(() => _to = picked)),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: _datePickerField('From', _from, (picked) => setState(() => _from = picked))),
                              const SizedBox(width: 12),
                              Expanded(child: _datePickerField('To', _to, (picked) => setState(() => _to = picked))),
                            ],
                          );
                        },
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

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 768;

                        return Column(
                          children: [
                            _summaryCard(isMobile, openingBalance, totalDebit, totalCredit, closingBalance),
                            const SizedBox(height: 8),
                            Expanded(
                              child: isMobile
                                  ? _mobileEntryList(rows)
                                  : _desktopEntryTable(rows, constraints.maxWidth),
                            ),
                          ],
                        );
                      },
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

  Widget _datePickerField(String label, DateTime date, ValueChanged<DateTime> onPicked) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now());
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, isDense: true),
        child: Text(AppUtils.formatDate(date), style: TextStyle(color: AppTheme.textPrimary)),
      ),
    );
  }

  Widget _summaryCard(bool isMobile, double opening, double debit, double credit, double closing) {
    if (isMobile) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_statLabel('Opening', opening)]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_statLabel('Debit', debit, AppTheme.error)]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_statLabel('Credit', credit, AppTheme.success)]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_statLabel('Closing', closing, AppTheme.warning)]),
            ],
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('Opening', opening),
            _stat('Debit', debit, AppTheme.error),
            _stat('Credit', credit, AppTheme.success),
            _stat('Closing', closing, AppTheme.warning),
          ],
        ),
      ),
    );
  }

  Widget _mobileEntryList(List<dynamic> rows) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final r = rows[index] as Map<String, dynamic>;
        final debit = (r['debit'] ?? 0) as num;
        final credit = (r['credit'] ?? 0) as num;
        final balance = (r['balance'] as num).toDouble();
        final dateStr = AppUtils.formatDate(DateTime.parse(r['date']));

        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(r['description'] ?? '', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                    ),
                    Text(dateStr, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
                const Divider(height: 12),
                _entryDetailRow('Balance', AppUtils.formatCurrency(balance), AppTheme.textPrimary),
                if (debit > 0) _entryDetailRow('Debit', AppUtils.formatCurrency(debit.toDouble()), AppTheme.error),
                if (credit > 0) _entryDetailRow('Credit', AppUtils.formatCurrency(credit.toDouble()), AppTheme.success),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _desktopEntryTable(List<dynamic> rows, double maxWidth) {
    final descFlex = 3;
    final numFlex = 1;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          color: AppTheme.textPrimary.withOpacity(0.05),
          child: Row(
            children: [
              const Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
              Expanded(flex: numFlex, child: Text('Debit', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
              Expanded(flex: numFlex, child: Text('Credit', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
              Expanded(flex: numFlex, child: Text('Balance', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final r = rows[index] as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: descFlex,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['description'] ?? '', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                            Text(AppUtils.formatDate(DateTime.parse(r['date'])), style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      Expanded(flex: numFlex, child: Text((r['debit'] ?? 0) > 0 ? AppUtils.formatCurrency((r['debit'] as num).toDouble()) : '-', textAlign: TextAlign.right, style: TextStyle(color: AppTheme.error, fontSize: 13))),
                      Expanded(flex: numFlex, child: Text((r['credit'] ?? 0) > 0 ? AppUtils.formatCurrency((r['credit'] as num).toDouble()) : '-', textAlign: TextAlign.right, style: TextStyle(color: AppTheme.success, fontSize: 13))),
                      Expanded(flex: numFlex, child: Text(AppUtils.formatCurrency((r['balance'] as num).toDouble()), textAlign: TextAlign.right, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _entryDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _statLabel(String label, double amount, [Color? color]) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(AppUtils.formatCurrency(amount), style: TextStyle(color: color ?? AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _stat(String label, double amount, [Color? color]) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(AppUtils.formatCurrency(amount), style: TextStyle(color: color ?? AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
