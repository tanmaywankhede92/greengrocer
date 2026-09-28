import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../core/utils.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/draft_bill.dart';
import '../../providers/bill_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/rate_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/breadcrumb.dart';
import '../../widgets/bill_item_row.dart';
import 'widgets/customer_section.dart';
import 'widgets/product_search_bar.dart';
import 'widgets/product_edit_row.dart';
import 'widgets/product_list.dart';
import 'widgets/empty_state.dart';
import 'widgets/bottom_bar.dart';
import 'widgets/summary_card.dart';

class NewBillScreen extends ConsumerStatefulWidget {
  final DraftBill? initialDraft;
  const NewBillScreen({super.key, this.initialDraft});
  @override
  ConsumerState<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends ConsumerState<NewBillScreen> {
  Customer? _selectedCustomer;
  final List<LineItem> _items = [];
  double _deliveryCharge = 0;
  Map<String, double> _defaultRates = {};
  String? _draftId;
  String? _draftMongoId;
  bool _isSavingDraft = false;

  final _searchCtrl = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _searchFieldKey = GlobalKey();
  final _searchLayerLink = LayerLink();
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
    if (widget.initialDraft != null) {
      final draft = widget.initialDraft!;
      _draftId = draft.draftId;
      _draftMongoId = draft.id;
      _selectedCustomer = draft.toCustomer();
      _items.addAll(draft.items.map((i) => LineItem(
        productId: i.productId,
        productName: i.productName,
        productNameHindi: i.productNameHindi,
        unit: i.unit,
        quantity: i.quantity,
        defaultRate: i.defaultRate,
        appliedRate: i.appliedRate,
      )));
      _deliveryCharge = draft.deliveryCharge;
      if (_deliveryCharge > 0) {
        _deliveryChargeCtrl.text = _deliveryCharge.toStringAsFixed(0);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_selectedCustomer != null) {
          _loadDefaultRates();
        }
        _searchFocusNode.requestFocus();
      }
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
                  _addProduct();
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

    context.push('/bills/preview', extra: {
      'customer': _selectedCustomer!,
      'items': List.from(_items),
      'deliveryCharge': _deliveryCharge,
      if (_draftId != null && _draftId!.isNotEmpty) 'draftId': _draftId,
    });
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.amount);
  double get _total => _subtotal + _deliveryCharge;
  bool get _canProceed =>
      _selectedCustomer != null &&
      _items.isNotEmpty &&
      !_items.any((i) => i.quantity <= 0);

  bool get _hasUnsavedData =>
      _items.isNotEmpty || _selectedCustomer != null || _editingProduct != null;

  Future<void> _saveDraft({bool navigateBack = true}) async {
    if (_isSavingDraft) return;
    setState(() => _isSavingDraft = true);

    try {
      if (_editingProduct != null) {
        final qty = double.tryParse(_qtyCtrl.text) ?? 0;
        final rate = double.tryParse(_rateCtrl.text) ?? 0;
        if (qty > 0) {
          _editingItem!.quantity = qty;
          _editingItem!.appliedRate = rate;
          _items.add(_editingItem!);
          _editingProduct = null;
          _editingItem = null;
        }
      }

      final billService = ref.read(billServiceProvider);
      final payload = {
        if (_draftMongoId != null && _draftMongoId!.isNotEmpty) 'id': _draftMongoId,
        if (_draftId != null && _draftId!.isNotEmpty) 'draftId': _draftId,
        'customerId': _selectedCustomer?.id,
        'customerName': _selectedCustomer?.name ?? '',
        'customerMobile': _selectedCustomer?.mobile ?? '',
        'customerAddress': _selectedCustomer?.address ?? '',
        'billDate': AppUtils.formatDateApi(DateTime.now()),
        'items': _items.map((i) => i.toJson()).toList(),
        'deliveryCharge': _deliveryCharge,
        'notes': '',
      };

      final saved = await billService.saveDraft(payload);
      _draftId = saved.draftId;
      _draftMongoId = saved.id;

      ref.invalidate(draftListProvider);
      ref.invalidate(draftCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill saved as draft (${saved.draftId})'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 3),
          ),
        );
        if (navigateBack) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/bills');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save draft: ${ApiClient.humanizeError(e)}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingDraft = false);
    }
  }

  Future<void> _handleBack() async {
    if (!_hasUnsavedData) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/bills');
      }
      return;
    }

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.drafts_outlined, color: AppTheme.primaryRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Save this bill as Draft?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'You have unsaved bill items or details. Would you like to save this bill as a draft to continue later without losing your work?',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop('cancel'),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop('discard'),
            child: const Text('Discard'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save Draft'),
            onPressed: () => Navigator.of(dialogCtx).pop('save'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (action == 'discard') {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/bills');
      }
    } else if (action == 'save') {
      await _saveDraft(navigateBack: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppConstants.tabletBreakpoint;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBack();
          },
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: Scaffold(
              appBar: _buildAppBar(),
              body: _buildBody(isWide),
              resizeToAvoidBottomInset: true,
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _handleBack,
      ),
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('New Bill'),
            if (_draftId != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade700, width: 0.8),
                ),
                child: Text(
                  'Draft: $_draftId',
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_hasUnsavedData)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryRed,
                side: const BorderSide(color: AppTheme.primaryRed),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(0, 36),
              ),
              icon: _isSavingDraft
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRed),
                    )
                  : const Icon(Icons.save_outlined, size: 16),
              label: Text(_isSavingDraft ? 'Saving...' : 'Save Draft', style: const TextStyle(fontSize: 13)),
              onPressed: _isSavingDraft ? null : () => _saveDraft(navigateBack: false),
            ),
          ),
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
