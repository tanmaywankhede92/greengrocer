import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../core/enums.dart';
import '../../../core/utils.dart';
import '../../../widgets/payment_mode_select.dart';

class PaymentSection extends StatelessWidget {
  final double total;
  final double paymentAmount;
  final ValueChanged<double> onAmountChanged;
  final PaymentMode paymentMode;
  final ValueChanged<PaymentMode?> onModeChanged;

  const PaymentSection({
    super.key,
    required this.total,
    required this.paymentAmount,
    required this.onAmountChanged,
    required this.paymentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final balance = total - paymentAmount;
    final isPaid = balance <= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Payment', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Amount Paid',
              prefixIcon: Icon(Icons.currency_rupee, size: 14),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onChanged: (v) => onAmountChanged(double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 6),
          PaymentModeSelect(value: paymentMode, onChanged: onModeChanged),
          if (paymentAmount > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Balance', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                Text(
                  isPaid ? 'Paid \u2713' : 'Due: ${AppUtils.formatCurrency(balance)}',
                  style: TextStyle(
                    color: isPaid ? AppTheme.success : AppTheme.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
