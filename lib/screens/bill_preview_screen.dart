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
  final String? editingBillId;
  final String? editingBillNumber;

  const BillPreviewScreen({
    super.key,
    required this.customer,
    required this.items,
    this.deliveryCharge = 0,
    this.paymentAmount = 0,
    this.paymentMode = PaymentMode.cash,
    this.draftId,
    this.billDate,
    this.editingBillId,
    this.editingBillNumber,
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
    _billNumber = widget.editingBillNumber;
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


  Future<void> _saveOnly() => _runBusy(() async {
        final billNumber = await _ensureBillSaved();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editingBillId != null
                ? 'Bill $billNumber updated successfully'
                : 'Bill $billNumber saved successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go('/bills');
      }, stage: 'Saving bill...');

  /// Saves the bill once and returns its server-assigned number.
  ///
  /// Kept separate from printing because the number is what the printed copy
  /// shows, and the preview renders a placeholder until it arrives. The result
  /// is cached, so printing and sharing the same bill never creates a second
  /// bill, and no settings, font or PDF work happens here.
  Future<String> _ensureBillSaved() async {
    final billService = ref.read(billServiceProvider);

    if (widget.editingBillId != null) {
      final result = await billService.update(widget.editingBillId!, _buildCreatePayload());
      final billNumber = result['billNumber'] as String? ?? widget.editingBillNumber ?? _billNumber ?? 'Bill';
      if (!mounted) return billNumber;

      _billNumber = billNumber;
      ref.invalidate(billListProvider);
      ref.invalidate(billDetailProvider(widget.editingBillId!));
      setState(() {});
      await WidgetsBinding.instance.endOfFrame;
      return billNumber;
    }

    final existing = _billNumber;
    if (existing != null) return existing;

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
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _darkHeader = Color(0xFF2D2D3A);

  Widget _thinLine({double thickness = 0.5}) {
    return Container(height: thickness, color: _line);
  }

  Widget _buildCopy({required bool isCustomerCopy, required double maxWidth}) {
    final copySuffix = isCustomerCopy ? 'Customer Copy' : 'Office Copy';
    final copyLabel = isCustomerCopy ? 'ORIGINAL' : 'DUPLICATE';
    final billDateTime = _billDate;
    final grandTotal = _total > 0 ? _total : _subtotal;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final businessName = settings?.businessName.isNotEmpty == true ? settings!.businessName : 'RATHOD ENTERPRISES';
    final tagline = settings?.tagline ?? 'Vegetable, Fruits Supplier & Commission Agent';
    final phone = (settings?.phone != null && settings!.phone!.isNotEmpty) ? settings.phone! : '8087344819, 9529031540';
    final address = (settings?.address != null && settings!.address!.isNotEmpty)
        ? settings.address!
        : 'Shop No.95 Kanji House, Phule Market, Cotton Market, Nagpur';

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 2.5, color: _red),

          // ── Top Bar (Bill No, Copy Badge, Contact Numbers) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bill No: ${_billNumber ?? "Pending"}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCustomerCopy ? _red.withAlpha(20) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$copyLabel – $copySuffix',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isCustomerCopy ? _red : Colors.grey.shade700,
                    ),
                  ),
                ),
                Text(
                  'Mob: $phone',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
          _thinLine(thickness: 0.5),

          // ── Compact Business Branding ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    businessName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _red, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$tagline  •  $address',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 8.5, color: _muted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          _thinLine(thickness: 0.5),

          // ── Compact Customer Info Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          const Text('Customer: ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)),
                          Expanded(
                            child: Text(
                              widget.customer.name,
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('Mob: ${widget.customer.mobile}', style: const TextStyle(fontSize: 9.5)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Date: ${AppUtils.formatDate(billDateTime)}  ${DateFormat("hh:mm a").format(billDateTime)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 9.5),
                      ),
                    ),
                  ],
                ),
                if (widget.customer.address?.isNotEmpty == true || _paymentMode.displayName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        if (widget.customer.address?.isNotEmpty == true)
                          Expanded(
                            child: Text(
                              'Address: ${widget.customer.address!}',
                              style: const TextStyle(fontSize: 8.5, color: _muted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (_paymentMode.displayName.isNotEmpty)
                          Text('Payment: ${_paymentMode.displayName}', style: const TextStyle(fontSize: 8.5, color: _muted)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _thinLine(thickness: 0.5),
          const SizedBox(height: 4),

          // ── Statement-Style Products Table (No vertical borders, compact) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                // Header row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                  decoration: const BoxDecoration(color: _darkHeader),
                  child: const Row(
                    children: [
                      SizedBox(width: 24, child: Text('Sr.', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
                      Expanded(flex: 30, child: Padding(padding: EdgeInsets.only(left: 6), child: Text('Product', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)))),
                      SizedBox(width: 44, child: Text('Unit', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
                      SizedBox(width: 40, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
                      SizedBox(width: 55, child: Text('Rate (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
                      SizedBox(width: 65, child: Text('Amount (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
                    ],
                  ),
                ),
                // Data rows
                ..._items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final productName = item.productNameHindi.isNotEmpty
                      ? '${item.productName} (${item.productNameHindi})'
                      : item.productName;
                  final isAlt = idx.isOdd;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 3.5, horizontal: 6),
                    color: isAlt ? const Color(0xFFF9FAFB) : Colors.white,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 24, child: Text('${idx + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 9))),
                        Expanded(
                          flex: 30,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(productName, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        SizedBox(width: 44, child: Text(item.unit, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9))),
                        SizedBox(
                          width: 40,
                          child: Text(
                            item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 9),
                          ),
                        ),
                        SizedBox(
                          width: 55,
                          child: Text(item.appliedRate.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 9)),
                        ),
                        SizedBox(
                          width: 65,
                          child: Text(item.amount.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          _thinLine(thickness: 0.5),

          // ── Compact Summary & Stamp ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 30, bottom: 2),
                  child: buildStampPreview(width: 105),
                ),
                SizedBox(
                  width: 190,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _amountRow('Subtotal', _subtotal),
                      if (widget.deliveryCharge > 0)
                        _amountRow('Delivery Charge', widget.deliveryCharge),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: _line, width: 0.6),
                            bottom: BorderSide(color: _line, width: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            Text('₹ ${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
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
          const SizedBox(height: 6),
        ],
      ),
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
                    const SizedBox(width: 8),
                    if (widget.editingBillId != null) ...[
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Save Only'),
                          onPressed: _busyStage == null ? () => _saveOnly() : null,
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                        onPressed: _busyStage == null ? () => _share() : null,
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.print, size: 18),
                        label: Text(widget.editingBillId != null ? 'Update & Print' : 'Print Both Copies'),
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
