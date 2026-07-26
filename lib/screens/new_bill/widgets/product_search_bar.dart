import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/enums.dart';
import '../../../models/product.dart';
import '../../../services/product_service.dart';
import '../../../services/api_client.dart';

class ProductSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final bool isSearching;

  const ProductSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search product...',
        prefixIcon: isSearching
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Icon(Icons.search, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primaryRed, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onSubmitted: onSubmitted,
    );
  }
}

class AddProductDialog extends StatefulWidget {
  final String initialName;
  const AddProductDialog({super.key, this.initialName = ''});

  static Future<Product?> show(BuildContext context, {String initialName = ''}) {
    return showDialog<Product>(
      context: context,
      builder: (_) => AddProductDialog(initialName: initialName),
    );
  }

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _nameHindiCtrl;
  late final TextEditingController _customUnitCtrl;
  bool _saving = false;
  String _selectedUnit = 'kg';
  bool _isCustom = false;

  static const _commonUnits = ['kg', 'pcs', 'bundle', 'bunch', 'box', 'dozen', 'quintal', 'bag', 'crate'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _nameHindiCtrl = TextEditingController();
    _customUnitCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameHindiCtrl.dispose();
    _customUnitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Product'),
      content: StatefulBuilder(
        builder: (ctx, setDialogState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Product Name *'),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameHindiCtrl,
                  decoration: const InputDecoration(labelText: 'Hindi Name'),
                  textCapitalization: TextCapitalization.none,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _isCustom ? 'custom' : _selectedUnit,
                  decoration: const InputDecoration(labelText: 'Unit *'),
                  items: [
                    ..._commonUnits.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(color: AppTheme.textPrimary)))),
                    const DropdownMenuItem(value: 'custom', child: Text('Custom...', style: TextStyle(color: AppTheme.primaryRed, fontStyle: FontStyle.italic))),
                  ],
                  onChanged: (v) => setDialogState(() {
                    if (v == 'custom') {
                      _isCustom = true;
                      _selectedUnit = 'custom';
                    } else {
                      _isCustom = false;
                      _selectedUnit = v ?? 'kg';
                    }
                  }),
                ),
                if (_isCustom) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customUnitCtrl,
                    decoration: const InputDecoration(labelText: 'Custom Unit', hintText: 'e.g. tin, potli, gaddi'),
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final finalUnit = _isCustom ? _customUnitCtrl.text.trim() : _selectedUnit;
    if (finalUnit.isEmpty) return;
    setState(() => _saving = true);
    try {
      final service = ProductService();
      final id = await service.create({
        'name': _nameCtrl.text.trim(),
        'nameHindi': _nameHindiCtrl.text.trim(),
        'unit': finalUnit,
      });
      if (mounted) {
        Navigator.pop(
          context,
          Product(
            id: id,
            name: _nameCtrl.text.trim(),
            nameHindi: _nameHindiCtrl.text.trim(),
            unit: ProductUnit.fromString(finalUnit),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.humanizeError(e)), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class ProductSearchDropdown extends StatelessWidget {
  final List<Product> results;
  final Map<String, double> defaultRates;
  final ValueChanged<Product> onSelected;
  final VoidCallback onAddProduct;
  final String searchQuery;

  const ProductSearchDropdown({
    super.key,
    required this.results,
    required this.defaultRates,
    required this.onSelected,
    required this.onAddProduct,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 260),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (results.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final p = results[index];
                    return InkWell(
                      onTap: () => onSelected(p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: index < results.length - 1
                              ? const Border(bottom: BorderSide(color: AppTheme.border, width: 0.5))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRed.withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2, color: AppTheme.primaryRed, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.nameHindi.isNotEmpty ? '${p.name} (${p.nameHindi})' : p.name,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  _buildSubtitle(p),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (searchQuery.isNotEmpty)
              InkWell(
                onTap: onAddProduct,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: results.isNotEmpty
                      ? const BoxDecoration(
                          border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
                        )
                      : null,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.success.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_circle_outline, color: AppTheme.success, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add new product',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '"$searchQuery"',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.add, size: 18, color: AppTheme.success),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(Product p) {
    return Row(
      children: [
        Text(
          'Unit: ${p.unit.value}',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        if (defaultRates.containsKey(p.id)) ...[
          Text(
            '  \u2022  ',
            style: TextStyle(color: AppTheme.textSecondary.withAlpha(100), fontSize: 12),
          ),
          Text(
            'Rate: \u20B9${defaultRates[p.id]!.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppTheme.primaryRed,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
