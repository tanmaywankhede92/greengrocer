import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/print_pdf.dart';
import '../../../core/utils.dart';
import '../../../core/enums.dart';
import '../../../core/params.dart';
import '../../../models/customer.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../widgets/payment_mode_select.dart';
import '../../../widgets/payment_invoice_pdf.dart';
import '../../../providers/settings_provider.dart';
import 'payment_helpers.dart';

class AddPaymentDialog extends ConsumerStatefulWidget {
  final Customer customer;
  final VoidCallback? onPaymentRecorded;

  const AddPaymentDialog({super.key, required this.customer, this.onPaymentRecorded});

  static Future<void> show(BuildContext context, {required WidgetRef ref, required Customer customer, VoidCallback? onPaymentRecorded}) {
    return showDialog(
      context: context,
      builder: (_) => AddPaymentDialog(customer: customer, onPaymentRecorded: onPaymentRecorded),
    );
  }

  @override
  ConsumerState<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends ConsumerState<AddPaymentDialog> {
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  PaymentMode _mode = PaymentMode.cash;
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.payments, size: 22, color: AppTheme.primaryRed),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Record Payment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          Text(c.name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      dialogRow('Outstanding', AppUtils.formatCurrency(c.currentDue)),
                      dialogRow('Total Paid', AppUtils.formatCurrency(c.totalPaid)),
                      if (c.currentDue > 0)
                        dialogRow('Due Amount', AppUtils.formatCurrency(c.currentDue), valueColor: AppTheme.error),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Payment Amount *', prefixIcon: Icon(Icons.currency_rupee, size: 18)),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                PaymentModeSelect(value: _mode, onChanged: (v) => setState(() => _mode = v ?? PaymentMode.cash)),
                const SizedBox(height: 12),
                TextField(controller: _refCtrl, decoration: const InputDecoration(labelText: 'Reference (optional)', prefixIcon: Icon(Icons.receipt, size: 18))),
                const SizedBox(height: 12),
                TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes, size: 18)), maxLines: 2),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton.icon(
                    icon: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle, size: 18),
                    label: Text(_submitting ? 'Recording...' : 'Receive Payment', style: const TextStyle(fontSize: 14)),
                    onPressed: _submitting ? null : () => _submit(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: AppTheme.error),
      );
      }
      return;
    }

    setState(() => _submitting = true);
    final c = widget.customer;
    try {
      await ref.read(paymentServiceProvider).create({
        'customerId': c.id,
        'amount': amount,
        'mode': _mode.value,
        'reference': _refCtrl.text,
        'notes': _notesCtrl.text,
        'paymentDate': AppUtils.formatDateApi(DateTime.now()),
      });
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ref.invalidate(customerListProvider(const CustomerListParams()));
        ref.invalidate(paymentListProvider(const PaymentListParams()));
        ref.invalidate(paymentListProvider(PaymentListParams(customerId: c.id)));
        widget.onPaymentRecorded?.call();
        _showInvoice(c, paidNow: amount, paymentMode: _mode.value);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  Future<void> _showInvoice(Customer customer, {required double paidNow, required String paymentMode}) async {
    try {
      final settings = await ref.read(settingsProvider.future);
      final previousOutstanding = customer.currentDue + paidNow;
      final remainingOutstanding = customer.currentDue;
      final now = DateTime.now();
      final receiptNumber = 'RCP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecond}';
      final pdf = await buildPaymentInvoicePdf(
        settings: settings,
        receiptNumber: receiptNumber,
        customer: customer,
        amount: paidNow,
        paymentMode: paymentMode,
        previousOutstanding: previousOutstanding,
        remainingOutstanding: remainingOutstanding,
        paymentDate: now,
        remarks: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
      );
      if (mounted) await printPdf(pdf, filename: 'Payment-$receiptNumber');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice error: $e'), backgroundColor: AppTheme.error));
      }
    }
  }
}
