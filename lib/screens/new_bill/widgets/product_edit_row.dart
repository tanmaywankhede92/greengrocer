import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../core/utils.dart';
import '../../../widgets/bill_item_row.dart';

class ProductEditRow extends StatelessWidget {
  final LineItem item;
  final TextEditingController qtyCtrl;
  final TextEditingController rateCtrl;
  final FocusNode qtyFocusNode;
  final FocusNode rateFocusNode;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isWide;

  const ProductEditRow({
    super.key,
    required this.item,
    required this.qtyCtrl,
    required this.rateCtrl,
    required this.qtyFocusNode,
    required this.rateFocusNode,
    required this.onConfirm,
    required this.onCancel,
    required this.isWide,
  });

  String get _displayName {
    if (item.productNameHindi.isNotEmpty) {
      return '${item.productName} (${item.productNameHindi})';
    }
    return item.productName;
  }

  double get _amount => item.quantity * item.appliedRate;

  @override
  Widget build(BuildContext context) {
    return isWide ? _buildWide() : _buildNarrow();
  }

  Widget _buildWide() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withAlpha(8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryRed.withAlpha(40)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_displayName, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                Text(item.unit, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          SizedBox(
            width: 65,
            child: TextField(
              controller: qtyCtrl,
              focusNode: qtyFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Qty',
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => rateFocusNode.requestFocus(),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 75,
            child: TextField(
              controller: rateCtrl,
              focusNode: rateFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Rate',
                prefixText: '\u20B9 ',
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => onConfirm(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              AppUtils.formatCurrency(_amount),
              style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 36, height: 36,
            child: IconButton(
              icon: const Icon(Icons.check_circle, color: AppTheme.success, size: 22),
              onPressed: onConfirm,
              tooltip: 'Save (Enter)',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
          SizedBox(
            width: 36, height: 36,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.grey.shade400, size: 18),
              onPressed: onCancel,
              tooltip: 'Cancel (Esc)',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrow() {
    return Card(
      color: AppTheme.primaryRed.withAlpha(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_displayName, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                      Text(item.unit, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 36, height: 36,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onCancel,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    focusNode: qtyFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Qty',
                      labelText: 'Qty',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => rateFocusNode.requestFocus(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: rateCtrl,
                    focusNode: rateFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Rate',
                      labelText: 'Rate',
                      prefixText: '\u20B9 ',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => onConfirm(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppUtils.formatCurrency(_amount),
                  style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Add'),
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
