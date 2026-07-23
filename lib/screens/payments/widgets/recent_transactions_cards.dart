import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/utils.dart';
import '../../../models/payment.dart';

class TransactionCard extends StatelessWidget {
  final Payment payment;
  final ValueChanged<Payment> onView;
  final ValueChanged<Payment> onPrint;
  final ValueChanged<Payment> onDownload;
  final String? loadingAction;

  const TransactionCard({
    super.key,
    required this.payment,
    required this.onView,
    required this.onPrint,
    required this.onDownload,
    this.loadingAction,
  });

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final customerName = p.customer?.name ?? 'N/A';
    final isLoadingPrint = loadingAction == 'print_pay_${p.id}';
    final isLoadingDownload = loadingAction == 'dl_pay_${p.id}';
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
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.receipt, size: 14, color: AppTheme.success),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${p.receiptNumber}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(customerName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Text(AppUtils.formatCurrency(p.amount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF2D2D2D))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Chip(Icons.calendar_today, DateFormat('dd MMM yy').format(p.paymentDate)),
                const SizedBox(width: 6),
                _Chip(Icons.access_time, DateFormat('hh:mm a').format(p.paymentDate)),
                const SizedBox(width: 6),
                _Chip(Icons.payment, p.mode.displayName),
              ],
            ),
            const SizedBox(height: 8),
            Container(height: 0.5, color: AppTheme.border),
            const SizedBox(height: 6),
            Row(
              children: [
                _CompactAction(Icons.visibility, 'View', false, () => onView(p)),
                const SizedBox(width: 4),
                _CompactAction(isLoadingPrint ? Icons.hourglass_empty : Icons.print, 'Invoice', isLoadingPrint, isLoadingPrint ? () {} : () => onPrint(p)),
                const SizedBox(width: 4),
                _CompactAction(isLoadingDownload ? Icons.hourglass_empty : Icons.download, 'Invoice', isLoadingDownload, isLoadingDownload ? () {} : () => onDownload(p)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppTheme.textSecondary),
          const SizedBox(width: 3),
          Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
        ],
      ),
    );
  }
}

class _CompactAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  const _CompactAction(this.icon, this.label, this.isLoading, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        icon: isLoading
            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, size: 12),
        label: Text(label, style: const TextStyle(fontSize: 10)),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
