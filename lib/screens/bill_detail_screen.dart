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
import '../models/bill_adjustment.dart';
import '../providers/bill_provider.dart';
import '../services/api_client.dart';
import '../providers/settings_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/breadcrumb.dart';
import '../widgets/bill_pdf.dart';
import '../widgets/bill_item_row.dart';

class BillDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const BillDetailScreen({super.key, required this.id});
  @override
  ConsumerState<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends ConsumerState<BillDetailScreen> {
  static const _red = Color(0xFFB71C1C);
  static const _muted = Color(0xFF757575);
  static const _line = Color(0xFFBDBDBD);
  static const _lightLine = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(billDetailProvider(widget.id));

    return detailAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(
        child: Text(ApiClient.humanizeError(e), style: const TextStyle(color: AppTheme.error)),
      ),
      data: (detail) {
        final bill = detail.bill;
        final items = detail.items;
        final adjustments = detail.adjustments;
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
                    onPressed: () => _cancelBill(bill),
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
                          adjustments: adjustments,
                          isActive: isActive,
                        ),
                        const SizedBox(height: 24),
                        _buildCopy(
                          isCustomerCopy: false,
                          maxWidth: 700,
                          bill: bill,
                          items: items,
                          adjustments: adjustments,
                          isActive: isActive,
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
                        onPressed: () => _reprint(bill, items, adjustments),
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

  double _currentQuantity(BillItem item, List<BillAdjustment> adjustments) {
    final itemAdj = adjustments.where((a) => a.billItemId == item.id).toList();
    if (itemAdj.isEmpty) return item.quantity;
    itemAdj.sort((a, b) => a.adjustmentDate.compareTo(b.adjustmentDate));
    return itemAdj.last.adjustedQuantity ?? item.quantity;
  }

  double _currentAmount(BillItem item, List<BillAdjustment> adjustments) {
    return _currentQuantity(item, adjustments) * item.appliedRate;
  }

  Future<void> _adjustProduct(BillItem item, List<BillAdjustment> adjustments, Bill bill) async {
    final currentQty = _currentQuantity(item, adjustments);
    final qtyCtrl = TextEditingController(text: currentQty.toStringAsFixed(currentQty == currentQty.roundToDouble() ? 0 : 1));
    final noteCtrl = TextEditingController();
    String reason = 'damaged';
    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Adjust ${item.productName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Quantity: ${currentQty.toStringAsFixed(currentQty == currentQty.roundToDouble() ? 0 : 1)} ${item.unit}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                Text(
                  'Rate: ₹${item.appliedRate.toStringAsFixed(0)} / ${item.unit}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'New Quantity (${item.unit})',
                    hintText: 'Max: ${currentQty.toStringAsFixed(0)}',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  decoration: const InputDecoration(labelText: 'Reason (optional)', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                    DropdownMenuItem(value: 'missing', child: Text('Missing')),
                    DropdownMenuItem(value: 'short_supply', child: Text('Short Supply')),
                    DropdownMenuItem(value: 'rate_diff', child: Text('Rate Difference')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setDialogState(() => reason = v ?? reason),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'e.g., 5 kg were rotten',
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving ? null : () async {
                final newQty = double.tryParse(qtyCtrl.text.trim());
                if (newQty == null || newQty < 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Enter a valid quantity'), backgroundColor: AppTheme.error),
                  );
                  return;
                }
                if (newQty > currentQty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('New quantity cannot exceed current (${currentQty.toStringAsFixed(0)})'), backgroundColor: AppTheme.error),
                  );
                  return;
                }
                if (newQty == currentQty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Quantity unchanged'), backgroundColor: AppTheme.error),
                  );
                  return;
                }
                setDialogState(() => saving = true);
                try {
                  await ref.read(billServiceProvider).adjust(
                    bill.id,
                    items: [{
                      'billItemId': item.id,
                      'adjustedQuantity': newQty,
                      'reason': reason,
                      'note': noteCtrl.text.trim(),
                    }],
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  setDialogState(() => saving = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(ApiClient.humanizeError(e)), backgroundColor: AppTheme.error),
                    );
                  }
                }
              },
              child: saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      ref.invalidate(billDetailProvider(widget.id));
      ref.invalidate(billListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product adjusted'), backgroundColor: AppTheme.success),
      );
    }
  }

  Future<void> _cancelBill(Bill bill) async {
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
        ref.invalidate(billDetailProvider(widget.id));
        ref.invalidate(billListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bill cancelled'), backgroundColor: AppTheme.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.humanizeError(e)), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _reprint(Bill bill, List<BillItem> items, List<BillAdjustment> adjustments) async {
    try {
      final settings = await ref.read(settingsProvider.future);
      final lineItems = items.map((i) {
        final curQty = _currentQuantity(i, adjustments);
        final itemAdj = adjustments.where((a) => a.billItemId == i.id).toList();
        final reason = itemAdj.isNotEmpty ? itemAdj.last.reasonLabel : null;
        return LineItem(
          productId: i.productId,
          productName: i.productName,
          productNameHindi: i.productNameHindi,
          unit: i.unit,
          quantity: i.quantity,
          defaultRate: i.defaultRate,
          appliedRate: i.appliedRate,
          adjustedQuantity: curQty != i.quantity ? curQty : null,
          adjustmentReason: reason,
        );
      }).toList();
      final totalAdjusted = adjustments.fold<double>(0, (sum, a) => sum + a.amount);
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
        adjustmentAmount: totalAdjusted,
        adjustmentNote: adjustments.map((a) => '${a.reasonLabel}: ${a.note}'.trim()).join(', '),
      );
      await printPdf(pdf, filename: bill.billNumber);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Widget _buildCopy({
    required bool isCustomerCopy,
    required double maxWidth,
    required Bill bill,
    required List<BillItem> items,
    required List<BillAdjustment> adjustments,
    bool isActive = false,
  }) {
    const copyLabel = 'ORIGINAL';
    final copySuffix = isCustomerCopy ? 'Customer Copy' : 'Office Copy';
    final billDate = bill.billDate;
    final grandTotal = bill.total > 0 ? bill.total : bill.subtotal;
    final totalAdjusted = adjustments.fold<double>(0, (sum, a) => sum + a.amount);
    final adjustedTotal = grandTotal - totalAdjusted;

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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Table(
              columnWidths: {
                0: const FlexColumnWidth(0.55),
                1: const FlexColumnWidth(2.25),
                2: const FlexColumnWidth(0.85),
                3: const FlexColumnWidth(0.85),
                4: const FlexColumnWidth(1.0),
                5: const FlexColumnWidth(1.15),
                if (isActive) 6: const FlexColumnWidth(0.6),
              },
              border: TableBorder.all(color: _line, width: 0.7),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                  children: [
                    'Sr.', 'Product', 'Unit', 'Qty', 'Rate (₹)', 'Amount (₹)',
                    if (isActive) '',
                  ].map((h) {
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

                  final itemAdj = adjustments.where((a) => a.billItemId == item.id).toList();
                  final isAdjusted = itemAdj.isNotEmpty;
                  final curQty = _currentQuantity(item, adjustments);
                  final curAmt = _currentAmount(item, adjustments);
                  final qtyStr = curQty.toStringAsFixed(curQty == curQty.roundToDouble() ? 0 : 1);
                  final origQtyStr = item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1);

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Text('${idx + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(productName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                            if (isAdjusted) ...[
                              const SizedBox(height: 2),
                              Text(
                                '$origQtyStr → $qtyStr (${itemAdj.last.reasonLabel})',
                                style: TextStyle(fontSize: 8.5, color: Colors.orange.shade800, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Text(item.unit, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Text(qtyStr, textAlign: TextAlign.center, style: TextStyle(
                          fontSize: 10,
                          fontWeight: isAdjusted ? FontWeight.w700 : FontWeight.w400,
                          color: isAdjusted ? Colors.orange.shade800 : null,
                        )),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Text(item.appliedRate.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Text(curAmt.toStringAsFixed(2), textAlign: TextAlign.right, style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isAdjusted ? Colors.orange.shade800 : null,
                        )),
                      ),
                      if (isActive)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: Center(
                            child: GestureDetector(
                              onTap: () => _adjustProduct(item, adjustments, bill),
                              child: Icon(Icons.edit_note, size: 16, color: AppTheme.primaryRed),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

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
                  _amountRow('Grand Total', grandTotal),
                  if (totalAdjusted > 0) ...[
                    _amountRow('Total Adjustment', -totalAdjusted, isAdjustment: true),
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
                          const Text('Final Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryRed)),
                          Text('₹ ${adjustedTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryRed)),
                        ],
                      ),
                    ),
                  ] else
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
                  if (totalAdjusted > 0 && bill.paidNow > 0)
                    _amountRow('Balance Due', adjustedTotal - bill.paidNow, isBold: true),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),
          _thinLine(),
          const SizedBox(height: 10),

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

  Widget _amountRow(String label, double value, {bool isAdjustment = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: isBold ? 12 : 11,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isAdjustment ? Colors.orange.shade800 : AppTheme.textPrimary,
          )),
          Text(
            '₹ ${value.abs().toStringAsFixed(0)}${isAdjustment ? '' : ''}',
            style: TextStyle(
              fontSize: isBold ? 12 : 11,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: isAdjustment ? Colors.orange.shade800 : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
