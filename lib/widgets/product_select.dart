import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

class ProductSelect extends ConsumerStatefulWidget {
  final ValueChanged<Product> onSelected;
  const ProductSelect({super.key, required this.onSelected});

  @override
  ConsumerState<ProductSelect> createState() => _ProductSelectState();
}

class _ProductSelectState extends ConsumerState<ProductSelect> {
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  Future<void> _loadProducts() async {
    final list = await ref.read(allProductsProvider.future);
    if (mounted) setState(() { _products = list.where((p) => p.isActive).toList(); });
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Product>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return [];
        return _products.where((p) =>
            p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      displayStringForOption: (p) => p.name,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            hintText: 'Product...',
            suffixIcon: Icon(Icons.search, size: 18),
          ),
          onEditingComplete: onSubmitted,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Container(
            width: 320,
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final p = options.elementAt(index);
                return ListTile(
                  dense: true,
                  title: Text(p.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                  subtitle: Text(p.unit.value, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  onTap: () {
                    onSelected(p);
                    widget.onSelected(p);
                  },
                );
              },
            ),
          ),
        );
      },
      onSelected: (p) => widget.onSelected(p),
    );
  }
}
