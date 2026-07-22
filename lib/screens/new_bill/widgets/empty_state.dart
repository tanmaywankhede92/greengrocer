import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class EmptyState extends StatelessWidget {
  final bool isWide;
  const EmptyState({super.key, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_shopping_cart_rounded, size: 72, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            Text('Search products to add', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Type product name in Hindi or English', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            if (isWide) ...[
              const SizedBox(height: 28),
              const _KeyboardShortcuts(),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeyboardShortcuts extends StatelessWidget {
  const _KeyboardShortcuts();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Keyboard Shortcuts', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _row('Search', 'Type product name'),
          _row('Qty \u2192 Rate', 'Tab or Enter'),
          _row('Save item', 'Enter on Rate'),
          _row('Cancel edit', 'Esc'),
        ],
      ),
    );
  }

  Widget _row(String key, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(key, style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(action, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }
}
