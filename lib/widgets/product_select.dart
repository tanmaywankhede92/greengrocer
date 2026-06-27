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
  final _controller = TextEditingController();
  List<Product> _products = [];
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final list = await ref.read(allProductsProvider.future);
    if (mounted) setState(() { _products = list.where((p) => p.isActive).toList(); });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Product...',
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () { _controller.clear(); setState(() => _showDropdown = false); },
                  )
                : const Icon(Icons.search, size: 18),
          ),
          onChanged: (v) => setState(() => _showDropdown = v.isNotEmpty),
        ),
        if (_showDropdown && _products.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade700),
            ),
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final p = _products[index];
                final match = p.name.toLowerCase().contains(_controller.text.toLowerCase());
                if (!match) return const SizedBox.shrink();
                return ListTile(
                  dense: true,
                  title: Text(p.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                  subtitle: Text(p.unit.value, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  onTap: () {
                    _controller.text = p.name;
                    setState(() => _showDropdown = false);
                    widget.onSelected(p);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
