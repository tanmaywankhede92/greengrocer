import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../core/constants.dart';

class LineItem {
  String? productId;
  String productName;
  String productNameHindi;
  String unit;
  double quantity;
  double defaultRate;
  double appliedRate;

  LineItem({
    this.productId,
    this.productName = '',
    this.productNameHindi = '',
    this.unit = 'kg',
    this.quantity = 1,
    this.defaultRate = 0,
    this.appliedRate = 0,
  });

  double get amount => quantity * appliedRate;

  Map<String, dynamic> toJson() => {
    if (productId != null) 'productId': productId,
    'productName': productName,
    'productNameHindi': productNameHindi,
    'unit': unit,
    'quantity': quantity,
    'defaultRate': defaultRate,
    'appliedRate': appliedRate,
  };
}

class BillItemRow extends StatefulWidget {
  final LineItem item;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final Map<String, double> defaultRates;

  const BillItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
    required this.onChanged,
    this.defaultRates = const {},
  });

  @override
  State<BillItemRow> createState() => _BillItemRowState();
}

class _BillItemRowState extends State<BillItemRow> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _rateCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: widget.item.quantity.toString());
    _rateCtrl = TextEditingController(text: widget.item.appliedRate.toString());
  }

  @override
  void didUpdateWidget(BillItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.quantity != widget.item.quantity) {
      _qtyCtrl.text = widget.item.quantity.toString();
    }
    if (oldWidget.item.appliedRate != widget.item.appliedRate) {
      _rateCtrl.text = widget.item.appliedRate.toString();
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= AppConstants.tabletBreakpoint;

    if (isWide) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(child: Text('${widget.index + 1}', style: TextStyle(color: AppTheme.primaryRed, fontSize: 11, fontWeight: FontWeight.w600))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.item.productName, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
                          if (widget.item.productNameHindi.isNotEmpty)
                            Text(widget.item.productNameHindi, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          Text(widget.item.unit, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Qty', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  onChanged: (v) {
                    widget.item.quantity = double.tryParse(v) ?? 0;
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _rateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rate', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  onChanged: (v) {
                    widget.item.appliedRate = double.tryParse(v) ?? 0;
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                child: Text(AppUtils.formatCurrency(widget.item.amount),
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppTheme.error, size: 18),
                onPressed: widget.onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item.productName, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                      if (widget.item.productNameHindi.isNotEmpty)
                        Text(widget.item.productNameHindi, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      Text(widget.item.unit, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.error, size: 18),
                  onPressed: widget.onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Qty', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    onChanged: (v) {
                      widget.item.quantity = double.tryParse(v) ?? 0;
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _rateCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rate', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    onChanged: (v) {
                      widget.item.appliedRate = double.tryParse(v) ?? 0;
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(AppUtils.formatCurrency(widget.item.amount),
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
