import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/product.dart';

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
      decoration: InputDecoration(
        hintText: 'Search product... (Hindi or English)',
        prefixIcon: isSearching
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20, height: 20,
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
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onSubmitted: onSubmitted,
    );
  }
}

class ProductSearchDropdown extends StatelessWidget {
  final List<Product> results;
  final Map<String, double> defaultRates;
  final ValueChanged<Product> onSelected;

  const ProductSearchDropdown({
    super.key,
    required this.results,
    required this.defaultRates,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: results.length,
        itemBuilder: (context, index) {
          final p = results[index];
          return ListTile(
            dense: true,
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2, color: AppTheme.primaryRed, size: 18),
            ),
            title: Text(
              p.nameHindi.isNotEmpty ? '${p.name} (${p.nameHindi})' : p.name,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: _buildSubtitle(p),
            onTap: () => onSelected(p),
          );
        },
      ),
    );
  }

  Widget _buildSubtitle(Product p) {
    return Row(
      children: [
        Text('Unit: ${p.unit.value}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        if (defaultRates.containsKey(p.id)) ...[
          Text('  \u2022  ', style: TextStyle(color: AppTheme.textSecondary.withAlpha(100), fontSize: 12)),
          Text(
            'Rate: \u20B9${defaultRates[p.id]!.toStringAsFixed(0)}',
            style: TextStyle(color: AppTheme.primaryRed, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }
}
