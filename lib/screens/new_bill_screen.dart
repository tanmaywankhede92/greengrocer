import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../models/customer.dart';
import '../core/enums.dart';
import '../providers/rate_provider.dart';
import '../widgets/breadcrumb.dart';
import '../widgets/customer_select.dart';
import '../widgets/bill_item_row.dart';
import '../widgets/payment_mode_select.dart';
import 'bill_preview_screen.dart';

class NewBillScreen extends ConsumerStatefulWidget {
  const NewBillScreen({super.key});
  @override
  ConsumerState<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends ConsumerState<NewBillScreen> {
  Customer? _selectedCustomer;
  final List<LineItem> _items = [];
  double _paymentAmount = 0;
  PaymentMode _paymentMode = PaymentMode.cash;
  Map<String, double> _defaultRates = {};
  final _deliveryBoyCtrl = TextEditingController();
  final _paymentCtrl = TextEditingController();

  @override
  void dispose() {
    _deliveryBoyCtrl.dispose();
    _paymentCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.amount);
  double get _total => _subtotal;
  double get _newDue => (_selectedCustomer?.currentDue ?? 0) + _total - _paymentAmount;

  void _addItem() {
    setState(() => _items.add(LineItem()));
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _loadDefaultRates() async {
    try {
      final rateService = ref.read(rateServiceProvider);
      final rates = await rateService.getByDate(DateTime.now());
      setState(() {
        _defaultRates = rates.map((key, value) => MapEntry(key, value.rate));
      });
    } catch (_) {}
  }

  void _goToPreview() {
    if (_selectedCustomer == null) return;
    if (_items.isEmpty || _items.any((i) => i.productName.isEmpty || i.quantity <= 0)) return;

    Navigator.push(context, MaterialPageRoute(builder: (_) => BillPreviewScreen(
      customer: _selectedCustomer!,
      items: List.from(_items),
      deliveryBoyName: _deliveryBoyCtrl.text.trim(),
      paymentAmount: _paymentAmount,
      paymentMode: _paymentMode,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/bills')),
        title: const Text('New Bill'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Bills', route: '/bills'), Crumb('New Bill')]),
            const SizedBox(height: 16),
            CustomerSelect(
              onSelected: (c) {
                setState(() => _selectedCustomer = c);
                _loadDefaultRates();
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Line Items', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                  onPressed: _addItem,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Add items to the bill', style: TextStyle(color: AppTheme.textSecondary)))))
            else
              ..._items.asMap().entries.map((entry) => BillItemRow(
                key: ValueKey(entry.value.hashCode),
                item: entry.value,
                index: entry.key,
                defaultRates: _defaultRates,
                onRemove: () => _removeItem(entry.key),
                onChanged: () => setState(() {}),
              )),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _summaryRow('Subtotal', _subtotal),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(child: Text('Delivery Boy', style: TextStyle(color: AppTheme.textSecondary))),
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: _deliveryBoyCtrl,
                            decoration: const InputDecoration(isDense: true, hintText: 'Enter delivery boy name', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _summaryRow('Total', _total, bold: true),
                    if (_selectedCustomer != null) ...[
                      const SizedBox(height: 4),
                      _summaryRow('Previous Due', _selectedCustomer!.currentDue),
                      const Divider(height: 24),
                      _summaryRow('Amount Payable', _selectedCustomer!.currentDue + _total),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Payment', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _paymentCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount Paid'),
                      onChanged: (v) => setState(() => _paymentAmount = double.tryParse(v) ?? 0),
                    ),
                    const SizedBox(height: 12),
                    PaymentModeSelect(value: _paymentMode, onChanged: (v) => setState(() => _paymentMode = v ?? PaymentMode.cash)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('New Due', style: TextStyle(color: AppTheme.textSecondary)),
                        Text(AppUtils.formatCurrency(_newDue), style: TextStyle(color: _newDue > 0 ? AppTheme.warning : AppTheme.success, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _goToPreview,
                child: const Text('Preview & Print', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
        Text(AppUtils.formatCurrency(amount), style: TextStyle(color: AppTheme.textPrimary, fontSize: bold ? 18 : 14, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
