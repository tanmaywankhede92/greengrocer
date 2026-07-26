import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../core/params.dart';
import '../core/print_pdf.dart';
import '../providers/customer_provider.dart';
import '../providers/statement_provider.dart';
import '../widgets/breadcrumb.dart';
import '../services/api_client.dart';
import '../widgets/loading_widget.dart';
import '../widgets/statement_pdf.dart';

class StatementScreen extends ConsumerStatefulWidget {
  final String customerId;
  const StatementScreen({super.key, required this.customerId});
  @override
  ConsumerState<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends ConsumerState<StatementScreen> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerDetailProvider(widget.customerId));
    final params = StatementParams(
      customerId: widget.customerId,
      from: AppUtils.formatDateApi(_from),
      to: AppUtils.formatDateApi(_to),
    );
    final statementAsync = ref.watch(statementProvider(params));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/customers/${widget.customerId}'),
        ),
        title: const Text('Statement'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              icon: _isDownloading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, size: 18),
              label: Text(_isDownloading ? 'Generating...' : 'Download'),
              onPressed: _isDownloading ? null : () => _downloadStatement(customerAsync.value),
            ),
          ),
        ],
      ),
      body: customerAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text(ApiClient.humanizeError(e))),
        data: (customer) {
          return Column(
            children: [
              const Breadcrumb(crumbs: [
                Crumb('Home', route: '/dashboard'),
                Crumb('Customers', route: '/customers'),
                Crumb('Statement'),
              ]),
              Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed.withAlpha(15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                AppUtils.initials(customer.name),
                                style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customer.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                                Text(customer.mobile, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                  error: (e, _) => Center(child: Text(ApiClient.humanizeError(e))),
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
                            _summaryBar(isMobile, openingBalance, totalDebit, totalCredit, closingBalance),
                            const SizedBox(height: 8),
                            Expanded(
                              child: isMobile
                                  ? _mobileGroupedList(rows, openingBalance)
                                  : _desktopTable(rows, openingBalance),
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

  Future<void> _downloadStatement(dynamic customer) async {
    setState(() => _isDownloading = true);
    try {
      final params = StatementParams(
        customerId: widget.customerId,
        from: AppUtils.formatDateApi(_from),
        to: AppUtils.formatDateApi(_to),
      );
      final data = await ref.read(statementProvider(params).future);
      final rows = data['rows'] as List<dynamic>? ?? [];
      final openingBalance = (data['openingBalance'] ?? 0).toDouble();
      final closingBalance = (data['closingBalance'] ?? 0).toDouble();
      final totalDebit = (data['totalDebit'] ?? 0).toDouble();
      final totalCredit = (data['totalCredit'] ?? 0).toDouble();

      final castRows = rows.map((r) => Map<String, dynamic>.from(r as Map)).toList();

      final pdf = await buildStatementPdf(
        customerName: customer.name,
        customerMobile: customer.mobile,
        customerAddress: customer.address,
        from: AppUtils.formatDateApi(_from),
        to: AppUtils.formatDateApi(_to),
        openingBalance: openingBalance,
        closingBalance: closingBalance,
        totalDebit: totalDebit,
        totalCredit: totalCredit,
        rows: castRows,
      );
      await printPdf(pdf, filename: 'Statement_${customer.name}_${AppUtils.formatDateShort(_from)}-${AppUtils.formatDateShort(_to)}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.humanizeError(e)), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Widget _datePickerField(String label, DateTime date, ValueChanged<DateTime> onPicked) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, isDense: true),
        child: Text(
          AppUtils.formatDate(date),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
      ),
    );
  }

  Widget _summaryBar(bool isMobile, double opening, double debit, double credit, double closing) {
    final netChange = debit - credit;
    if (isMobile) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _summaryRow('Opening Balance', opening, AppTheme.textPrimary),
              const SizedBox(height: 6),
              _summaryRow('Bills (Period)', debit, AppTheme.error),
              const SizedBox(height: 6),
              _summaryRow('Payments (Period)', credit, AppTheme.success),
              const SizedBox(height: 6),
              _summaryRow('Net Change', netChange, netChange >= 0 ? AppTheme.error : AppTheme.success),
              const Divider(height: 12),
              _summaryRow('Closing Balance', closing, closing > 0 ? AppTheme.error : AppTheme.success),
            ],
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _summaryStat('Opening Balance', opening),
            _summaryStat('Bills (Period)', debit, AppTheme.error),
            _summaryStat('Payments (Period)', credit, AppTheme.success),
            _summaryStat('Net Change', netChange, netChange >= 0 ? AppTheme.error : AppTheme.success),
            _summaryStat('Closing Balance', closing, closing > 0 ? AppTheme.error : AppTheme.success),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        Text(AppUtils.formatCurrency(amount), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _summaryStat(String label, double amount, [Color? color]) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          AppUtils.formatCurrency(amount),
          style: TextStyle(color: color ?? AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  String _extractBillNumber(String description) {
    final match = RegExp(r'([A-Za-z]+-\d{6}-\d{4})').firstMatch(description);
    return match != null ? match.group(1)! : '';
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'bill':
        return 'Bill';
      case 'payment':
        return 'Payment';
      case 'adjustment':
        return 'Adjustment';
      case 'opening_balance':
        return 'Opening';
      default:
        return 'Other';
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(List<dynamic> rows) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      final row = r as Map<String, dynamic>;
      final dateStr = row['date']?.toString() ?? '';
      final key = dateStr.isNotEmpty ? AppUtils.formatDate(DateTime.parse(dateStr)) : 'Unknown';
      map.putIfAbsent(key, () => []).add(row);
    }
    return map;
  }

  Widget _desktopTable(List<dynamic> rows, double openingBalance) {
    final grouped = _groupByDate(rows);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D3A),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white))),
              Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white))),
              Expanded(flex: 2, child: Text('Ref No.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white))),
              Expanded(flex: 2, child: Text('Debit', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white))),
              Expanded(flex: 2, child: Text('Credit', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white))),
              Expanded(flex: 2, child: Text('Balance', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (openingBalance != 0)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: const Color(0xFFF5F5F5),
            child: Row(
              children: [
                const Expanded(flex: 2, child: Text('-', style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)))),
                const Expanded(flex: 2, child: Text('Opening', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF616161)))),
                const Expanded(flex: 2, child: Text('-', style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)))),
                const Expanded(flex: 2, child: Text('-', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)))),
                const Expanded(flex: 2, child: Text('-', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)))),
                Expanded(flex: 2, child: Text(
                  AppUtils.formatCurrency(openingBalance),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                )),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final dateKey = grouped.keys.elementAt(index);
              final entries = grouped[dateKey]!;
              return _dateGroup(dateKey, entries, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _dateGroup(String dateKey, List<Map<String, dynamic>> entries, int groupIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: groupIndex == 0 ? 0 : 8, bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            dateKey,
            style: const TextStyle(
              color: AppTheme.primaryRed,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ),
        ...entries.map((r) => _desktopRow(r)),
      ],
    );
  }

  Widget _desktopRow(Map<String, dynamic> r) {
    final desc = r['description']?.toString() ?? '';
    final type = (r['type'] ?? 'other').toString();
    final debit = (r['debit'] ?? 0) as num;
    final credit = (r['credit'] ?? 0) as num;
    final balance = (r['balance'] ?? 0) as num;
    final billNo = _extractBillNumber(desc);
    final label = _typeLabel(type);
    final dateStr = r['date']?.toString() ?? '';
    final dateFormatted = dateStr.isNotEmpty ? AppUtils.formatDateShort(DateTime.parse(dateStr)) : '-';

    final isAdjustment = type == 'adjustment';
    final isPayment = type == 'payment';

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isAdjustment ? const Color(0xFFFFF3E0) : (type == 'opening_balance' ? const Color(0xFFF5F5F5) : Colors.white),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(dateFormatted, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)))),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isAdjustment ? Colors.orange.shade800 : (isPayment ? AppTheme.success : AppTheme.textPrimary),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              billNo.isNotEmpty ? billNo : '-',
              style: const TextStyle(fontSize: 12, color: Color(0xFF616161)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              debit > 0 ? AppUtils.formatCurrency(debit.toDouble()) : '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: isAdjustment ? Colors.orange.shade800 : AppTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              credit > 0 ? AppUtils.formatCurrency(credit.toDouble()) : '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: isAdjustment ? Colors.orange.shade800 : AppTheme.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              AppUtils.formatCurrency(balance.toDouble()),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileGroupedList(List<dynamic> rows, double openingBalance) {
    final grouped = _groupByDate(rows);
    final totalGroups = grouped.length + (openingBalance != 0 ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: totalGroups,
      itemBuilder: (context, index) {
        if (openingBalance != 0 && index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Opening Balance', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                Text(AppUtils.formatCurrency(openingBalance), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          );
        }

        final groupIdx = openingBalance != 0 ? index - 1 : index;
        final dateKey = grouped.keys.elementAt(groupIdx);
        final entries = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                dateKey,
                style: const TextStyle(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            ...entries.map((r) {
              final desc = r['description']?.toString() ?? '';
              final type = (r['type'] ?? 'other').toString();
              final debit = (r['debit'] ?? 0) as num;
              final credit = (r['credit'] ?? 0) as num;
              final balance = (r['balance'] ?? 0) as num;
              final billNo = _extractBillNumber(desc);
              final label = _typeLabel(type);
              final isAdjustment = type == 'adjustment';

              return Card(
                margin: const EdgeInsets.only(bottom: 4),
                color: isAdjustment ? const Color(0xFFFFF3E0) : null,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            billNo.isNotEmpty ? billNo : label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isAdjustment ? Colors.orange.shade800 : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          AppUtils.formatCurrency(balance.toDouble()),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (debit > 0)
                            Text(
                              'Bill: ${AppUtils.formatCurrency(debit.toDouble())}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.error, fontWeight: FontWeight.w500),
                            ),
                          if (debit > 0 && credit > 0) const SizedBox(width: 12),
                          if (credit > 0 && !isAdjustment)
                            Text(
                              'Paid: ${AppUtils.formatCurrency(credit.toDouble())}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w500),
                            ),
                          if (isAdjustment)
                            Text(
                              'Adjustment: ${AppUtils.formatCurrency(credit.toDouble())}',
                              style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

}
