import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
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
      await Printing.layoutPdf(onLayout: (_) => pdf);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bill saved & printed'), backgroundColor: AppTheme.success),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tableWidth = (screenWidth - 80).clamp(400.0, 800.0);
    const cSr = 28.0;
    const cQty = 50.0;
    const cRate = 60.0;
    const cAmt = 70.0;
    final cProd = tableWidth - cSr - cQty - cRate - cAmt;

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
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildPreview(cSr, cProd, cQty, cRate, cAmt),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surface, border: Border(top: BorderSide(color: AppTheme.border))),
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

  Widget _buildPreview(double colSr, double colProd, double colQty, double colRate, double colAmt) {
    final cellStyle = TextStyle(fontSize: 10, color: Colors.grey.shade800);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RATHOD ENTERPRISES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFD32F2F), letterSpacing: 1)),
        const SizedBox(height: 4),
        Text('Vegetable, Fruits Supplier & Commission Agent', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        Text('Green & Fresh \u2022 Every Day...', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
        const SizedBox(height: 6),
        Text('Shop No.95 Kanji House, Mahatma Phule Market, Cotton Market, Nagpur \u2013 440018',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
        Text('Nitesh : 8087344819  |  Vicky : 9529031540  |  7030914867',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        const Divider(height: 24),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BILL TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red.shade700, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(widget.customer.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade900)),
                  Text(widget.customer.mobile, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  if (widget.customer.address != null && widget.customer.address!.isNotEmpty)
                    Text(widget.customer.address!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BILL DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red.shade700, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  _infoRow('Bill No', 'Will be generated on print'),
                  const SizedBox(height: 4),
                  _infoRow('Date', AppUtils.formatDate(DateTime.now())),

                ],
              ),
            ),
          ],
        ),
        const Divider(height: 24),

        Text('PRODUCTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final isMobile = MediaQuery.of(context).size.width < 768;
            if (isMobile) {
              return Column(
                children: List.generate(_items.length, (idx) {
                  final i = _items[idx];
                  final name = i.productNameHindi.isNotEmpty ? '${i.productName} (${i.productNameHindi})' : i.productName;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('#${idx + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                            const Spacer(),
                            Text('Qty: ${i.quantity.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 6),
                          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Text('Rate: \u20B9${_fmt(i.appliedRate)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                            const Spacer(),
                            Text('Amount: \u20B9${_fmt(i.amount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red)),
                          ]),
                        ],
                      ),
                    ),
                  );
                }),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 0.5)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _headerRow(colSr, colProd, colQty, colRate, colAmt),
                      ...List.generate(_items.length, (i) => _dataRow(i, colSr, colProd, colQty, colRate, colAmt, cellStyle)),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(4)),
          child: Column(
            children: [
              _sumRow('Subtotal', _subtotal, 10, false, null),
              if (widget.deliveryCharge > 0) ...[
                const SizedBox(height: 4),
                _sumRow('Delivery Charge', widget.deliveryCharge, 10, false, null),
              ],
              const Divider(height: 16),
              _sumRow('Total', _total, 15, true, Colors.red.shade700),
              if (_paymentAmount > 0) ...[
                const SizedBox(height: 6),
                _sumRow('Paid', _paymentAmount, 11, false, Colors.green.shade700),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 55, child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade600))),
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

  Widget _dataRow(int idx, double sr, double prod, double qty, double rate, double amt, TextStyle cell) {
    final item = _items[idx];
    final isOdd = idx.isOdd;
    final isLast = idx == _items.length - 1;
    final name = item.productNameHindi.isNotEmpty ? '${item.productName} (${item.productNameHindi})' : item.productName;
    final border = isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5));

    return Container(
      decoration: BoxDecoration(color: isOdd ? const Color(0xFFF5F5F5) : Colors.white, border: border),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Row(
        children: [
          SizedBox(width: sr, child: Text('${idx + 1}', style: cell, textAlign: TextAlign.center)),
          SizedBox(width: prod, child: Text(name, style: cell, overflow: TextOverflow.ellipsis)),
          SizedBox(width: qty, child: Text(item.quantity.toStringAsFixed(0), style: cell, textAlign: TextAlign.center)),
          SizedBox(width: rate, child: Text(_fmt(item.appliedRate), style: cell, textAlign: TextAlign.right)),
          SizedBox(width: amt, child: Text(_fmt(item.amount), style: cell.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
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
