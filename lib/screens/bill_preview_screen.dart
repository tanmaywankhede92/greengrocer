import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../models/customer.dart';
import '../core/enums.dart';
import '../providers/bill_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/breadcrumb.dart';
import '../widgets/bill_item_row.dart';
import '../widgets/bill_pdf.dart';

class BillPreviewScreen extends ConsumerStatefulWidget {
  final Customer customer;
  final List<LineItem> items;
  final String deliveryBoyName;
  final double paymentAmount;
  final PaymentMode paymentMode;

  const BillPreviewScreen({
    super.key,
    required this.customer,
    required this.items,
    required this.deliveryBoyName,
    required this.paymentAmount,
    required this.paymentMode,
  });

  @override
  ConsumerState<BillPreviewScreen> createState() => _BillPreviewScreenState();
}

class _BillPreviewScreenState extends ConsumerState<BillPreviewScreen> {
  late List<LineItem> _items;
  late double _paymentAmount;
  late PaymentMode _paymentMode;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _items = widget.items.map((i) => LineItem(
      productId: i.productId,
      productName: i.productName,
      unit: i.unit,
      quantity: i.quantity,
      defaultRate: i.defaultRate,
      appliedRate: i.appliedRate,
    )).toList();
    _paymentAmount = widget.paymentAmount;
    _paymentMode = widget.paymentMode;
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.amount);
  double get _total => _subtotal;
  double get _newDue => (widget.customer.currentDue) + _total - _paymentAmount;

  Future<void> _print() async {
    setState(() => _isGenerating = true);
    try {
      final billService = ref.read(billServiceProvider);
      final settings = await ref.read(settingsProvider.future);
      final id = await billService.create({
        'customerId': widget.customer.id,
        'billDate': AppUtils.formatDateApi(DateTime.now()),
        'items': _items.map((i) => i.toJson()).toList(),
        'deliveryBoyName': widget.deliveryBoyName,
        'notes': '',
        'paymentAmount': _paymentAmount,
        'paymentMode': _paymentMode.value,
      });
      if (!mounted) return;
      ref.invalidate(billListProvider);
      final pdf = await buildBillPdf(
        settings: settings,
        billNumber: id,
        customerName: widget.customer.name,
        customerMobile: widget.customer.mobile,
        customerAddress: widget.customer.address,
        subtotal: _subtotal,
        total: _total,
        previousDue: widget.customer.currentDue,
        paidNow: _paymentAmount,
        newDue: _newDue,
        deliveryBoyName: widget.deliveryBoyName,
        items: _items,
        billDate: DateTime.now(),
        paymentMode: _paymentMode.displayName,
        isReprint: false,
      );
      if (!mounted) return;
      await Printing.layoutPdf(onLayout: (_) => pdf);
      if (mounted) context.go('/bills/$id');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Bill Preview'),
      ),
      body: Column(
        children: [
          const Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Bills', route: '/bills'), Crumb('Preview')]),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  settingsAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (settings) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(settings.businessName.toUpperCase(), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                      if (settings.tagline != null && settings.tagline!.isNotEmpty)
                                        Text(settings.tagline!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                                      const SizedBox(height: 4),
                                      if (settings.address != null && settings.address!.isNotEmpty)
                                        Text(settings.address!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                      if (settings.phone != null && settings.phone!.isNotEmpty)
                                        Text('Phone: ${settings.phone}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                      if (settings.gstNumber != null && settings.gstNumber!.isNotEmpty)
                                        Text('GST: ${settings.gstNumber}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(AppUtils.formatDate(DateTime.now()), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Delivery Boy: ${widget.deliveryBoyName.isNotEmpty ? widget.deliveryBoyName : '-'}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text('Payment: ${_paymentMode.displayName}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade600), borderRadius: BorderRadius.circular(4)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Bill To:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                                      const SizedBox(height: 4),
                                      Text(widget.customer.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                                      Text(widget.customer.mobile, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                      if (widget.customer.address != null && widget.customer.address!.isNotEmpty)
                                        Text(widget.customer.address!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Table(
                              columnWidths: const {0: FlexColumnWidth(0.6), 1: FlexColumnWidth(2.8), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1.2), 4: FlexColumnWidth(1.4)},
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(color: AppTheme.surfaceNav),
                                  children: ['#', 'Item', 'Qty', 'Rate', 'Amount'].map((h) => Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(h, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                                  )).toList(),
                                ),
                                ..._items.asMap().entries.map((e) {
                                  final i = e.value;
                                  return TableRow(
                                    children: [
                                      Padding(padding: const EdgeInsets.all(8), child: Text('${e.key + 1}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
                                      Padding(padding: const EdgeInsets.all(8), child: Text(i.productName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
                                      Padding(padding: const EdgeInsets.all(8), child: Text('${i.quantity.toStringAsFixed(0)} ${i.unit}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                                      Padding(padding: const EdgeInsets.all(8), child: Text(AppUtils.formatCurrency(i.appliedRate), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12), textAlign: TextAlign.right)),
                                      Padding(padding: const EdgeInsets.all(8), child: Text(AppUtils.formatCurrency(i.amount), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                                    ],
                                  );
                                }),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 280,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade600), borderRadius: BorderRadius.circular(4)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _row('Subtotal', _subtotal),
                                      const Divider(height: 12),
                                      _row('Total', _total, bold: true, fontSize: 16),
                                      const SizedBox(height: 4),
                                      _row('Previous Due', widget.customer.currentDue, color: AppTheme.warning),
                                      const Divider(height: 12),
                                      _row('Paid', _paymentAmount, color: AppTheme.success),
                                      const SizedBox(height: 4),
                                      _row('New Due', _newDue, bold: true, fontSize: 15, color: _newDue > 0 ? AppTheme.error : AppTheme.success),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(settings.footerNote ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Authorised Signature', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                                    SizedBox(height: 20),
                                    Text('_________________________', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surfaceCard, border: Border(top: BorderSide(color: Colors.grey.shade800))),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: Icon(_isGenerating ? Icons.hourglass_top : Icons.print, size: 18),
                    label: Text(_isGenerating ? 'Generating...' : 'Print Both Copies'),
                    onPressed: _isGenerating ? null : _print,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double amount, {bool bold = false, double fontSize = 13, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: fontSize, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
          Text(AppUtils.formatCurrency(amount), style: TextStyle(color: color ?? AppTheme.textPrimary, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }
}
