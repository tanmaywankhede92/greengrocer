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
      error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: AppTheme.error))),
      data: (detail) {
        final bill = detail.bill;
        final items = detail.items;
        final isActive = bill.status == BillStatus.active;

        final screenWidth = MediaQuery.of(context).size.width;
        final tableWidth = (screenWidth - 80).clamp(400.0, 800.0);
        const cSr = 28.0;
        const cQty = 50.0;
        const cRate = 60.0;
        const cAmt = 70.0;
        final cProd = tableWidth - cSr - cQty - cRate - cAmt;
        final cellStyle = TextStyle(fontSize: 10, color: Colors.grey.shade800);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/bills')),
            title: Text(bill.billNumber),
            actions: [
              IconButton(
                icon: Icon(Icons.print, color: AppTheme.primaryRed),
                tooltip: 'Reprint',
                onPressed: () async {
                  try {
                    final settings = await ref.read(settingsProvider.future);
                    final lineItems = items.map((i) => LineItem(
                      productId: i.productId,
                      productName: i.productName,
                      productNameHindi: i.productNameHindi,
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
                      deliveryBoyPhone: bill.deliveryBoyPhone,
                      items: lineItems,
                      billDate: bill.billDate,
                      paymentMode: bill.paymentType,
                      isReprint: true,
                    );
                    await Printing.layoutPdf(onLayout: (_) => pdf);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
                    }
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
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bill cancelled'), backgroundColor: AppTheme.success));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
                        }
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.success.withAlpha(20) : AppTheme.error.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(isActive ? 'Active' : 'Cancelled', style: TextStyle(color: isActive ? AppTheme.success : AppTheme.error, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CUSTOMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red.shade700, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Text(bill.customer?.name ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade900)),
                        Text(bill.customer?.mobile ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        if (bill.customer?.address != null && bill.customer!.address!.isNotEmpty)
                          Text(bill.customer!.address!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _infoRow('Bill No', bill.billNumber),
                            ),
                            Expanded(
                              child: _infoRow('Date', AppUtils.formatDate(bill.billDate)),
                            ),
                          ],
                        ),
                        if (bill.deliveryBoyName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _infoRow('Delivery', '${bill.deliveryBoyName}${bill.deliveryBoyPhone.isNotEmpty ? ' (${bill.deliveryBoyPhone})' : ''}'),
                        ],
                        if (bill.paymentType != null && bill.paymentType!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _infoRow('Payment', bill.paymentType!),
                        ],
                        const Divider(height: 24),

                        Text('PRODUCTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 0.5)),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              _headerRow(cSr, cProd, cQty, cRate, cAmt),
                              ...List.generate(items.length, (idx) {
                                final i = items[idx];
                                final isOdd = idx.isOdd;
                                final isLast = idx == items.length - 1;
                                final name = i.productNameHindi.isNotEmpty ? '${i.productName} (${i.productNameHindi})' : i.productName;
                                final border = isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5));
                                return Container(
                                  decoration: BoxDecoration(color: isOdd ? const Color(0xFFF5F5F5) : Colors.white, border: border),
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                  child: Row(
                                    children: [
                                      SizedBox(width: cSr, child: Text('${idx + 1}', style: cellStyle, textAlign: TextAlign.center)),
                                      SizedBox(width: cProd, child: Text(name, style: cellStyle, overflow: TextOverflow.ellipsis)),
                                      SizedBox(width: cQty, child: Text(i.quantity.toStringAsFixed(0), style: cellStyle, textAlign: TextAlign.center)),
                                      SizedBox(width: cRate, child: Text(_fmt(i.appliedRate), style: cellStyle, textAlign: TextAlign.right)),
                                      SizedBox(width: cAmt, child: Text(_fmt(i.amount), style: cellStyle.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(4)),
                          child: Column(
                            children: [
                              _sumRow('Subtotal', bill.subtotal, 10, false, null),
                              const SizedBox(height: 4),
                              _sumRow('Previous Due', bill.customer?.currentDue ?? 0, 10, false, Colors.orange.shade700),
                              const Divider(height: 16),
                              _sumRow('Grand Total', bill.subtotal + (bill.customer?.currentDue ?? 0), 15, true, Colors.red.shade700),
                              const SizedBox(height: 6),
                              _sumRow('Paid', bill.paidNow, 11, false, Colors.green.shade700),
                              const Divider(height: 16),
                              _sumRow('Remaining Due', bill.newDue, 13, true, bill.newDue > 0 ? Colors.red.shade700 : Colors.green.shade700),
                            ],
                          ),
                        ),
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

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 65, child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade600))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 10, color: Colors.grey.shade800))),
      ],
    );
  }

  Widget _headerRow(double sr, double prod, double qty, double rate, double amt) {
    return Container(
      color: const Color(0xFF37474F),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Row(
        children: [
          SizedBox(width: sr, child: const Text('#', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center)),
          SizedBox(width: prod, child: const Text('Product', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white))),
          SizedBox(width: qty, child: const Text('Qty', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center)),
          SizedBox(width: rate, child: const Text('Rate', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center)),
          SizedBox(width: amt, child: const Text('Amount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _sumRow(String label, double amount, double fontSize, bool bold, Color? color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.normal, fontSize: fontSize.clamp(10, 16), color: Colors.grey.shade700)),
        Text('\u20B9 ${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize.clamp(10, 16), color: color ?? Colors.grey.shade900)),
      ],
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0);
}
