import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils.dart';
import '../../../models/customer.dart';
import 'status_badge.dart';

class CustomerOutstandingCard extends StatelessWidget {
  final Customer customer;
  final ValueChanged<Customer> onPay;
  final ValueChanged<Customer> onStatement;
  final ValueChanged<Customer> onInvoice;
  final ValueChanged<Customer> onShare;
  final ValueChanged<Customer> onViewLedger;
  final String? loadingAction;

  const CustomerOutstandingCard({
    super.key,
    required this.customer,
    required this.onPay,
    required this.onStatement,
    required this.onInvoice,
    required this.onShare,
    required this.onViewLedger,
    this.loadingAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final isInvLoading = loadingAction == 'inv_${c.id}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryRed.withAlpha(25),
                  child: Text(
                    AppUtils.initials(c.name),
                    style: const TextStyle(color: AppTheme.primaryRed, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(c.mobile, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                StatusBadge.fromCustomer(currentDue: c.currentDue, totalPaid: c.totalPaid, compact: true),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _CompactAmt('Due', c.currentDue, AppTheme.error),
                const SizedBox(width: 20),
                _CompactAmt('Paid', c.totalPaid, AppTheme.success),
              ],
            ),
            const SizedBox(height: 8),
            Container(height: 0.5, color: AppTheme.border),
            const SizedBox(height: 6),
            Row(
              children: [
                if (c.currentDue > 0) ...[
                  _CompactBtn(Icons.payments, 'Pay', AppTheme.primaryRed, false, () => onPay(c)),
                  const SizedBox(width: 4),
                ],
                _CompactBtn(Icons.description_outlined, 'Stmt', AppTheme.info, false, () => onStatement(c)),
                const SizedBox(width: 4),
                _CompactBtn(isInvLoading ? Icons.hourglass_empty : Icons.receipt_long, 'Inv', AppTheme.textSecondary, isInvLoading, isInvLoading ? () {} : () => onInvoice(c)),
                const SizedBox(width: 4),
                _CompactBtn(Icons.share, 'Share', AppTheme.info, false, () => onShare(c)),
                const SizedBox(width: 4),
                _CompactBtn(Icons.account_balance, 'Ledger', AppTheme.primaryRedDark, false, () => onViewLedger(c)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactAmt extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _CompactAmt(this.label, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        Text(AppUtils.formatCurrency(amount), style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }
}

class _CompactBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;
  const _CompactBtn(this.icon, this.label, this.color, this.isLoading, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        icon: isLoading
            ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: color))
            : Icon(icon, size: 12),
        label: Text(label, style: const TextStyle(fontSize: 10)),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          visualDensity: VisualDensity.compact,
          side: BorderSide(color: color.withAlpha(80)),
          foregroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}
