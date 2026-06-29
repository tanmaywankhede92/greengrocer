import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/product_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: productsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.error))),
        data: (products) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Product'),
                    onPressed: () => _showProductForm(context, ref, null),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ),
              Expanded(child: products.isEmpty
                ? const EmptyState(icon: Icons.inventory_outlined, title: 'No products', subtitle: 'Add your first product')
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];
                      return Card(
                        child: ListTile(
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: p.isActive ? AppTheme.primaryGreen.withAlpha(40) : Colors.grey.withAlpha(40),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.inventory_2, color: p.isActive ? AppTheme.primaryGreenLight : AppTheme.textSecondary, size: 22),
                          ),
                          title: Text(p.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                          subtitle: Text(p.unit.value, style: const TextStyle(color: AppTheme.textSecondary)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: p.isActive,
                                activeThumbColor: AppTheme.primaryGreen,
                                onChanged: (v) async {
                                  try {
                                    await ref.read(productServiceProvider).toggleActive(p.id, v);
                                    ref.invalidate(allProductsProvider);
                                    ref.invalidate(productListProvider);
                                  } catch (e) {
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _showProductForm(context, ref, p),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )),
            ],
          );
        },
      ),
    );
  }

  static const _commonUnits = ['kg','pcs','bundle','box','dozen','quintal','bag','crate'];

  void _showProductForm(BuildContext context, WidgetRef ref, dynamic product) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: isCustom ? 'custom' : unit,
                decoration: const InputDecoration(labelText: 'Quantity Type'),
                dropdownColor: AppTheme.surfaceCard,
                items: [..._commonUnits.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(color: AppTheme.textPrimary)))), const DropdownMenuItem(value: 'custom', child: Text('Custom...', style: TextStyle(color: AppTheme.primaryGreenLight, fontStyle: FontStyle.italic)))],
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
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final finalUnit = isCustom ? customUnitCtrl.text.trim() : unit;
              if (finalUnit.isEmpty) return;
              try {
                final data = {'name': nameCtrl.text, 'unit': finalUnit};
                if (product == null) {
                  await ref.read(productServiceProvider).create(data);
                } else {
                  await ref.read(productServiceProvider).update(product.id, data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(allProductsProvider);
                ref.invalidate(productListProvider);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
