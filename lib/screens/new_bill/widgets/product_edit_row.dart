import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../core/utils.dart';
import '../../../widgets/bill_item_row.dart';

class ProductEditRow extends StatefulWidget {
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

  @override
  State<ProductEditRow> createState() => _ProductEditRowState();
}

class _ProductEditRowState extends State<ProductEditRow> {
  String get _displayName {
    if (widget.item.productNameHindi.isNotEmpty) {
      return '${widget.item.productName} (${widget.item.productNameHindi})';
    }
    return widget.item.productName;
  }

  double get _amount => widget.item.quantity * widget.item.appliedRate;

  @override
  Widget build(BuildContext context) {
    return widget.isWide ? _buildWide() : _buildNarrow();
  }

  Widget _buildWide() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withAlpha(8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryRed.withAlpha(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _displayName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Unit: ${widget.item.unit}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: widget.qtyCtrl,
                  focusNode: widget.qtyFocusNode,
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
                  onSubmitted: (_) => widget.rateFocusNode.requestFocus(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 85,
                child: TextField(
                  controller: widget.rateCtrl,
                  focusNode: widget.rateFocusNode,
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
                  onSubmitted: (_) => widget.onConfirm(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text(
                  AppUtils.formatCurrency(_amount),
                  style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  icon: const Icon(Icons.check_circle, color: AppTheme.success, size: 22),
                  onPressed: widget.onConfirm,
                  tooltip: 'Add Product',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade400, size: 18),
                  onPressed: widget.onCancel,
                  tooltip: 'Cancel',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
            ],
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
                      Text(
                        _displayName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Unit: ${widget.item.unit}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: widget.onCancel,
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
                    controller: widget.qtyCtrl,
                    focusNode: widget.qtyFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Qty',
                      labelText: 'Qty',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => widget.rateFocusNode.requestFocus(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.rateCtrl,
                    focusNode: widget.rateFocusNode,
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
                    onSubmitted: (_) => widget.onConfirm(),
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
                  style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Add'),
                  onPressed: widget.onConfirm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
