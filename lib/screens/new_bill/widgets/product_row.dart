import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils.dart';
import '../../../widgets/bill_item_row.dart';

class ProductRow extends StatelessWidget {
  final LineItem item;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final bool isWide;

  const ProductRow({
    super.key,
    required this.item,
    required this.index,
    required this.onEdit,
    required this.onRemove,
    required this.isWide,
  });

  String get _displayName {
    if (item.productNameHindi.isNotEmpty) {
      return '${item.productName} (${item.productNameHindi})';
    }
    return item.productName;
  }

  String get _formattedQty {
    final qty = item.quantity;
    return qty == qty.roundToDouble() ? qty.toStringAsFixed(0) : qty.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return isWide ? _buildWide() : _buildNarrow();
  }

  Widget _buildWide() {
    return Container(
      decoration: BoxDecoration(
        color: index.isOdd ? const Color(0xFFF5F5F5) : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withAlpha(15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: AppTheme.primaryRed, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_displayName, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                Text(item.unit, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          SizedBox(width: 60, child: Text(_formattedQty, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13), textAlign: TextAlign.center)),
          SizedBox(width: 70, child: Text(item.appliedRate.toStringAsFixed(0), style: TextStyle(color: AppTheme.textPrimary, fontSize: 13), textAlign: TextAlign.center)),
          SizedBox(width: 90, child: Text(AppUtils.formatCurrency(item.amount), style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14), textAlign: TextAlign.right)),
          SizedBox(
            width: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onEdit,
                  child: Icon(Icons.edit, size: 16, color: AppTheme.info),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(Icons.delete_outline, size: 16, color: AppTheme.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrow() {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withAlpha(15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(color: AppTheme.primaryRed, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _displayName,
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  AppUtils.formatCurrency(item.amount),
                  style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _infoChip('Unit', item.unit),
                const SizedBox(width: 6),
                _infoChip('Qty', _formattedQty),
                const SizedBox(width: 6),
                _infoChip('Rate', '\u20B9${item.appliedRate.toStringAsFixed(0)}'),
                const Spacer(),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withAlpha(15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.edit, size: 13, color: AppTheme.info),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withAlpha(15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.delete_outline, size: 13, color: AppTheme.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$label: $value', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
    );
  }
}
