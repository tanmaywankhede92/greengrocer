import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<Product>? _searchResults;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    try {
      final results = await ref.read(productServiceProvider).getAll(activeOnly: true, search: q);
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Product'),
              onPressed: () => _showProductForm(context, ref, null),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _searchFocusNode.requestFocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: productsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppTheme.error.withAlpha(150)),
                      const SizedBox(height: 16),
                      const Text('Failed to load products', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('$e', style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              data: (products) {
                final display = _searchResults ?? products;
                if (display.isEmpty) {
                  return const EmptyState(icon: Icons.inventory_outlined, title: 'No products', subtitle: 'Add your first product');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: display.length,
                  itemBuilder: (context, index) {
                    final p = display[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: p.isActive ? AppTheme.primaryRed.withAlpha(20) : Colors.grey.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.inventory_2, color: p.isActive ? AppTheme.primaryRed : AppTheme.textSecondary, size: 22),
                        ),
                        title: Text(p.nameHindi.isNotEmpty ? '${p.name} (${p.nameHindi})' : p.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                        subtitle: Text(p.unit.value, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: p.isActive,
                              onChanged: (v) async {
                                try {
                                  await ref.read(productServiceProvider).toggleActive(p.id, v);
                                  ref.invalidate(allProductsProvider);
                                  ref.invalidate(productListProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: AppTheme.textSecondary),
                              onPressed: () => _showProductForm(context, ref, p),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const _commonUnits = ['kg','pcs','bundle','box','dozen','quintal','bag','crate'];

  void _showProductForm(BuildContext context, WidgetRef ref, Product? product) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final nameHindiCtrl = TextEditingController(text: product?.nameHindi ?? '');
    final customUnitCtrl = TextEditingController();
    String unit = product?.unit.value ?? 'kg';
    bool isCustom = !_commonUnits.contains(unit);
    if (isCustom) {
      customUnitCtrl.text = unit;
      unit = '';
    }
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(product == null ? 'Add Product' : 'Edit Product'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (English) *', prefixIcon: Icon(Icons.text_fields, size: 18))),
                  const SizedBox(height: 12),
                  TextField(controller: nameHindiCtrl, decoration: const InputDecoration(labelText: 'Name (Hindi)', prefixIcon: Icon(Icons.translate, size: 18), hintText: 'e.g. आलू, टमाटर')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: isCustom ? 'custom' : unit,
                    decoration: const InputDecoration(labelText: 'Unit', prefixIcon: Icon(Icons.scale, size: 18)),
                    items: [
                      ..._commonUnits.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(color: AppTheme.textPrimary)))),
                      const DropdownMenuItem(value: 'custom', child: Text('Custom...', style: TextStyle(color: AppTheme.primaryRed, fontStyle: FontStyle.italic))),
                    ],
                    onChanged: (v) => setDialogState(() {
                      if (v == 'custom') {
                        isCustom = true;
                        unit = '';
                      } else {
                        isCustom = false;
                        unit = v ?? 'kg';
                      }
                    }),
                  ),
                  if (isCustom) ...[
                    const SizedBox(height: 12),
                    TextField(controller: customUnitCtrl, decoration: const InputDecoration(labelText: 'Custom Unit', hintText: 'e.g. tin, potli, gaddi')),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final finalUnit = isCustom ? customUnitCtrl.text.trim() : unit;
              if (finalUnit.isEmpty) return;
              try {
                final data = {'name': nameCtrl.text, 'nameHindi': nameHindiCtrl.text.trim(), 'unit': finalUnit};
                if (product == null) {
                  await ref.read(productServiceProvider).create(data);
                } else {
                  await ref.read(productServiceProvider).update(product.id, data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(allProductsProvider);
                ref.invalidate(productListProvider);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            }, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
