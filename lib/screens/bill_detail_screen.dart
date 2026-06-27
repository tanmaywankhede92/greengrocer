import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../core/enums.dart';
import '../providers/bill_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/breadcrumb.dart';
import '../widgets/bill_item_row.dart';
import '../widgets/bill_pdf.dart';

class BillDetailScreen extends ConsumerWidget {
  final String id;
  const BillDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(billDetailProvider(id));
    return detailAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.error))),
      data: (detail) {
        final bill = detail.bill;
        final items = detail.items;
        final isActive = bill.status == BillStatus.active;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/bills')),
            title: Text(bill.billNumber),
            actions: [
              IconButton(
                icon: const Icon(Icons.print, color: AppTheme.primaryGreenLight),
                tooltip: 'Reprint',
                onPressed: () async {
                  try {
                    final settings = await ref.read(settingsProvider.future);
                    final lineItems = items.map((i) => LineItem(
                      productId: i.productId,
                      productName: i.productName,
                      unit: i.unit,
                      quantity: i.quantity,
                      appliedRate: i.appliedRate,
                    )).toList();
                    final pdf = await buildBillPdf(
                      settings: settings,
                      billNumber: bill.billNumber,
                      customerName: bill.customer?.name ?? '',
                      customerMobile: bill.customer?.mobile ?? '',
                      customerAddress: bill.customer?.address,
                      subtotal: bill.subtotal,
                      total: bill.total,
                      previousDue: 0,
                      paidNow: bill.paidNow,
                      newDue: bill.newDue,
                      deliveryBoyName: bill.deliveryBoyName,
                      items: lineItems,
                      billDate: bill.billDate,
                      paymentMode: bill.paymentType,
                      isReprint: true,
                    );
                    await Printing.layoutPdf(onLayout: (_) => pdf);
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
                  }
                },
              ),
              if (isActive)
                TextButton.icon(
                  icon: const Icon(Icons.cancel_outlined, color: AppTheme.error),
                  label: const Text('Cancel', style: TextStyle(color: AppTheme.error)),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cancel Bill'),
                        content: Text('Cancel ${bill.billNumber}? This will reverse the ledger entries.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel'), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error)),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await ref.read(billServiceProvider).cancel(id);
                        ref.invalidate(billDetailProvider(id));
                        ref.invalidate(billListProvider);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill cancelled'), backgroundColor: AppTheme.success));
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
                      }
                    }
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Bills', route: '/bills'), Crumb('Bill Detail')]),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bill.billNumber, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(AppUtils.formatDate(bill.billDate), style: const TextStyle(color: AppTheme.textSecondary)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive ? AppTheme.success.withAlpha(30) : AppTheme.error.withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(isActive ? 'Active' : 'Cancelled', style: TextStyle(color: isActive ? AppTheme.success : AppTheme.error, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(bill.customer?.name ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                        Text(bill.customer?.mobile ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Items', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text(item.productName, style: const TextStyle(color: AppTheme.textPrimary))),
                            SizedBox(width: 40, child: Text('${item.quantity.toStringAsFixed(0)} ${item.unit}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                            SizedBox(width: 60, child: Text(AppUtils.formatCurrency(item.appliedRate), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), textAlign: TextAlign.right)),
                            SizedBox(width: 80, child: Text(AppUtils.formatCurrency(item.amount), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _row('Subtotal', bill.subtotal),
                        const SizedBox(height: 8),
                        _summaryRow('Delivery Boy', bill.deliveryBoyName.isNotEmpty ? bill.deliveryBoyName : '-'),
                        const Divider(height: 20),
                        _row('Total', bill.total, bold: true),
                        const SizedBox(height: 8),
                        _row('Paid Now', bill.paidNow, color: AppTheme.success),
                        const SizedBox(height: 8),
                        _row('New Due', bill.newDue, color: AppTheme.warning),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _row(String label, double amount, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
        Text(AppUtils.formatCurrency(amount), style: TextStyle(color: color ?? AppTheme.textPrimary, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 18 : 14)),
      ],
    );
  }
}
