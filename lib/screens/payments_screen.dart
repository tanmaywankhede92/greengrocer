import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../core/params.dart';
import '../core/enums.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/breadcrumb.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/payment_receipt_pdf.dart';
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

  Future<void> _showAddPayment(Customer customer) async {
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    PaymentMode mode = PaymentMode.cash;
    bool submitting = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name, style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(customer.mobile, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const Divider(height: 20),
                _row('Outstanding', AppUtils.formatCurrency(customer.currentDue)),
                _row('Total Paid', AppUtils.formatCurrency(customer.totalPaid)),
                if (customer.currentDue > 0)
                  _row('Current Outstanding', AppUtils.formatCurrency(customer.currentDue),
                      valueColor: AppTheme.error),
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
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: submitting ? null : () async {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || amount <= 0) return;
                setDialogState(() => submitting = true);
                try {
                  final id = await ref.read(paymentServiceProvider).create({
                    'customerId': customer.id,
                    'amount': amount,
                    'mode': mode.value,
                    'reference': refCtrl.text,
                    'notes': notesCtrl.text,
                    'paymentDate': AppUtils.formatDateApi(DateTime.now()),
                  });
                  if (ctx.mounted) Navigator.pop(ctx, true);
                  if (mounted) {
                    ref.invalidate(customerListProvider(CustomerListParams()));
                    _showReceipt(customer, id, amount, mode, refCtrl.text, notesCtrl.text, customer.currentDue, customer.currentDue - amount);
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
                  }
                  setDialogState(() => submitting = false);
                }
              },
              child: submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Receive Payment'),
            ),
          ],
        ),
      ),
    );
    if (result == true) ref.invalidate(customerListProvider(CustomerListParams()));
  }

  Future<void> _showReceipt(Customer customer, String paymentId, double amount, PaymentMode mode,
      String ref, String notes, double outstandingBefore, double outstandingAfter) async {
    try {
      final pdf = await buildPaymentReceiptPdf(
        receiptNumber: paymentId,
        customer: customer,
        amount: amount,
        mode: mode,
        reference: ref.isNotEmpty ? ref : null,
        notes: notes.isNotEmpty ? notes : null,
        paymentDate: DateTime.now(),
        outstandingBefore: outstandingBefore,
        outstandingAfter: outstandingAfter,
      );
      if (mounted) {
        await Printing.layoutPdf(onLayout: (_) => pdf);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Receipt error: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  Widget _buildMobileCard(Customer c, String status, Color statusColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (c.currentDue > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.payments, size: 16),
                      label: const Text('Add', style: TextStyle(fontSize: 12)),
                      onPressed: () => _showAddPayment(c),
                    ),
                  ),
                if (c.currentDue > 0) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: const Text('Statement', style: TextStyle(fontSize: 12)),
                    onPressed: () => context.go('/customers/${c.id}/statement'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<Customer> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(width: w * 0.22, child: _headerCell('Customer')),
                  SizedBox(width: w * 0.15, child: _headerCell('Mobile')),
                  SizedBox(width: w * 0.17, child: _headerCell('Outstanding')),
                  SizedBox(width: w * 0.15, child: _headerCell('Paid')),
                  SizedBox(width: w * 0.11, child: _headerCell('Status')),
                  const Spacer(),
                ],
              ),
            ),
            Container(height: 1, color: AppTheme.border),
            Expanded(
              child: ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final c = data[index];
                  final status = c.currentDue <= 0 ? 'Paid' :
                      c.totalPaid > 0 ? 'Partial' : 'Unpaid';
                  final statusColor = c.currentDue <= 0 ? AppTheme.success :
                      c.totalPaid > 0 ? AppTheme.warning : AppTheme.error;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: w * 0.22,
                              child: Text(c.name, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                            SizedBox(
                              width: w * 0.15,
                              child: Text(c.mobile, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ),
                            SizedBox(
                              width: w * 0.17,
                              child: Text(AppUtils.formatCurrency(c.currentDue), style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                            SizedBox(
                              width: w * 0.15,
                              child: Text(AppUtils.formatCurrency(c.totalPaid), style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            ),
                            SizedBox(
                              width: w * 0.11,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (c.currentDue > 0)
                                  TextButton.icon(
                                    icon: const Icon(Icons.payments, size: 16),
                                    label: const Text('Add', style: TextStyle(fontSize: 12)),
                                    onPressed: () => _showAddPayment(c),
                                  ),
                                TextButton.icon(
                                  icon: const Icon(Icons.description_outlined, size: 16),
                                  label: const Text('Statement', style: TextStyle(fontSize: 12)),
                                  onPressed: () => context.go('/customers/${c.id}/statement'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(height: 0.5, color: AppTheme.border.withAlpha(80)),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final params = CustomerListParams(search: _search, page: 1, limit: 200);
    final customersAsync = ref.watch(customerListProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          if (_search.isNotEmpty)
            IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _search = ''; _searchCtrl.clear(); })),
        ],
      ),
      body: Column(
        children: [
          const Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Payments')]),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(hintText: 'Search customer...', prefixIcon: Icon(Icons.search), isDense: true),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: customersAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('$e', style: TextStyle(color: AppTheme.error))),
              data: (result) {
                if (result.data.isEmpty) return const EmptyState(icon: Icons.people_outline, title: 'No customers found');
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 768;
                    if (isMobile) {
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        itemCount: result.data.length,
                        itemBuilder: (context, index) {
                          final c = result.data[index];
                          final status = c.currentDue <= 0 ? 'Paid' :
                              c.totalPaid > 0 ? 'Partial' : 'Unpaid';
                          final statusColor = c.currentDue <= 0 ? AppTheme.success :
                              c.totalPaid > 0 ? AppTheme.warning : AppTheme.error;
                          return _buildMobileCard(c, status, statusColor);
                        },
                      );
                    }
                    return _buildDesktopTable(result.data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String label) {
    return Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600));
  }

  Widget _row(String label, String value, {Color? valueColor}) {
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
