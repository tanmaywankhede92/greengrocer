import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../core/params.dart';
import '../providers/customer_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/breadcrumb.dart';
import '../models/customer.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});
  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  int _page = 1;
  static const _limit = 20;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final params = CustomerListParams(search: _searchCtrl.text.trim(), page: _page, limit: _limit);
    final customersAsync = ref.watch(customerListProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add Customer'),
              onPressed: () => _showCustomerForm(context, null),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Customers')]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(hintText: 'Search by name or mobile...', prefixIcon: Icon(Icons.search)),
              onChanged: (_) => setState(() => _page = 1),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.error))),
              data: (result) {
                if (result.data.isEmpty) {
                  return const EmptyState(icon: Icons.people_outline, title: 'No customers found', subtitle: 'Add your first customer to get started');
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: result.data.length,
                        itemBuilder: (context, index) {
                          final c = result.data[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(c.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                              subtitle: Text('${c.mobile}  •  ${c.address ?? ""}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(AppUtils.formatCurrency(c.currentDue), style: TextStyle(color: c.currentDue > 0 ? AppTheme.warning : AppTheme.success, fontWeight: FontWeight.w600)),
                                      Text('${c.billCount} bills', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.textSecondary),
                                    onSelected: (v) {
                                      if (v == 'edit') {
                                        _showCustomerForm(context, {
                                          'id': c.id,
                                          'name': c.name,
                                          'mobile': c.mobile,
                                          'address': c.address ?? '',
                                          'gstNumber': c.gstNumber ?? '',
                                          'openingBalance': c.openingBalance,
                                        });
                                      } else if (v == 'delete') {
                                        _confirmDelete(context, c);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppTheme.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppTheme.error))])),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () => context.go('/customers/${c.id}'),
                            ),
                          );
                        },
                      ),
                    ),
                    if (result.meta != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(icon: const Icon(Icons.chevron_left), onPressed: _page > 1 ? () => setState(() => _page--) : null),
                            Text('Page ${result.meta!['page']} of ${result.meta!['totalPages']}', style: const TextStyle(color: AppTheme.textSecondary)),
                            IconButton(icon: const Icon(Icons.chevron_right), onPressed: result.meta!['hasNextPage'] == true ? () => setState(() => _page++) : null),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerForm(BuildContext context, Map<String, dynamic>? initial) {
    final nameCtrl = TextEditingController(text: initial?['name'] ?? '');
    final mobileCtrl = TextEditingController(text: initial?['mobile'] ?? '');
    final addrCtrl = TextEditingController(text: initial?['address'] ?? '');
    final gstCtrl = TextEditingController(text: initial?['gstNumber'] ?? '');
    final balCtrl = TextEditingController(text: initial?['openingBalance']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(initial == null ? 'Add Customer' : 'Edit Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.person_outline, size: 18))),
              const SizedBox(height: 12),
              TextField(controller: mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile *', prefixIcon: Icon(Icons.phone, size: 18)), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined, size: 18))),
              const SizedBox(height: 12),
              TextField(controller: gstCtrl, decoration: const InputDecoration(labelText: 'GST Number', prefixIcon: Icon(Icons.numbers, size: 18))),
              if (initial == null) ...[const SizedBox(height: 12), TextField(controller: balCtrl, decoration: const InputDecoration(labelText: 'Opening Balance', prefixIcon: Icon(Icons.account_balance, size: 18)), keyboardType: TextInputType.number)],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.isEmpty || mobileCtrl.text.isEmpty) return;
            if (!RegExp(r'^\d{10}$').hasMatch(mobileCtrl.text.trim())) {
              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Mobile number must be exactly 10 digits')));
              return;
            }
            final data = <String, dynamic>{'name': nameCtrl.text, 'mobile': mobileCtrl.text, 'address': addrCtrl.text, 'gstNumber': gstCtrl.text};
            if (initial == null) data['openingBalance'] = double.tryParse(balCtrl.text) ?? 0;
            try {
              if (initial == null) {
                await ref.read(customerServiceProvider).create(data);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Customer created successfully'), backgroundColor: AppTheme.success),
                  );
                }
              } else {
                await ref.read(customerServiceProvider).update(initial['id'], data);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Customer updated successfully'), backgroundColor: AppTheme.success),
                  );
                }
              }
              ref.invalidate(customerListProvider);
            } catch (e) {
              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Customer c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 40),
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete "${c.name}"?\n\nThis action cannot be undone.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await ref.read(customerServiceProvider).delete(c.id);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${c.name}" deleted successfully'), backgroundColor: AppTheme.success),
                  );
                }
                ref.invalidate(customerListProvider);
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
