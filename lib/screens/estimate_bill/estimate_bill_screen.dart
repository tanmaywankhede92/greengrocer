import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../core/enums.dart';
import '../../core/print_pdf.dart';
import '../../core/share_pdf.dart';
import '../../core/utils.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/rate_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/bill_item_row.dart';
import '../../widgets/bill_pdf.dart';
import '../../widgets/breadcrumb.dart';
import '../new_bill/widgets/customer_section.dart';
import '../new_bill/widgets/empty_state.dart';
import '../new_bill/widgets/product_edit_row.dart';
import '../new_bill/widgets/product_list.dart';
import '../new_bill/widgets/product_search_bar.dart';
import '../new_bill/widgets/summary_card.dart';

class EstimateBillScreen extends ConsumerStatefulWidget {
  const EstimateBillScreen({super.key});

  @override
  ConsumerState<EstimateBillScreen> createState() => _EstimateBillScreenState();
}

class _EstimateBillScreenState extends ConsumerState<EstimateBillScreen> {
  Customer? _selectedCustomer;
  final List<LineItem> _items = [];
  double _deliveryCharge = 0;
  DateTime _billDate = DateTime.now();

  Product? _editingProduct;
  LineItem? _editingItem;
  final _qtyCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _qtyFocusNode = FocusNode();
  final _rateFocusNode = FocusNode();

  final _searchCtrl = TextEditingController();
  final _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  final GlobalKey _searchFieldKey = GlobalKey();
  List<Product> _searchResults = [];
  bool _isSearching = false;
  Map<String, double> _defaultRates = {};
  final Debouncer _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 300));
  OverlayEntry? _dropdownOverlay;

  String _estimateTitle = 'DELIVERY SLIP';
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultRates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productListProvider);
    });
  }

  @override
  void dispose() {
    _removeDropdown();
    _searchDebouncer.cancel();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _qtyFocusNode.dispose();
    _rateFocusNode.dispose();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showDropdown() {
    _removeDropdown();
    final RenderBox? renderBox =
        _searchFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;
    final size = renderBox.size;

    _dropdownOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeDropdown,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          CompositedTransformFollower(
            link: _searchLayerLink,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            showWhenUnlinked: false,
            child: SizedBox(
              width: size.width,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                child: ProductSearchDropdown(
                  results: _searchResults,
                  defaultRates: _defaultRates,
                  onSelected: (p) {
                    _selectProduct(p);
                    _removeDropdown();
                  },
                  onAddProduct: () {
                    _removeDropdown();
                  },
                  searchQuery: _searchCtrl.text.trim(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_dropdownOverlay!);
  }

  void _removeDropdown() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
  }

  Future<void> _loadDefaultRates() async {
    try {
      final rateService = ref.read(rateServiceProvider);
      final rates = await rateService.getByDate(_billDate);
      if (mounted) {
        setState(() {
          _defaultRates = rates.map((key, value) => MapEntry(key, value.rate));
        });
      }
    } catch (_) {}
  }

  void _onSearchChanged(String query) {
    final q = query.trim();
    if (q.isEmpty) {
      _searchDebouncer.cancel();
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      _removeDropdown();
      return;
    }

    final qLower = q.toLowerCase();
    final cachedList = ref.read(productListProvider).valueOrNull ?? [];
    if (cachedList.isNotEmpty) {
      final immediateMatches = cachedList.where((p) {
        if (!p.isActive) return false;
        final nameMatch = p.name.toLowerCase().contains(qLower);
        final hindiMatch = p.nameHindi.isNotEmpty && p.nameHindi.toLowerCase().contains(qLower);
        return nameMatch || hindiMatch;
      }).take(10).toList();

      setState(() {
        _searchResults = immediateMatches;
        _isSearching = false;
      });
      if (_searchResults.isNotEmpty || q.isNotEmpty) {
        _showDropdown();
      } else {
        _removeDropdown();
      }
      return;
    }

    setState(() => _isSearching = true);
    _searchDebouncer.run(() async {
      try {
        final results = await ref.read(productServiceProvider).getAll(search: q);
        if (mounted) {
          setState(() {
            _searchResults = results.where((p) => p.isActive).toList();
            _isSearching = false;
          });
          if (_searchResults.isNotEmpty || q.isNotEmpty) {
            _showDropdown();
          } else {
            _removeDropdown();
          }
        }
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _selectProduct(Product product) {
    _removeDropdown();
    final defaultRate = _defaultRates[product.id] ?? 0;
    setState(() {
      _editingProduct = product;
      _editingItem = LineItem(
        productId: product.id,
        productName: product.name,
        productNameHindi: product.nameHindi,
        unit: product.unit.value,
        quantity: 1,
        defaultRate: defaultRate,
        appliedRate: defaultRate,
      );
      _searchResults = [];
      _searchCtrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _qtyFocusNode.requestFocus();
      _qtyCtrl.text = '1';
      _rateCtrl.text = defaultRate > 0 ? AppUtils.formatRate(defaultRate) : '';
      _qtyCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _qtyCtrl.text.length);
    });
  }

  void _confirmEdit() {
    _removeDropdown();
    if (_editingItem == null) return;
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final rate = double.tryParse(_rateCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      _qtyFocusNode.requestFocus();
      return;
    }

    final updated = LineItem(
      productId: _editingItem!.productId,
      productName: _editingItem!.productName,
      productNameHindi: _editingItem!.productNameHindi,
      unit: _editingItem!.unit,
      quantity: qty,
      defaultRate: _editingItem!.defaultRate,
      appliedRate: rate,
    );

    setState(() {
      final existingIndex = _items.indexWhere((i) => i.productId == updated.productId);
      if (existingIndex >= 0) {
        _items[existingIndex] = updated;
      } else {
        _items.add(updated);
      }
      _editingProduct = null;
      _editingItem = null;
      _qtyCtrl.clear();
      _rateCtrl.clear();
    });
    _searchFocusNode.requestFocus();
  }

  void _cancelEdit() {
    _removeDropdown();
    setState(() {
      _editingProduct = null;
      _editingItem = null;
      _qtyCtrl.clear();
      _rateCtrl.clear();
    });
    _searchFocusNode.requestFocus();
  }

  void _editExistingItem(int index) {
    final item = _items[index];
    setState(() {
      _editingProduct = Product(
        id: item.productId ?? '',
        name: item.productName,
        nameHindi: item.productNameHindi,
        unit: ProductUnit.fromString(item.unit),
      );
      _editingItem = item;
      _qtyCtrl.text = item.quantity == item.quantity.roundToDouble()
          ? item.quantity.toStringAsFixed(0)
          : item.quantity.toString();
      _rateCtrl.text = item.appliedRate.toStringAsFixed(2);
      _items.removeAt(index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _qtyFocusNode.requestFocus();
      _qtyCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _qtyCtrl.text.length);
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _clearAll() {
    setState(() {
      _items.clear();
      _selectedCustomer = null;
      _editingProduct = null;
      _editingItem = null;
      _deliveryCharge = 0;
      _qtyCtrl.clear();
      _rateCtrl.clear();
      _searchCtrl.clear();
    });
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.amount);
  double get _total => _subtotal + _deliveryCharge;
  bool get _canProceed => _items.isNotEmpty && !_items.any((i) => i.quantity <= 0);

  Future<void> _pickBillDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _billDate,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Select Slip Date',
      confirmText: 'SELECT',
    );
    if (picked != null) {
      setState(() => _billDate = DateTime(picked.year, picked.month, picked.day, now.hour, now.minute));
      _loadDefaultRates();
    }
  }

  Future<void> _printSlip() async {
    if (!_canProceed || _isPrinting) return;
    if (_editingProduct != null) _confirmEdit();

    setState(() => _isPrinting = true);
    try {
      final settings = await ref.read(settingsProvider.future);
      final customer = _selectedCustomer ??
          const Customer(id: '', name: 'Cash Customer', mobile: '', address: '');
      final billNumber = 'EST-${DateFormat('ddMMyy-HHmm').format(_billDate)}';

      final pdf = await buildBillPdf(
        settings: settings,
        billNumber: billNumber,
        customerName: customer.name,
        customerMobile: customer.mobile,
        customerAddress: customer.address,
        subtotal: _subtotal,
        total: _total,
        deliveryCharge: _deliveryCharge,
        paidNow: _total,
        items: _items,
        billDate: _billDate,
        paymentMode: 'Cash',
        isReprint: false,
        isEstimate: true,
        estimateTitle: _estimateTitle,
      );

      await printPdf(pdf, filename: billNumber);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Slip printed (Not added to sales or khata)'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _shareSlip() async {
    if (!_canProceed || _isPrinting) return;
    if (_editingProduct != null) _confirmEdit();

    setState(() => _isPrinting = true);
    try {
      final settings = await ref.read(settingsProvider.future);
      final customer = _selectedCustomer ??
          const Customer(id: '', name: 'Cash Customer', mobile: '', address: '');
      final billNumber = 'EST-${DateFormat('ddMMyy-HHmm').format(_billDate)}';

      final pdf = await buildBillPdf(
        settings: settings,
        billNumber: billNumber,
        customerName: customer.name,
        customerMobile: customer.mobile,
        customerAddress: customer.address,
        subtotal: _subtotal,
        total: _total,
        deliveryCharge: _deliveryCharge,
        paidNow: _total,
        items: _items,
        billDate: _billDate,
        paymentMode: 'Cash',
        isReprint: false,
        isEstimate: true,
        estimateTitle: _estimateTitle,
      );

      final message = '$_estimateTitle\nCustomer: ${customer.name}\nTotal: ${AppUtils.formatCurrency(_total)}\nDate: ${DateFormat('dd MMM yyyy').format(_billDate)}';
      await sharePdf(pdf, filename: billNumber, message: message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slip ready to share'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dummy Bill'),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryRed),
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: Text(
              DateFormat('dd MMM').format(_billDate),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: _pickBillDate,
          ),
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.grey),
              tooltip: 'Clear Slip',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: Column(
        children: [
          const Breadcrumb(crumbs: [
            Crumb('Home', route: '/dashboard'),
            Crumb('Dummy Bill'),
          ]),

          // ── Module Banner ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_outlined, size: 16, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dummy Bill: No Rathod branding or stamp. Zero impact on sales or khata.',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),

          // ── Heading Selector Chips ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Slip Heading: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  ...['DELIVERY SLIP', 'CASH MEMO', 'ESTIMATE', 'NO HEADING'].map((title) {
                    final isSelected = (title == 'NO HEADING' && _estimateTitle.isEmpty) || _estimateTitle == title;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _estimateTitle = title == 'NO HEADING' ? '' : title;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── Customer Selector (Optional / Walk-in Cash Customer default) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: CustomerSection(
              padding: EdgeInsets.zero,
              customer: _selectedCustomer,
              onSelected: (c) => setState(() => _selectedCustomer = c),
              onCleared: () => setState(() => _selectedCustomer = null),
            ),
          ),

          // ── Product Search Field ──
          Padding(
            key: _searchFieldKey,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: CompositedTransformTarget(
              link: _searchLayerLink,
              child: ProductSearchBar(
                controller: _searchCtrl,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                onSubmitted: (v) {
                  if (_searchResults.length == 1) {
                    _selectProduct(_searchResults.first);
                  }
                },
                isSearching: _isSearching,
              ),
            ),
          ),

          if (_editingProduct != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: ProductEditRow(
                item: _editingItem!,
                qtyCtrl: _qtyCtrl,
                rateCtrl: _rateCtrl,
                qtyFocusNode: _qtyFocusNode,
                rateFocusNode: _rateFocusNode,
                onConfirm: _confirmEdit,
                onCancel: _cancelEdit,
                isWide: isWide,
              ),
            ),

          // ── Items List & Summary ──
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_items.isEmpty && _editingProduct == null)
                    EmptyState(isWide: isWide),
                  if (_items.isNotEmpty || _editingProduct != null)
                    ProductList(
                      items: _items,
                      onEdit: _editExistingItem,
                      onRemove: _removeItem,
                      isWide: isWide,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                    ),
                  SummaryCard(
                    itemCount: _items.length,
                    subtotal: _subtotal,
                    deliveryCharge: _deliveryCharge,
                    onDeliveryChanged: (v) => setState(() => _deliveryCharge = v),
                    total: _total,
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Action Bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_items.length} item${_items.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        Text(
                          AppUtils.formatCurrency(_total),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _canProceed && !_isPrinting ? _shareSlip : null,
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _canProceed && !_isPrinting ? _printSlip : null,
                    icon: _isPrinting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.print, size: 16),
                    label: Text(_isPrinting ? 'Printing...' : 'Print Slip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D3A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
