import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/print_pdf.dart';
import '../core/share_pdf.dart';
import 'package:dio/dio.dart';
import '../config/theme.dart';
import '../services/api_client.dart';
import '../core/utils.dart';
import '../models/customer.dart';
import '../core/enums.dart';
import '../providers/bill_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/breadcrumb.dart';
import '../widgets/bill_item_row.dart';
import '../widgets/bill_pdf.dart';
import '../widgets/bill_stamp.dart';

class BillPreviewScreen extends ConsumerStatefulWidget {
  final Customer customer;
  final List<LineItem> items;
  final double deliveryCharge;
  final double paymentAmount;
  final PaymentMode paymentMode;
  final String? draftId;
  final DateTime? billDate;

  const BillPreviewScreen({
    super.key,
    required this.customer,
    required this.items,
    this.deliveryCharge = 0,
    this.paymentAmount = 0,
    this.paymentMode = PaymentMode.cash,
    this.draftId,
    this.billDate,
  });

  @override
  ConsumerState<BillPreviewScreen> createState() => _BillPreviewScreenState();
}

class _BillPreviewScreenState extends ConsumerState<BillPreviewScreen> {
  final _customerCopyKey = GlobalKey();
  final _officeCopyKey = GlobalKey();
  late List<LineItem> _items;
  late double _paymentAmount;
  late PaymentMode _paymentMode;
  late DateTime _billDate;
  /// Non-null while the bill is being saved, shared or printed. Doubles as a
  /// lock so the action cannot be started twice.
  String? _busyStage;
  String? _billNumber;

  @override
  void initState() {
    super.initState();
    _billDate = widget.billDate ?? DateTime.now();
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
    precacheStamp(context);
    BillPdfFonts.preload();
  }

  Future<void> _pickBillDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _billDate,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Select Bill Date',
      confirmText: 'SELECT',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryRed,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _billDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          now.hour,
          now.minute,
          now.second,
        );
      });
    }
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.amount);
  double get _total => _subtotal + widget.deliveryCharge;

  Map<String, dynamic> _buildCreatePayload() {
    final itemsJson = _items.map((i) => i.toJson()).toList();
    return {
      'customerId': widget.customer.id,
      'billDate': AppUtils.formatDateApi(_billDate),
      'items': itemsJson,
      'deliveryCharge': widget.deliveryCharge,
      'notes': '',
      'paymentAmount': _paymentAmount,
      'paymentMode': _paymentMode.value,
      if (widget.draftId != null && widget.draftId!.isNotEmpty) 'draftId': widget.draftId,
    };
  }

  /// Runs a save/print action behind the blocking overlay and reports failures
  /// to the user. Ignored while another action is already running.
  Future<void> _runBusy(Future<void> Function() action, {required String stage}) async {
    if (_busyStage != null) return;
    setState(() => _busyStage = stage);
    try {
      await action();
    } on DioException catch (e) {
      _showError(e.response?.data?['message'] ?? 'Failed to save bill. Please try again.');
    } catch (e) {
      _showError(ApiClient.humanizeError(e));
    } finally {
      if (mounted) setState(() => _busyStage = null);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  Future<void> _print() => _runBusy(() async {
        final billNumber = await _ensureBillSaved();
        if (!mounted) return;
        final pdf = await _buildPdf(billNumber);
        await printPdf(pdf, filename: billNumber);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill saved & printed'), backgroundColor: AppTheme.success),
        );
        context.go('/bills');
      }, stage: 'Printing bill...');

  Future<void> _share() => _runBusy(() async {
        final billNumber = await _ensureBillSaved();
        if (!mounted) return;
        final balance = (_total - _paymentAmount) < 0 ? 0.0 : (_total - _paymentAmount);
        final message = buildShareMessage(
          businessName: (await ref.read(settingsProvider.future)).businessName,
          docLabel: 'Sale Invoice',
          amount: _total,
          balance: balance,
        );
        await sharePdf(await _buildPdf(billNumber), filename: billNumber, message: message);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill saved & ready to share'), backgroundColor: AppTheme.success),
        );
        context.go('/bills');
      }, stage: 'Preparing bill...');


  /// Saves the bill once and returns its server-assigned number.
  ///
  /// Kept separate from printing because the number is what the printed copy
  /// shows, and the preview renders a placeholder until it arrives. The result
  /// is cached, so printing and sharing the same bill never creates a second
  /// bill, and no settings, font or PDF work happens here.
  Future<String> _ensureBillSaved() async {
    final existing = _billNumber;
    if (existing != null) return existing;

    final billService = ref.read(billServiceProvider);
    final result = await billService.create(_buildCreatePayload());
    final billNumber = result['billNumber'] as String;
    if (!mounted) return billNumber;

    _billNumber = billNumber;
    ref.invalidate(billListProvider);
    ref.invalidate(draftListProvider);
    ref.invalidate(draftCountProvider);
    setState(() {});
    // Wait a frame so the printed Bill No. is painted before capture.
    await WidgetsBinding.instance.endOfFrame;
    return billNumber;
  }

  /// Only the share path needs a real PDF file; the print path reuses the
  /// already-rendered preview and never calls this.
  Future<Uint8List> _buildPdf(String billNumber) async {
    final settings = await ref.read(settingsProvider.future);
    return buildBillPdf(
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
      billDate: _billDate,
      paymentMode: _paymentMode.displayName,
      isReprint: false,
    );
  }

  static const _red = Color(0xFFB71C1C);
  static const _muted = Color(0xFF757575);
  static const _line = Color(0xFFBDBDBD);
  static const _lightLine = Color(0xFFE0E0E0);

  Widget _thinLine({double thickness = 0.7}) {
    return Container(height: thickness, color: _line);
  }

  Widget _buildCopy({required bool isCustomerCopy, required double maxWidth}) {
    final copySuffix = isCustomerCopy ? 'Customer Copy' : 'Office Copy';
    final copyLabel = isCustomerCopy ? 'ORIGINAL' : 'DUPLICATE';
    final billDateTime = _billDate;
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
                      _infoField('Bill No.', _billNumber ?? 'Will be generated on print'),
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
                        _infoField('Date', AppUtils.formatDate(billDateTime)),
                        const SizedBox(height: 6),
                        _infoField('Time', DateFormat('hh:mm a').format(billDateTime)),
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

          // ── Summary & Stamp (in line with Grand Total, slightly to the left) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 110, bottom: 4),
                  child: buildStampPreview(width: 150),
                ),
                SizedBox(
                  width: 220,
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
              ],
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
          const SizedBox(height: 10),
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryRed,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: Text(
                AppUtils.formatDate(_billDate),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: _busyStage != null ? null : _pickBillDate,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Bills', route: '/bills'), Crumb('Preview')]),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        RepaintBoundary(
                          key: _customerCopyKey,
                          child: _buildCopy(isCustomerCopy: true, maxWidth: 700),
                        ),
                        const SizedBox(height: 24),
                        RepaintBoundary(
                          key: _officeCopyKey,
                          child: _buildCopy(isCustomerCopy: false, maxWidth: 700),
                        ),
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
                        onPressed: _busyStage == null ? () => context.pop() : null,
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                        onPressed: _busyStage == null ? () => _share() : null,
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Print Both Copies'),
                        onPressed: _busyStage == null ? () => _print() : null,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_busyStage != null)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 16),
                          Text(_busyStage!, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
