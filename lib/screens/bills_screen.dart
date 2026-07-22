import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../core/enums.dart';
import '../core/params.dart';
import '../providers/bill_provider.dart';
import 'bills/widgets/export_bills_excel_dialog.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/breadcrumb.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});
  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  final _searchCtrl = TextEditingController();
  String? _statusFilter;
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _periodFilter;
  int _page = 1;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _setPeriod(String period) {
    final now = DateTime.now();
    setState(() {
      _periodFilter = period;
      _page = 1;
      if (period == 'today') {
        _fromDate = DateTime(now.year, now.month, now.day);
        _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (period == 'all') {
        _fromDate = null;
        _toDate = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final params = BillListParams(
      search: _searchCtrl.text.trim(),
      status: _statusFilter ?? 'all',
      page: _page,
      limit: 50,
      from: _fromDate != null ? AppUtils.formatDateApi(_fromDate!) : null,
      to: _toDate != null ? AppUtils.formatDateApi(_toDate!) : null,
    );
    final billsAsync = ref.watch(billListProvider(params));

    return Scaffold(
      appBar: AppBar(title: const Text('Bills'), actions: [
        IconButton(
          icon: const Icon(Icons.table_chart_outlined, size: 20),
          tooltip: 'Export Excel',
          onPressed: () => ExportBillsExcelDialog.show(context),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Bill'),
            onPressed: () => context.go('/bills/new'),
          ),
        ),
      ]),
      body: Column(
        children: [
          const Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Bills')]),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(hintText: 'Search by bill no. or customer name...', prefixIcon: Icon(Icons.search), isDense: true),
              onChanged: (_) => setState(() => _page = 1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _filterChip('Today', _periodFilter == 'today', () => _setPeriod('today')),
                const SizedBox(width: 8),
                _filterChip('All', _periodFilter == 'all' || _periodFilter == null, () => _setPeriod('all')),
                const Spacer(),
                _filterChip('Active', _statusFilter == 'active', () => setState(() { _statusFilter = _statusFilter == 'active' ? null : 'active'; _page = 1; })),
                const SizedBox(width: 8),
                _filterChip('Cancelled', _statusFilter == 'cancelled', () => setState(() { _statusFilter = _statusFilter == 'cancelled' ? null : 'cancelled'; _page = 1; })),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: _fromDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (picked != null) setState(() { _fromDate = picked; _periodFilter = null; _page = 1; });
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'From', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      child: Text(_fromDate != null ? AppUtils.formatDate(_fromDate!) : 'From date', style: TextStyle(color: _fromDate != null ? AppTheme.textPrimary : AppTheme.textSecondary, fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: _toDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (picked != null) setState(() { _toDate = picked; _periodFilter = null; _page = 1; });
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'To', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      child: Text(_toDate != null ? AppUtils.formatDate(_toDate!) : 'To date', style: TextStyle(color: _toDate != null ? AppTheme.textPrimary : AppTheme.textSecondary, fontSize: 13)),
                    ),
                  ),
                ),
                if (_fromDate != null || _toDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() { _fromDate = null; _toDate = null; _periodFilter = null; _page = 1; }),
                  ),
              ],
            ),
          ),
          Expanded(
            child: billsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: AppTheme.error))),
              data: (result) {
                if (result.data.isEmpty) return const EmptyState(icon: Icons.receipt_long, title: 'No bills found');
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: result.data.length,
                  itemBuilder: (context, index) {
                    final b = result.data[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: b.status == BillStatus.active ? AppTheme.success.withAlpha(20) : AppTheme.error.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(b.status == BillStatus.active ? Icons.check_circle : Icons.cancel, color: b.status == BillStatus.active ? AppTheme.success : AppTheme.error, size: 22),
                        ),
                        title: Text(b.billNumber, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                        subtitle: Text('${b.customer?.name ?? ''}  •  ${AppUtils.formatDate(b.billDate)}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(AppUtils.formatCurrency(b.total), style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                            Text(b.status == BillStatus.active ? 'Active' : 'Cancelled', style: TextStyle(color: b.status == BillStatus.active ? AppTheme.success : AppTheme.error, fontSize: 11)),
                          ],
                        ),
                        onTap: () => context.go('/bills/${b.id}'),
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

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryRed.withAlpha(15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primaryRed : AppTheme.border, width: 1),
        ),
        child: Text(label, style: TextStyle(color: selected ? AppTheme.primaryRed : AppTheme.textSecondary, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}
