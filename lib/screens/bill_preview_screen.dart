import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/print_pdf.dart';
import 'package:dio/dio.dart';
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
  final double deliveryCharge;
  final double paymentAmount;
  final PaymentMode paymentMode;

  const BillPreviewScreen({
    super.key,
    required this.customer,
    required this.items,
    this.deliveryCharge = 0,
    this.paymentAmount = 0,
    this.paymentMode = PaymentMode.cash,
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
      productNameHindi: i.productNameHindi,
      unit: i.unit,
      quantity: i.quantity,
      defaultRate: i.defaultRate,
      appliedRate: i.appliedRate,
    )).toList();
    _paymentAmount = widget.paymentAmount;
    _paymentMode = widget.paymentMode;
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.amount);
  double get _total => _subtotal + widget.deliveryCharge;

  Map<String, dynamic> _buildCreatePayload() {
    final itemsJson = _items.map((i) => i.toJson()).toList();
    return {
      'customerId': widget.customer.id,
      'billDate': AppUtils.formatDateApi(DateTime.now()),
      'items': itemsJson,
      'deliveryCharge': widget.deliveryCharge,
      'notes': '',
      'paymentAmount': _paymentAmount,
      'paymentMode': _paymentMode.value,
    };
  }

  Future<void> _print() async {
    setState(() => _isGenerating = true);
    try {
      final billService = ref.read(billServiceProvider);
      final settings = await ref.read(settingsProvider.future);

      final payload = _buildCreatePayload();
      final result = await billService.create(payload);
      final billNumber = result['billNumber'] as String;

      if (!mounted) return;
      ref.invalidate(billListProvider);

      final pdf = await buildBillPdf(
        settings: settings,
        billNumber: billNumber,
        customerName: widget.customer.name,
        customerMobile: widget.customer.mobile,
        customerAddress: widget.customer.address,
        subtotal: _subtotal,
        total: _total,
        deliveryCharge: widget.deliveryCharge,
        paidNow: _paymentAmount,
        items: _items,
        billDate: DateTime.now(),
        paymentMode: _paymentMode.displayName,
        isReprint: false,
      );
      if (!mounted) return;
      await printPdf(pdf, filename: billNumber);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill saved & printed'), backgroundColor: AppTheme.success),
        );
        context.go('/bills');
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data?['message'] ?? 'Failed to save bill. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  static const _red = Color(0xFFB71C1C);
  static const _muted = Color(0xFF757575);
  static const _line = Color(0xFFBDBDBD);
  static const _lightLine = Color(0xFFE0E0E0);

  Widget _thinLine({double thickness = 0.7}) {
    return Container(height: thickness, color: _line);
  }

  Widget _buildCopy({required bool isCustomerCopy, required double maxWidth}) {
    const copyLabel = 'ORIGINAL';
    final copySuffix = isCustomerCopy ? 'Customer Copy' : 'Office Copy';
    final now = DateTime.now();
    final grandTotal = _total > 0 ? _total : _subtotal;

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
          _thinLine(thickness: 0.7),
          const SizedBox(height: 12),

          // ── Info section (two columns with divider) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoField('Bill No.', 'Will be generated on print'),
                      const SizedBox(height: 6),
                      _infoField('Customer', widget.customer.name),
                      const SizedBox(height: 6),
                      _infoField('Mobile', widget.customer.mobile),
                      const SizedBox(height: 6),
                      _infoField('Address', widget.customer.address?.isNotEmpty == true ? widget.customer.address! : '-'),
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
                        _infoField('Date', AppUtils.formatDate(now)),
                        const SizedBox(height: 6),
                        _infoField('Time', DateFormat('hh:mm a').format(now)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _thinLine(thickness: 0.7),
          const SizedBox(height: 8),

          // ── Products table (6 columns, same as PDF) ──
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
                // Header row
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
                // Data rows
                ..._items.asMap().entries.map((entry) {
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

          // ── Summary (right-aligned, same as PDF) ──
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 220,
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _amountRow('Subtotal', _subtotal),
                  if (widget.deliveryCharge > 0)
                    _amountRow('Delivery Charge', widget.deliveryCharge),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: _line, width: 0.7), bottom: BorderSide(color: _line, width: 0.7)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('₹ ${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  if (_paymentAmount > 0) _amountRow('Paid', _paymentAmount),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),
          _thinLine(thickness: 0.7),
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

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    _buildCopy(isCustomerCopy: true, maxWidth: 700),
                    const SizedBox(height: 24),
                    _buildCopy(isCustomerCopy: false, maxWidth: 700),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppTheme.surface, border: Border(top: BorderSide(color: AppTheme.border))),
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
                    icon: _isGenerating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.print, size: 18),
                    label: Text(_isGenerating ? 'Saving & Printing...' : 'Print Both Copies'),
                    onPressed: _isGenerating ? null : () => _print(),
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
}
