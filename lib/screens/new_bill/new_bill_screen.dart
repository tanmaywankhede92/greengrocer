import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../core/utils.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/rate_provider.dart';
import '../../widgets/breadcrumb.dart';
import '../../widgets/bill_item_row.dart';
import 'widgets/customer_section.dart';
import 'widgets/product_search_bar.dart';
import 'widgets/product_edit_row.dart';
import 'widgets/product_list.dart';
import 'widgets/empty_state.dart';
import 'widgets/bottom_bar.dart';
import 'widgets/summary_card.dart';
import '../bill_preview_screen.dart';

class NewBillScreen extends ConsumerStatefulWidget {
  const NewBillScreen({super.key});
  @override
  ConsumerState<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends ConsumerState<NewBillScreen> {
  Customer? _selectedCustomer;
  final List<LineItem> _items = [];
  double _deliveryCharge = 0;
  Map<String, double> _defaultRates = {};

  final _searchCtrl = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _searchFieldKey = GlobalKey();
  final _qtyCtrl = TextEditingController();
  final _qtyFocusNode = FocusNode();
  final _rateCtrl = TextEditingController();
  final _rateFocusNode = FocusNode();
  final _deliveryChargeCtrl = TextEditingController();

  List<Product> _searchResults = [];
  bool _isSearching = false;

  Product? _editingProduct;
  LineItem? _editingItem;

  OverlayEntry? _dropdownOverlay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _removeDropdown();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _qtyCtrl.dispose();
    _qtyFocusNode.dispose();
    _rateCtrl.dispose();
    _rateFocusNode.dispose();
    _deliveryChargeCtrl.dispose();
    super.dispose();
  }

  void _showDropdown() {
    _removeDropdown();
    final RenderBox? renderBox =
        _searchFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;
    final position = renderBox.localToGlobal(Offset.zero);
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
          Positioned(
            left: position.dx,
            top: position.dy + size.height + 4,
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
                  _addProduct();
                },
                searchQuery: _searchCtrl.text.trim(),
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

  void _onSearchChanged(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      _removeDropdown();
      return;
    }
    setState(() => _isSearching = true);
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
  }

  void _selectProduct(Product product) {
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

    _removeDropdown();
    _qtyCtrl.text = '1';
    _rateCtrl.text = defaultRate > 0 ? defaultRate.toStringAsFixed(0) : '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _qtyFocusNode.requestFocus();
        _qtyCtrl.selection =
            TextSelection(baseOffset: 0, extentOffset: _qtyCtrl.text.length);
      }
    });
  }

  void _confirmEdit() {
    if (_editingItem == null || _editingProduct == null) return;

    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    if (qty <= 0) {
      _qtyFocusNode.requestFocus();
      return;
    }

    setState(() {
      _editingItem!.quantity = qty;
      _editingItem!.appliedRate = rate;
      _items.add(_editingItem!);
      _editingProduct = null;
      _editingItem = null;
    });

    _searchFocusNode.requestFocus();
  }

  void _cancelEdit() {
    _removeDropdown();
    setState(() {
      _editingProduct = null;
      _editingItem = null;
    });
    _searchFocusNode.requestFocus();
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _editExistingItem(int index) {
    final item = _items[index];
    final product = Product(
      id: item.productId ?? '',
      name: item.productName,
      nameHindi: item.productNameHindi,
      unit: ProductUnit.fromString(item.unit),
    );
    final savedUnit = item.unit;
    _selectProduct(product);
    setState(() {
      _items.removeAt(index);
      _editingItem!.unit = savedUnit;
    });
  }

  Future<void> _loadDefaultRates() async {
    try {
      final rateService = ref.read(rateServiceProvider);
      final rates = await rateService.getByDate(DateTime.now());
      if (mounted) {
        setState(() {
          _defaultRates =
              rates.map((key, value) => MapEntry(key, value.rate));
        });
      }
    } catch (_) {}
  }

  Future<void> _addProduct() async {
    final newProduct = await AddProductDialog.show(
      context,
      initialName: _searchCtrl.text.trim(),
    );
    if (newProduct != null && mounted) {
      _selectProduct(newProduct);
    }
  }

  void _goToPreview() {
    if (_selectedCustomer == null) return;
    if (_editingProduct != null) _confirmEdit();
    if (_items.isEmpty ||
        _items.any((i) => i.productName.isEmpty || i.quantity <= 0)) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillPreviewScreen(
          customer: _selectedCustomer!,
          items: List.from(_items),
          deliveryCharge: _deliveryCharge,
        ),
      ),
    );
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.amount);
  double get _total => _subtotal + _deliveryCharge;
  bool get _canProceed =>
      _selectedCustomer != null &&
      _items.isNotEmpty &&
      !_items.any((i) => i.quantity <= 0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppConstants.tabletBreakpoint;
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Scaffold(
            appBar: _buildAppBar(),
            body: _buildBody(isWide),
            resizeToAvoidBottomInset: true,
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/bills'),
      ),
      title: const Text('New Bill'),
      actions: [
        if (_items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_items.length} items  \u2022  ${AppUtils.formatCurrency(_total)}',
                  style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(bool isWide) {
    return Column(
      children: [
        const Breadcrumb(crumbs: [
          Crumb('Home', route: '/dashboard'),
          Crumb('Bills', route: '/bills'),
          Crumb('New Bill'),
        ]),
        CustomerSection(
          customer: _selectedCustomer,
          onSelected: (c) {
            setState(() => _selectedCustomer = c);
            _loadDefaultRates();
          },
          onCleared: () => setState(() => _selectedCustomer = null),
        ),
        Padding(
          key: _searchFieldKey,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
        if (_editingProduct != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
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
                  onDeliveryChanged: (v) =>
                      setState(() => _deliveryCharge = v),
                  total: _total,
                ),
              ],
            ),
          ),
        ),
        BottomBar(
          itemCount: _items.length,
          total: _total,
          allItemsValid: _canProceed,
          onSave: _goToPreview,
          isWide: isWide,
          canSave: _canProceed,
        ),
      ],
    );
  }
}
