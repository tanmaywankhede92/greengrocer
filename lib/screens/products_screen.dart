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
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showProductForm(context, ref, null)),
        ],
      ),
      body: productsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.error))),
        data: (products) {
          if (products.isEmpty) return const EmptyState(icon: Icons.inventory_outlined, title: 'No products', subtitle: 'Add your first product');
          return ListView.builder(
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
          );
        },
      ),
    );
  }

  void _showProductForm(BuildContext context, WidgetRef ref, dynamic product) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    String unit = product?.unit.value ?? 'kg';
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
                initialValue: unit,
                decoration: const InputDecoration(labelText: 'Unit'),
                dropdownColor: AppTheme.surfaceCard,
                items: ['kg','pcs','bundle','box','dozen','quintal','bag','crate'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(color: AppTheme.textPrimary)))).toList(),
                onChanged: (v) => setDialogState(() => unit = v ?? 'kg'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              try {
                final data = {'name': nameCtrl.text, 'unit': unit};
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
