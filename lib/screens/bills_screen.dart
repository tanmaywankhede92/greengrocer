import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../core/enums.dart';
import '../core/params.dart';
import '../providers/bill_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state.dart';

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
  int _page = 1;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final params = BillListParams(
      search: _searchCtrl.text,
      status: _statusFilter ?? 'all',
      page: _page,
      limit: 50,
      from: _fromDate != null ? AppUtils.formatDateApi(_fromDate!) : null,
      to: _toDate != null ? AppUtils.formatDateApi(_toDate!) : null,
    );
    final billsAsync = ref.watch(billListProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.go('/bills/new')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(hintText: 'Search bill number...', prefixIcon: Icon(Icons.search), isDense: true),
                    onChanged: (_) => setState(() => _page = 1),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _statusFilter,
                  hint: const Text('Status', style: TextStyle(color: AppTheme.textSecondary)),
                  dropdownColor: AppTheme.surfaceCard,
                  items: [
                    DropdownMenuItem(value: null, child: Text('All', style: TextStyle(color: AppTheme.textPrimary))),
                    DropdownMenuItem(value: 'active', child: Text('Active', style: TextStyle(color: AppTheme.success))),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled', style: TextStyle(color: AppTheme.error))),
                  ],
                  onChanged: (v) => setState(() { _statusFilter = v; _page = 1; }),
                ),
              ],
            ),
          ),
          Expanded(
            child: billsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.error))),
              data: (result) {
                if (result.data.isEmpty) return const EmptyState(icon: Icons.receipt_long, title: 'No bills found');
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: result.data.length,
                  itemBuilder: (context, index) {
                    final b = result.data[index];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: b.status == BillStatus.active ? AppTheme.success.withAlpha(40) : AppTheme.error.withAlpha(40),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(b.status == BillStatus.active ? Icons.check_circle : Icons.cancel, color: b.status == BillStatus.active ? AppTheme.success : AppTheme.error, size: 22),
                        ),
                        title: Text(b.billNumber, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                        subtitle: Text('${b.customer?.name ?? ''}  •  ${AppUtils.formatDate(b.billDate)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(AppUtils.formatCurrency(b.total), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
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
}
