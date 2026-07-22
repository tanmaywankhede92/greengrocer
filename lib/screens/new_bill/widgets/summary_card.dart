import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../core/utils.dart';

class SummaryCard extends StatelessWidget {
  final int itemCount;
  final double subtotal;
  final double deliveryCharge;
  final ValueChanged<double> onDeliveryChanged;
  final double total;

  const SummaryCard({
    super.key,
    required this.itemCount,
    required this.subtotal,
    required this.deliveryCharge,
    required this.onDeliveryChanged,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row('Subtotal ($itemCount items)', subtotal),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Delivery', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const Spacer(),
              SizedBox(
                width: 90,
                child: TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '0',
                    prefixText: '\u20B9 ',
                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  ),
                  onChanged: (v) => onDeliveryChanged(double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const Divider(height: 14),
          _row('Total', total, bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, double amount, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          AppUtils.formatCurrency(amount),
          style: TextStyle(
            color: bold ? AppTheme.primaryRed : AppTheme.textPrimary,
            fontSize: bold ? 18 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
