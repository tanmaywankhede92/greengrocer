import 'package:flutter/material.dart';
import '../../../widgets/bill_item_row.dart';
import 'product_row.dart';

class ProductList extends StatelessWidget {
  final List<LineItem> items;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;
  final bool isWide;

  const ProductList({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onRemove,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return isWide ? _buildWide() : _buildNarrow();
  }

  Widget _buildWide() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF37474F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const Row(
            children: [
              SizedBox(
                  width: 36,
                  child: Text('#',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      textAlign: TextAlign.center)),
              Expanded(
                  child: Text('Product',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
              SizedBox(
                  width: 60,
                  child: Text('Qty',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      textAlign: TextAlign.center)),
              SizedBox(
                  width: 70,
                  child: Text('Rate',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      textAlign: TextAlign.center)),
              SizedBox(
                  width: 90,
                  child: Text('Amount',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      textAlign: TextAlign.right)),
              SizedBox(
                  width: 72,
                  child: Text('Actions',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      textAlign: TextAlign.center)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < items.length; i++)
                ProductRow(
                  item: items[i],
                  index: i,
                  onEdit: () => onEdit(i),
                  onRemove: () => onRemove(i),
                  isWide: true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrow() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: items.length,
      itemBuilder: (context, index) => ProductRow(
        item: items[index],
        index: index,
        onEdit: () => onEdit(index),
        onRemove: () => onRemove(index),
        isWide: false,
      ),
    );
  }
}
