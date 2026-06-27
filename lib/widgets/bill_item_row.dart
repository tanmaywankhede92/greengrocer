import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../models/product.dart';
import 'product_select.dart';

class LineItem {
  String? productId;
  String productName;
  String unit;
  double quantity;
  double defaultRate;
  double appliedRate;

  LineItem({
    this.productId,
    this.productName = '',
    this.unit = 'kg',
    this.quantity = 1,
    this.defaultRate = 0,
    this.appliedRate = 0,
  });

  double get amount => quantity * appliedRate;

  Map<String, dynamic> toJson() => {
    if (productId != null) 'productId': productId,
    'productName': productName,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ProductSelect(
              onSelected: (Product p) {
                widget.item.productId = p.id;
                widget.item.productName = p.name;
                widget.item.unit = p.unit.value;
                final defaultRate = widget.defaultRates[p.id] ?? 0;
                widget.item.defaultRate = defaultRate;
                widget.item.appliedRate = defaultRate;
                _rateCtrl.text = defaultRate.toStringAsFixed(0);
                widget.onChanged();
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Qty'),
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
              decoration: const InputDecoration(labelText: 'Rate'),
              onChanged: (v) {
                widget.item.appliedRate = double.tryParse(v) ?? 0;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(AppUtils.formatCurrency(widget.item.amount),
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.error, size: 18),
            onPressed: widget.onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
