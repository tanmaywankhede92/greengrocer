import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/print_pdf.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../core/enums.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../providers/bill_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/breadcrumb.dart';
import '../widgets/bill_pdf.dart';
import '../widgets/bill_item_row.dart';

class BillDetailScreen extends ConsumerWidget {
  final String id;
  const BillDetailScreen({super.key, required this.id});

  static const _red = Color(0xFFB71C1C);
  static const _muted = Color(0xFF757575);
  static const _line = Color(0xFFBDBDBD);
  static const _lightLine = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(billDetailProvider(id));

    return detailAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(
        child: Text('Error: $e', style: const TextStyle(color: AppTheme.error)),
      ),
      data: (detail) {
        final bill = detail.bill;
        final items = detail.items;
        final isActive = bill.status == BillStatus.active;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/bills'),
            ),
            title: Text(bill.billNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
            actions: [
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: TextButton.icon(
                    icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                    label: const Text('Cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                    onPressed: () => _cancelBill(context, ref, bill),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              const Breadcrumb(crumbs: [
                Crumb('Home', route: '/dashboard'),
                Crumb('Bills', route: '/bills'),
                Crumb('Bill Detail'),
              ]),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        if (isActive)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.success.withAlpha(60)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.success),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Active',
                                  style: TextStyle(
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w600, fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.error.withAlpha(60)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.error),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Cancelled',
                                  style: TextStyle(
                                    color: AppTheme.error,
                                    fontWeight: FontWeight.w600, fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _buildCopy(
                          isCustomerCopy: true,
                          maxWidth: 700,
                          bill: bill,
                          items: items,
                        ),
                        const SizedBox(height: 24),
                        _buildCopy(
                          isCustomerCopy: false,
                          maxWidth: 700,
                          bill: bill,
                          items: items,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(top: BorderSide(color: AppTheme.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Back to Bills'),
                        onPressed: () => context.go('/bills'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Print Both Copies'),
                        onPressed: () => _reprint(context, ref, bill, items),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelBill(BuildContext context, WidgetRef ref, Bill bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Bill'),
        content: Text('Cancel ${bill.billNumber}? This will reverse the ledger entries.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(billServiceProvider).cancel(bill.id);
        ref.invalidate(billDetailProvider(bill.id));
        ref.invalidate(billListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bill cancelled'), backgroundColor: AppTheme.success),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _reprint(
    BuildContext context,
    WidgetRef ref,
    Bill bill,
    List<BillItem> items,
  ) async {
    try {
      final settings = await ref.read(settingsProvider.future);
      final lineItems = items.map((i) => LineItem(
        productId: i.productId,
        productName: i.productName,
        productNameHindi: i.productNameHindi,
        unit: i.unit,
        quantity: i.quantity,
        defaultRate: i.defaultRate,
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
        deliveryCharge: bill.deliveryCharge,
        paidNow: bill.paidNow,
        items: lineItems,
        billDate: bill.billDate,
        paymentMode: bill.paymentType,
        isReprint: true,
      );
      await printPdf(pdf, filename: bill.billNumber);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  // ── Receipt copy builder (exact same layout as preview) ──

  Widget _buildCopy({
    required bool isCustomerCopy,
    required double maxWidth,
    required Bill bill,
    required List<BillItem> items,
  }) {
    const copyLabel = 'ORIGINAL';
    final copySuffix = isCustomerCopy ? 'Customer Copy' : 'Office Copy';
    final billDate = bill.billDate;
    final grandTotal = bill.total > 0 ? bill.total : bill.subtotal;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _lightLine, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 3, color: _red),
          const SizedBox(height: 12),

          // ── Header (centered) ──
          const Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('RATHOD ENTERPRISES',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _red, letterSpacing: 1)),
                SizedBox(height: 4),
                Text('Vegetable, Fruits Supplier & Commission Agent',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted)),
                SizedBox(height: 2),
                Text('Green & Fresh  •  Every Day',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppTheme.success, fontStyle: FontStyle.italic)),
                SizedBox(height: 6),
                Text('Shop No.95 Kanji House, Mahatma Phule Market,',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: _muted)),
                Text('Cotton Market, Nagpur – 440018',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: _muted)),
                SizedBox(height: 4),
                Text('Nitesh : 8087344819   |   Vicky : 9529031540   |   7030914867',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9.5, color: AppTheme.textPrimary)),
              ],
            ),
          ),

          const SizedBox(height: 14),
          _thinLine(),
          const SizedBox(height: 12),

          // ── Info section ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoField('Bill No.', bill.billNumber),
                      const SizedBox(height: 6),
                      _infoField('Customer', bill.customer?.name ?? '-'),
                      const SizedBox(height: 6),
                      _infoField('Mobile', bill.customer?.mobile ?? '-'),
                      const SizedBox(height: 6),
                      _infoField('Address', bill.customer?.address?.isNotEmpty == true ? bill.customer!.address! : '-'),
                    ],
                  ),
                ),
                Container(width: 1, height: 80, color: _line),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoField('Date', AppUtils.formatDate(billDate)),
                        const SizedBox(height: 6),
                        _infoField('Time', DateFormat('hh:mm a').format(billDate)),
                        if (bill.paymentType != null && bill.paymentType!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _infoField('Payment', bill.paymentType!),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _thinLine(),
          const SizedBox(height: 8),

          // ── Products table ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(0.55),
                1: FlexColumnWidth(2.25),
                2: FlexColumnWidth(1.0),
                3: FlexColumnWidth(0.85),
                4: FlexColumnWidth(1.0),
                5: FlexColumnWidth(1.15),
              },
              border: TableBorder.all(color: _line, width: 0.7),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                  children: ['Sr.', 'Product', 'Unit', 'Qty', 'Rate (₹)', 'Amount (₹)'].map((h) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      child: Text(h,
                          textAlign: h == 'Product' ? TextAlign.left : TextAlign.center,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    );
                  }).toList(),
                ),
                ...items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final productName = item.productNameHindi.isNotEmpty
                      ? '${item.productName} (${item.productNameHindi})'
                      : item.productName;

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Text('${idx + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Text(productName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Text(item.unit, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Text(item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Text(item.appliedRate.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Text(item.amount.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Summary (right-aligned) ──
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 220,
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _amountRow('Subtotal', bill.subtotal),
                  if (bill.deliveryCharge > 0)
                    _amountRow('Delivery Charge', bill.deliveryCharge),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: _line, width: 0.7),
                        bottom: BorderSide(color: _line, width: 0.7),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('₹ ${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  if (bill.paidNow > 0) _amountRow('Paid', bill.paidNow),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),
          _thinLine(),
          const SizedBox(height: 10),

          // ── Footer ──
          Center(
            child: Column(
              children: [
                const Text('Thank You!  Visit Again',
                    style: TextStyle(fontSize: 11, color: _muted)),
                const SizedBox(height: 4),
                const Text('RATHOD ENTERPRISES',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _red, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Container(height: 1, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('$copyLabel – $copySuffix',
                    style: const TextStyle(fontSize: 10, color: _muted)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Helpers ──

  Widget _thinLine() => Container(height: 0.7, color: _line);

  Widget _infoField(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ),
        const Text(':  ', style: TextStyle(fontSize: 10.5)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 10.5, color: AppTheme.textPrimary))),
      ],
    );
  }

  Widget _amountRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
          Text('₹ ${value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
