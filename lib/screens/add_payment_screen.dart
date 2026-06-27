import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../models/customer.dart';
import '../core/enums.dart';
import '../providers/payment_provider.dart';
import '../widgets/customer_select.dart';
import '../widgets/payment_mode_select.dart';

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
      await ref.read(paymentServiceProvider).create({
        'customerId': _selectedCustomer!.id,
        'amount': amount,
        'mode': _mode.value,
        'reference': _refCtrl.text,
        'notes': _notesCtrl.text,
        'paymentDate': AppUtils.formatDateApi(DateTime.now()),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded'), backgroundColor: AppTheme.success));
        context.go('/payments');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomerSelect(onSelected: (c) => setState(() => _selectedCustomer = c)),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount *')),
                    const SizedBox(height: 16),
                    PaymentModeSelect(value: _mode, onChanged: (v) => setState(() => _mode = v ?? PaymentMode.cash)),
                    const SizedBox(height: 16),
                    TextField(controller: _refCtrl, decoration: const InputDecoration(labelText: 'Reference (optional)')),
                    const SizedBox(height: 16),
                    TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)'), maxLines: 2),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Record Payment', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
