import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/print_pdf.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../core/params.dart';
import '../core/enums.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/statement_provider.dart';
import '../widgets/breadcrumb.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/payment_receipt_pdf.dart';
import '../widgets/statement_pdf.dart';
import '../widgets/payment_mode_select.dart';


class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});
  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddPaymentDialog(Customer customer) {
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    PaymentMode mode = PaymentMode.cash;
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Payment'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(customer.mobile, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const Divider(height: 20),
                  _dialogRow('Outstanding', AppUtils.formatCurrency(customer.currentDue)),
                  _dialogRow('Total Paid', AppUtils.formatCurrency(customer.totalPaid)),
                  if (customer.currentDue > 0)
                    _dialogRow('Due', AppUtils.formatCurrency(customer.currentDue), valueColor: AppTheme.error),
                  const Divider(height: 20),
                  TextField(controller: amountCtrl, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Payment Amount *', prefixIcon: Icon(Icons.currency_rupee, size: 18))),
                  const SizedBox(height: 12),
                  PaymentModeSelect(value: mode, onChanged: (v) => setDialogState(() => mode = v ?? PaymentMode.cash)),
                  const SizedBox(height: 12),
                  TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Reference (optional)', prefixIcon: Icon(Icons.receipt, size: 18))),
                  const SizedBox(height: 12),
                  TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes, size: 18)), maxLines: 2),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: submitting ? null : () {
                openPrintWindow();
                () async {
                  final amount = double.tryParse(amountCtrl.text);
                  if (amount == null || amount <= 0) return;
                  setDialogState(() => submitting = true);
                  try {
                    final result = await ref.read(paymentServiceProvider).create({
                      'customerId': customer.id,
                      'amount': amount,
                      'mode': mode.value,
                      'reference': refCtrl.text,
                      'notes': notesCtrl.text,
                      'paymentDate': AppUtils.formatDateApi(DateTime.now()),
                    });
                    final receiptNum = result['receiptNumber'] as String? ?? result['id'] as String;
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ref.invalidate(customerListProvider(CustomerListParams()));
                      _showReceipt(customer, receiptNum, amount, mode, refCtrl.text, notesCtrl.text, customer.currentDue, customer.currentDue - amount);
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
                    }
                    setDialogState(() => submitting = false);
                  }
                }();
              },
              child: submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Receive Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReceipt(Customer customer, String paymentId, double amount, PaymentMode mode,
      String ref, String notes, double outstandingBefore, double outstandingAfter) async {
    try {
      final pdf = await buildPaymentReceiptPdf(
        receiptNumber: paymentId,
        customer: customer,
        amount: amount,
        modeDisplay: mode.displayName,
        reference: ref.isNotEmpty ? ref : null,
        notes: notes.isNotEmpty ? notes : null,
        paymentDate: DateTime.now(),
        outstandingBefore: outstandingBefore,
        outstandingAfter: outstandingAfter,
      );
      if (mounted) await printPdf(pdf, filename: 'Receipt-$paymentId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Receipt error: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  Future<void> _downloadInvoice(Customer customer) async {
    try {
      final service = ref.read(statementServiceProvider);
      final from = AppUtils.formatDateApi(DateTime.now().subtract(const Duration(days: 30)));
      final to = AppUtils.formatDateApi(DateTime.now());
      final data = await service.getStatement(customer.id, from: from, to: to);
      final pdf = await buildStatementPdf(
        customerName: data['customer']['name'] ?? customer.name,
        customerMobile: data['customer']['mobile'] ?? customer.mobile,
        customerAddress: customer.address,
        from: from,
        to: to,
        openingBalance: (data['openingBalance'] ?? 0).toDouble(),
        closingBalance: (data['closingBalance'] ?? 0).toDouble(),
        totalDebit: (data['totalDebit'] ?? 0).toDouble(),
        totalCredit: (data['totalCredit'] ?? 0).toDouble(),
        rows: (data['rows'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      );
      if (mounted) await printPdf(pdf, filename: 'Statement-${customer.name}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice error: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  Future<void> _showStatementDialog(Customer customer) async {
    DateTime from = DateTime.now().subtract(const Duration(days: 30));
    DateTime to = DateTime.now();
    bool loading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Download Statement'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name, style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(customer.mobile, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const Divider(height: 20),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: from, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (picked != null) setDialogState(() => from = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'From Date', isDense: true),
                    child: Text(DateFormat('dd MMM yyyy').format(from), style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: to, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (picked != null) setDialogState(() => to = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'To Date', isDense: true),
                    child: Text(DateFormat('dd MMM yyyy').format(to), style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download, size: 18),
              label: Text(loading ? 'Generating...' : 'Download'),
              onPressed: loading ? null : () {
                openPrintWindow();
                () async {
                  setDialogState(() => loading = true);
                  try {
                    final service = ref.read(statementServiceProvider);
                    final data = await service.getStatement(customer.id,
                      from: AppUtils.formatDateApi(from), to: AppUtils.formatDateApi(to));
                    if (ctx.mounted) Navigator.pop(ctx);
                    final pdf = await buildStatementPdf(
                      customerName: data['customer']['name'] ?? customer.name,
                      customerMobile: data['customer']['mobile'] ?? customer.mobile,
                      customerAddress: customer.address,
                      from: AppUtils.formatDateApi(from),
                      to: AppUtils.formatDateApi(to),
                      openingBalance: (data['openingBalance'] ?? 0).toDouble(),
                      closingBalance: (data['closingBalance'] ?? 0).toDouble(),
                      totalDebit: (data['totalDebit'] ?? 0).toDouble(),
                      totalCredit: (data['totalCredit'] ?? 0).toDouble(),
                      rows: (data['rows'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
                    );
                    if (mounted) await printPdf(pdf, filename: 'Statement-${customer.name}');
                  } catch (e) {
                    if (ctx.mounted) {
                      setDialogState(() => loading = false);
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
                    }
                  }
                }();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final params = CustomerListParams(search: _search, page: 1, limit: 200);
    final customersAsync = ref.watch(customerListProvider(params));
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          if (_search.isNotEmpty)
            IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _search = ''; _searchCtrl.clear(); })),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Payment'),
              onPressed: () => context.go('/payments/add'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryRed),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Payments')]),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: SizedBox(
              width: isMobile ? double.infinity : 420,
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(hintText: 'Search customer...', prefixIcon: Icon(Icons.search), isDense: true),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: customersAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('$e', style: TextStyle(color: AppTheme.error))),
              data: (result) {
                if (result.data.isEmpty) return const EmptyState(icon: Icons.people_outline, title: 'No customers found');
                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 768) {
                      return _buildMobileList(result.data);
                    }
                    return _buildDesktopTable(result.data, constraints.maxWidth);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(List<Customer> data) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final c = data[index];
        final status = c.currentDue <= 0 ? 'Paid' : c.totalPaid > 0 ? 'Partial' : 'Unpaid';
        final statusColor = c.currentDue <= 0 ? AppTheme.success : c.totalPaid > 0 ? AppTheme.info : AppTheme.error;
        return _buildMobileCard(c, status, statusColor);
      },
    );
  }

  Widget _buildMobileCard(Customer c, String status, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.name, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(c.mobile, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Outstanding', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(AppUtils.formatCurrency(c.currentDue), style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paid', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(AppUtils.formatCurrency(c.totalPaid), style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withAlpha(25), borderRadius: BorderRadius.circular(4)),
              child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (c.currentDue > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.payments, size: 14),
                      label: const Text('Pay', style: TextStyle(fontSize: 11)),
                      onPressed: () => _showAddPaymentDialog(c),
                    ),
                  ),
                if (c.currentDue > 0) const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.description_outlined, size: 14),
                    label: const Text('Stmt', style: TextStyle(fontSize: 11)),
                    onPressed: () => _showStatementDialog(c),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_long_outlined, size: 14),
                    label: const Text('Inv', style: TextStyle(fontSize: 11)),
                    onPressed: () { openPrintWindow(); _downloadInvoice(c); },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<Customer> data, double maxWidth) {
    const pad = 48.0;
    const colSr = 36.0;
    const colActions = 210.0;
    const colStatus = 80.0;
    const colMobile = 110.0;
    final otherFixed = colSr + colActions + colStatus + colMobile;
    final available = (maxWidth - pad - otherFixed).clamp(100, double.infinity);
    final colName = available * 0.38;
    final colOutstanding = available * 0.31;
    final colPaid = available * 0.31;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Row(
            children: [
              SizedBox(width: colSr, child: _th('Sr', TextAlign.center)),
              SizedBox(width: colName, child: _th('Customer')),
              SizedBox(width: colMobile, child: _th('Mobile')),
              SizedBox(width: colOutstanding, child: _th('Outstanding', TextAlign.right)),
              SizedBox(width: colPaid, child: _th('Total Paid', TextAlign.right)),
              SizedBox(width: colStatus, child: _th('Status', TextAlign.center)),
              SizedBox(width: colActions, child: _th('Actions', TextAlign.center)),
            ],
          ),
        ),
        Container(height: 1, color: const Color(0xFFE0E0E0), margin: const EdgeInsets.symmetric(horizontal: 24)),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: data.length,
            itemBuilder: (context, index) {
              final c = data[index];
              final status = c.currentDue <= 0 ? 'Paid' : c.totalPaid > 0 ? 'Partial' : 'Unpaid';
              final statusColor = c.currentDue <= 0 ? AppTheme.success : c.totalPaid > 0 ? AppTheme.info : AppTheme.error;
              final isOdd = index.isOdd;
              return Container(
                decoration: BoxDecoration(
                  color: isOdd ? const Color(0xFFFAFAFC) : Colors.white,
                  border: Border(bottom: BorderSide(color: const Color(0xFFEEEEF0), width: 0.5)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Row(
                  children: [
                    SizedBox(width: colSr, child: Text('${index + 1}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500), textAlign: TextAlign.center)),
                    SizedBox(width: colName, child: Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2D2D2D)), overflow: TextOverflow.ellipsis)),
                    SizedBox(width: colMobile, child: Text(c.mobile, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                    SizedBox(width: colOutstanding, child: Text(AppUtils.formatCurrency(c.currentDue), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
                    SizedBox(width: colPaid, child: Text(AppUtils.formatCurrency(c.totalPaid), style: TextStyle(fontSize: 13, color: Colors.grey.shade600), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
                    SizedBox(width: colStatus, child: Center(child: _statusBadge(status, statusColor))),
                    SizedBox(
                      width: colActions,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _actionBtn(Icons.payments, 'Pay', AppTheme.primaryRed,
                              c.currentDue > 0 ? () => _showAddPaymentDialog(c) : null),
                          const SizedBox(width: 2),
                          _actionBtn(Icons.description_outlined, 'Stmt', AppTheme.textSecondary,
                              () => _showStatementDialog(c)),
                          const SizedBox(width: 2),
                          _actionBtn(Icons.receipt_long_outlined, 'Inv', AppTheme.textSecondary,
                              () => _downloadInvoice(c)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _th(String label, [TextAlign align = TextAlign.left]) {
    return Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 0.5), textAlign: align);
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback? onPressed) {
    return TextButton.icon(
      icon: Icon(icon, size: 13, color: onPressed == null ? Colors.grey.shade300 : color),
      label: Text(label, style: TextStyle(fontSize: 10, color: onPressed == null ? Colors.grey.shade300 : color, fontWeight: FontWeight.w500)),
      onPressed: onPressed,
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), visualDensity: VisualDensity.compact, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    );
  }

  Widget _dialogRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor ?? AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
