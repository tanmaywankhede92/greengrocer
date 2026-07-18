import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../core/enums.dart';
import '../providers/rate_provider.dart';
import '../services/product_service.dart';
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
  final _deliveryPhoneCtrl = TextEditingController();
  final _paymentCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<Product> _searchResults = [];
  bool _showSearchDropdown = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _deliveryBoyCtrl.dispose();
    _deliveryPhoneCtrl.dispose();
    _paymentCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    debugPrint('[NewBill] _onSearchChanged: "$query"');
    if (query.isEmpty) {
      setState(() { _searchResults = []; _showSearchDropdown = false; });
      return;
    }
    try {
      final results = await ProductService().getAll(search: query);
      debugPrint('[NewBill] _onSearchChanged: got ${results.length} results');
      if (mounted) setState(() {
        _searchResults = results.where((p) => p.isActive).toList();
        _showSearchDropdown = _searchResults.isNotEmpty;
      });
    } catch (e) {
      debugPrint('[NewBill] _onSearchChanged ERROR: $e');
    }
  }

  void _addProduct(Product product) {
    final defaultRate = _defaultRates[product.id] ?? 0;
    print('[NewBill] _addProduct: "${product.name}" id=${product.id} rate=$defaultRate');
    setState(() {
      final existing = _items.where((i) => i.productId == product.id).firstOrNull;
      if (existing != null) {
        existing.quantity += 1;
        print('[NewBill] _addProduct: incremented qty to ${existing.quantity}');
      } else {
        _items.add(LineItem(
          productId: product.id,
          productName: product.name,
          productNameHindi: product.nameHindi,
          unit: product.unit.value,
          quantity: 1,
          defaultRate: defaultRate,
          appliedRate: defaultRate,
        ));
        print('[NewBill] _addProduct: added new item (total items: ${_items.length})');
      }
      _searchCtrl.clear();
      _searchResults = [];
      _showSearchDropdown = false;
    });
    _searchFocusNode.requestFocus();
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.amount);
  double get _total => _subtotal;
  double get _newDue => (_selectedCustomer?.currentDue ?? 0) + _total - _paymentAmount;

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

    final phone = _deliveryPhoneCtrl.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery phone must be exactly 10 digits')));
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => BillPreviewScreen(
      customer: _selectedCustomer!,
      items: List.from(_items),
      deliveryBoyName: _deliveryBoyCtrl.text.trim(),
      deliveryBoyPhone: _deliveryPhoneCtrl.text.trim(),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  const Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Bills', route: '/bills'), Crumb('New Bill')]),
                  const SizedBox(height: 12),

                  CustomerSelect(
                    onSelected: (c) {
                      setState(() => _selectedCustomer = c);
                      _loadDefaultRates();
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('Add Items', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            focusNode: _searchFocusNode,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search product...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: null,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onSubmitted: (value) {
                              if (_searchResults.length == 1) {
                                _addProduct(_searchResults.first);
                              }
                            },
                          ),
                          if (_showSearchDropdown && _searchResults.isNotEmpty)
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxHeight: 240),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.border),
                                boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final p = _searchResults[index];
                                  return ListTile(
                                    dense: true,
                                    leading: Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(color: AppTheme.primaryRed.withAlpha(15), borderRadius: BorderRadius.circular(8)),
                                      child: Icon(Icons.inventory_2, color: AppTheme.primaryRed, size: 18),
                                    ),
                                    title: Text(p.nameHindi.isNotEmpty ? '${p.name} (${p.nameHindi})' : p.name, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                                    subtitle: Row(
                                      children: [
                                        if (p.nameHindi.isNotEmpty) ...[
                                          Text(p.nameHindi, style: TextStyle(color: AppTheme.textSecondary.withAlpha(150), fontSize: 12)),
                                          Text('  •  ', style: TextStyle(color: AppTheme.textSecondary.withAlpha(100), fontSize: 12)),
                                        ],
                                        Text('Unit: ${p.unit.value}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                        if (_defaultRates.containsKey(p.id)) ...[
                                          Text('  •  ', style: TextStyle(color: AppTheme.textSecondary.withAlpha(100), fontSize: 12)),
                                          Text('Rate: \u20B9${_defaultRates[p.id]!.toStringAsFixed(0)}', style: TextStyle(color: AppTheme.primaryRed, fontSize: 12, fontWeight: FontWeight.w500)),
                                        ],
                                      ],
                                    ),
                                    onTap: () {
                                      _addProduct(p);
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_items.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.add_shopping_cart, size: 48, color: Color(0xFFDDDDDD)),
                              SizedBox(height: 12),
                              Text('Search and select products above', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                              SizedBox(height: 4),
                              Text('Items added will appear here', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._items.asMap().entries.map((entry) => BillItemRow(
                      key: ValueKey('item_${entry.key}_${entry.value.productId}'),
                      item: entry.value,
                      index: entry.key,
                      defaultRates: _defaultRates,
                      onRemove: () => _removeItem(entry.key),
                      onChanged: () => setState(() {}),
                    )),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _summaryRow('Subtotal', _subtotal),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(child: Text('Delivery Boy', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14))),
                              SizedBox(
                                width: 180,
                                child: TextField(
                                  controller: _deliveryBoyCtrl,
                                  decoration: const InputDecoration(isDense: true, hintText: 'Name', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(child: Text('Delivery Phone', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14))),
                              SizedBox(
                                width: 180,
                                child: TextField(
                                  controller: _deliveryPhoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(isDense: true, hintText: 'Phone number', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
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
                  const SizedBox(height: 16),
                  Text('Payment', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextField(
                            controller: _paymentCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Amount Paid', prefixIcon: Icon(Icons.currency_rupee, size: 18)),
                            onChanged: (v) => setState(() => _paymentAmount = double.tryParse(v) ?? 0),
                          ),
                          const SizedBox(height: 12),
                          PaymentModeSelect(value: _paymentMode, onChanged: (v) => setState(() => _paymentMode = v ?? PaymentMode.cash)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _newDue > 0 ? AppTheme.warning.withAlpha(15) : AppTheme.success.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('New Due', style: TextStyle(color: AppTheme.textSecondary)),
                                Text(AppUtils.formatCurrency(_newDue), style: TextStyle(color: _newDue > 0 ? AppTheme.warning : AppTheme.success, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _goToPreview,
                      child: const Text('Preview & Print', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 40),
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
