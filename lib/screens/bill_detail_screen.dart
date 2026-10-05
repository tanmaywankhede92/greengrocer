import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/print_pdf.dart';
import '../core/share_pdf.dart';
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
import '../widgets/bill_stamp.dart';
import '../widgets/bill_item_row.dart';

class BillDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const BillDetailScreen({super.key, required this.id});
  @override
  ConsumerState<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends ConsumerState<BillDetailScreen> {
  static const _red = Color(0xFFB71C1C);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _darkHeader = Color(0xFF2D2D3A);

  final _customerCopyKey = GlobalKey();
  final _officeCopyKey = GlobalKey();

  /// Set while a print job is running, so the action cannot be repeated and the
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    precacheStamp(context);
    BillPdfFonts.preload();
  }

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
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Bill',
                onPressed: () => context.push('/bills/${bill.id}/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                tooltip: 'Delete Bill',
                onPressed: () => _confirmDeleteBill(bill),
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
                        RepaintBoundary(
                          key: _customerCopyKey,
                          child: _buildCopy(
                            isCustomerCopy: true,
                            maxWidth: 700,
                            bill: bill,
                            items: items,
                            adjustments: adjustments,
                            isActive: isActive,
                          ),
                        ),
                        const SizedBox(height: 24),
                        RepaintBoundary(
                          key: _officeCopyKey,
                          child: _buildCopy(
                            isCustomerCopy: false,
                            maxWidth: 700,
                            bill: bill,
                            items: items,
                            adjustments: adjustments,
                            isActive: isActive,
                          ),
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
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                        onPressed: () => _share(bill, items, adjustments),
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
                        onPressed: _printing ? null : () => _reprint(bill, items, adjustments),
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

  Future<void> _confirmDeleteBill(Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bill Permanently?'),
        content: Text(
          'Are you sure you want to delete bill "${bill.billNumber}"?\n\n'
          'This will permanently erase all records of this bill, customer ledger entries, and payment history from the database. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(billServiceProvider).deleteBill(bill.id);
        ref.invalidate(billListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bill "${bill.billNumber}" deleted successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
          context.go('/bills');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ApiClient.humanizeError(e)),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _reprint(Bill bill, List<BillItem> items, List<BillAdjustment> adjustments) async {
    if (_printing) return;
    setState(() => _printing = true);
    try {
      final pdf = await _buildBillPdf(bill, items, adjustments);
      if (pdf != null) {
        await printPdf(pdf, filename: bill.billNumber);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _printing = false);
      }
    }
  }

  Future<void> _share(Bill bill, List<BillItem> items, List<BillAdjustment> adjustments) async {
    try {
      final pdf = await _buildBillPdf(bill, items, adjustments);
      if (pdf == null) return;
      final settings = await ref.read(settingsProvider.future);
      final grandTotal = bill.total > 0 ? bill.total : bill.subtotal;
      final balance = grandTotal - bill.paidNow;
      final message = buildShareMessage(
        businessName: settings.businessName,
        docLabel: 'Sale Invoice',
        amount: grandTotal,
        balance: balance < 0 ? 0 : balance,
      );
      await sharePdf(pdf, filename: bill.billNumber, message: message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<Uint8List?> _buildBillPdf(Bill bill, List<BillItem> items, List<BillAdjustment> adjustments) async {
    final settings = await ref.read(settingsProvider.future);
    final lineItems = items.map((i) {
      return LineItem(
        productId: i.productId,
        productName: i.productName,
        productNameHindi: i.productNameHindi,
        unit: i.unit,
        quantity: i.quantity,
        defaultRate: i.defaultRate,
        appliedRate: i.appliedRate,
      );
    }).toList();
    return buildBillPdf(
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
      adjustmentAmount: 0,
      adjustmentNote: '',
    );
  }

  Widget _thinLine({double thickness = 0.5}) => Container(height: thickness, color: _line);

  Widget _infoField(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: _muted),
          ),
        ),
        const Text(':  ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: _muted)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? AppTheme.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCopy({
    required bool isCustomerCopy,
    required double maxWidth,
    required Bill bill,
    required List<BillItem> items,
    required List<BillAdjustment> adjustments,
    bool isActive = false,
  }) {
    final copySuffix = isCustomerCopy ? 'Customer Copy' : 'Office Copy';
    final copyLabel = isCustomerCopy ? 'ORIGINAL' : 'DUPLICATE';
    final billDate = bill.billDate;
    final grandTotal = bill.total > 0 ? bill.total : bill.subtotal;
    final totalAdjusted = adjustments.fold<double>(0, (sum, a) => sum + a.amount);
    final adjustedTotal = grandTotal - totalAdjusted;

    final settings = ref.watch(settingsProvider).valueOrNull;
    final businessName = settings?.businessName.isNotEmpty == true ? settings!.businessName : 'RATHOD ENTERPRISES';
    final tagline = settings?.tagline ?? 'Vegetable, Fruits Supplier & Commission Agent';
    final phone = (settings?.phone != null && settings!.phone!.isNotEmpty)
        ? settings.phone!
        : 'Nitesh : 8087344819   |   Vicky : 9529031540   |   7030914867';
    final address = (settings?.address != null && settings!.address!.isNotEmpty)
        ? settings.address!
        : 'Shop No.95 Kanji House, Mahatma Phule Market, Cotton Market, Nagpur – 440018';

    final paymentText = (bill.paymentType != null && bill.paymentType!.trim().isNotEmpty)
        ? (bill.paymentType!.trim().toLowerCase() == 'upi'
            ? 'UPI'
            : bill.paymentType!.trim()[0].toUpperCase() + bill.paymentType!.trim().substring(1).toLowerCase())
        : 'Credit';

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

          // ── Header (Branding) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 80),
                    Text(
                      businessName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _red, letterSpacing: 1.0),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tagline,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _muted),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9.5, color: _muted),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
          _thinLine(thickness: 0.5),
          const SizedBox(height: 8),

          // ── Systematic Customer & Bill Details Card (NO TIME!) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                border: Border.all(color: _line, width: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Customer Info
                  Expanded(
                    flex: 55,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoField('Customer', bill.customer?.name ?? '-', isBold: true),
                        const SizedBox(height: 4),
                        _infoField('Mobile', bill.customer?.mobile ?? '-'),
                        const SizedBox(height: 4),
                        _infoField('Address', (bill.customer?.address?.isNotEmpty == true) ? bill.customer!.address! : '-'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 0.6, height: 48, color: _line),
                  const SizedBox(width: 12),
                  // Right Column: Bill Info (NO TIME!)
                  Expanded(
                    flex: 45,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoField('Bill No.', bill.billNumber, isBold: true, valueColor: _red),
                        const SizedBox(height: 4),
                        _infoField('Date', AppUtils.formatDate(billDate), isBold: true),
                        const SizedBox(height: 4),
                        _infoField('Payment', paymentText),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

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
                ...items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final productName = item.productNameHindi.isNotEmpty
                      ? '${item.productName} (${item.productNameHindi})'
                      : item.productName;

                  final qtyStr = AppUtils.formatQuantity(item.quantity);
                  final amt = item.quantity * item.appliedRate;
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
                            qtyStr,
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
                          child: Text(
                            amt.toStringAsFixed(2),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                          ),
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
                      _amountRow('Subtotal', bill.subtotal),
                      if (bill.deliveryCharge > 0)
                        _amountRow('Delivery Charge', bill.deliveryCharge),
                      if (totalAdjusted > 0) ...[
                        _amountRow('Grand Total', grandTotal),
                        _amountRow('Adjustment', -totalAdjusted, isAdjustment: true),
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
                              const Text('Final Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryRed)),
                              Text('₹ ${adjustedTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryRed)),
                            ],
                          ),
                        ),
                      ] else
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
                              Text(AppUtils.formatCurrency(grandTotal), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      if (bill.paidNow > 0) _amountRow('Paid', bill.paidNow),
                      if (bill.paidNow > 0 && (totalAdjusted > 0 ? (adjustedTotal - bill.paidNow > 0) : (grandTotal - bill.paidNow > 0)))
                        _amountRow('Balance Due', (totalAdjusted > 0 ? adjustedTotal : grandTotal) - bill.paidNow, isBold: true),
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

  Widget _amountRow(String label, double value, {bool isAdjustment = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: isBold ? 11 : 9.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isAdjustment ? Colors.orange.shade800 : AppTheme.textPrimary,
          )),
          Text(
            AppUtils.formatCurrency(value.abs()),
            style: TextStyle(
              fontSize: isBold ? 11 : 9.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: isAdjustment ? Colors.orange.shade800 : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
