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
import '../models/payment.dart';
import '../providers/customer_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/breadcrumb.dart';
import '../widgets/customer_select.dart';
import '../widgets/payment_mode_select.dart';
import '../widgets/payment_receipt_pdf.dart';
import 'payments/widgets/statement_dialog.dart';


class AddPaymentScreen extends ConsumerStatefulWidget {
  const AddPaymentScreen({super.key});
  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  Customer? _selectedCustomer;
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  PaymentMode _mode = PaymentMode.cash;
  DateTime _paymentDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedCustomer == null) return;
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(paymentServiceProvider).create({
        'customerId': _selectedCustomer!.id,
        'amount': amount,
        'mode': _mode.value,
        'reference': _refCtrl.text,
        'notes': _notesCtrl.text,
        'paymentDate': AppUtils.formatDateApi(_paymentDate),
      });
      final receiptNum = result['receiptNumber'] as String? ?? result['id'] as String;
      if (mounted) {
        ref.invalidate(customerListProvider(CustomerListParams()));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded'), backgroundColor: AppTheme.success));
        _showReceipt(receiptNum);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showReceipt(String paymentId) async {
    try {
      final pdf = await buildPaymentReceiptPdf(
        receiptNumber: paymentId,
        customer: _selectedCustomer!,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        modeDisplay: _mode.displayName,
        reference: _refCtrl.text.isNotEmpty ? _refCtrl.text : null,
        notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
        paymentDate: _paymentDate,
        outstandingBefore: _selectedCustomer!.currentDue,
        outstandingAfter: (_selectedCustomer!.currentDue - (double.tryParse(_amountCtrl.text) ?? 0)).clamp(0, double.infinity),
      );
      if (mounted) await printPdf(pdf, filename: 'Receipt-$paymentId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Receipt error: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  void _downloadStatement() {
    if (_selectedCustomer == null) return;
    StatementDownloadDialog.show(context, ref: ref, customer: _selectedCustomer!);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    Widget? recentPayments;
    if (_selectedCustomer != null) {
      final paymentsAsync = ref.watch(paymentListProvider(PaymentListParams(customerId: _selectedCustomer!.id, limit: 20)));
      recentPayments = paymentsAsync.when(
        loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        error: (e, _) => Padding(padding: const EdgeInsets.only(top: 8), child: Text('$e', style: TextStyle(color: AppTheme.error, fontSize: 13))),
        data: (result) {
          if (result.data.isEmpty) {
            return Padding(padding: const EdgeInsets.only(top: 16),
              child: Center(child: Text('No payments yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))));
          }
          return _buildRecentPayments(result.data, isMobile);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/payments')),
        title: const Text('Add Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Payments', route: '/payments'), Crumb('Add Payment')]),
              const SizedBox(height: 20),
              CustomerSelect(onSelected: (c) => setState(() => _selectedCustomer = c)),
              if (_selectedCustomer != null) ...[
                const SizedBox(height: 20),
                _buildSummaryCard(isMobile),
                const SizedBox(height: 24),
                _buildPaymentForm(isMobile),
                const SizedBox(height: 24),
                _buildStatementSection(isMobile, recentPayments),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(bool isMobile) {
    final c = _selectedCustomer!;
    final status = c.currentDue <= 0 ? 'Paid' : c.totalPaid > 0 ? 'Partial' : 'Unpaid';
    final statusColor = c.currentDue <= 0 ? AppTheme.success : c.totalPaid > 0 ? AppTheme.info : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(c.name, style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withAlpha(60)),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(c.mobile, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statTile('Outstanding', AppUtils.formatCurrency(c.currentDue), AppTheme.textPrimary)),
              Container(width: 1, height: 36, color: AppTheme.border),
              Expanded(child: _statTile('Total Paid', AppUtils.formatCurrency(c.totalPaid), AppTheme.success)),
              Container(width: 1, height: 36, color: AppTheme.border),
              Expanded(child: _statTile('Bills', '${c.billCount}', AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildPaymentForm(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payments, size: 18, color: AppTheme.primaryRed),
            const SizedBox(width: 8),
            Text('Record Payment', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: isMobile
              ? Column(children: _formFields())
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(children: _formFields().sublist(0, _formFields().length ~/ 2))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(children: _formFields().sublist(_formFields().length ~/ 2))),
                ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            icon: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.check_circle, size: 20),
            label: Text(_isSubmitting ? 'Recording...' : 'Record Payment', style: const TextStyle(fontSize: 15)),
            onPressed: _isSubmitting ? null : () { openPrintWindow(); _submit(); },
          ),
        ),
      ],
    );
  }

  List<Widget> _formFields() {
    return [
      TextField(controller: _amountCtrl, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Amount *', prefixIcon: Icon(Icons.currency_rupee, size: 18))),
      const SizedBox(height: 14),
      PaymentModeSelect(value: _mode, onChanged: (v) => setState(() => _mode = v ?? PaymentMode.cash)),
      const SizedBox(height: 14),
      TextField(controller: _refCtrl, decoration: const InputDecoration(labelText: 'Reference (optional)', prefixIcon: Icon(Icons.receipt, size: 18))),
      const SizedBox(height: 14),
      TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes, size: 18)), maxLines: 2),
      const SizedBox(height: 14),
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: _paymentDate, firstDate: DateTime(2020), lastDate: DateTime.now());
          if (picked != null) setState(() => _paymentDate = picked);
        },
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Payment Date', prefixIcon: Icon(Icons.calendar_today, size: 18), isDense: true),
          child: Text(DateFormat('dd MMM yyyy').format(_paymentDate), style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
        ),
      ),
    ];
  }

  Widget _buildStatementSection(bool isMobile, Widget? recentPayments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description_outlined, size: 18, color: AppTheme.primaryRed),
            const SizedBox(width: 8),
            Text('Recent Transactions', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Download Statement', style: TextStyle(fontSize: 12)),
              onPressed: _downloadStatement,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          padding: const EdgeInsets.all(16),
          child: recentPayments ?? Center(child: Text('Select a customer to view transactions', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
        ),
      ],
    );
  }

  Widget _buildRecentPayments(List<Payment> data, bool isMobile) {
    if (isMobile) {
      return Column(
        children: data.take(10).map((p) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#${p.receiptNumber}', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(DateFormat('dd MMM yy').format(p.paymentDate), style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Text(AppUtils.formatCurrency(p.amount), style: TextStyle(color: AppTheme.success, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        )).toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            _th('Receipt', 100),
            _th('Date', 100),
            _th('Mode', 90),
            _th('Reference', 120),
            _th('Amount', 100, align: TextAlign.right),
          ],
        ),
        const Divider(height: 1, color: AppTheme.border),
        const SizedBox(height: 4),
        ...data.take(10).map((p) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5))),
          child: Row(
            children: [
              SizedBox(width: 100, child: Text('#${p.receiptNumber}', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
              SizedBox(width: 100, child: Text(DateFormat('dd MMM yy').format(p.paymentDate), style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
              SizedBox(width: 90, child: Text(p.mode.displayName, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
              SizedBox(width: 120, child: Text(p.reference ?? '', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
              SizedBox(width: 100, child: Text(AppUtils.formatCurrency(p.amount), style: TextStyle(color: AppTheme.success, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _th(String label, double width, {TextAlign align = TextAlign.left}) {
    return SizedBox(
      width: width,
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 0.5), textAlign: align),
    );
  }
}
