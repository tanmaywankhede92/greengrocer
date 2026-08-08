import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/utils.dart';
import '../../../models/payment.dart';

class RecentTransactionsTable extends StatelessWidget {
  final List<Payment> payments;
  final ValueChanged<Payment> onView;
  final ValueChanged<Payment> onPrint;
  final ValueChanged<Payment> onDownload;
  final ValueChanged<Payment> onShare;
  final String? loadingAction;

  const RecentTransactionsTable({
    super.key,
    required this.payments,
    required this.onView,
    required this.onPrint,
    required this.onDownload,
    required this.onShare,
    this.loadingAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF1E2330),
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 18, child: Text('Receipt No', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
              Expanded(flex: 12, child: Text('Date', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
              Expanded(flex: 22, child: Text('Customer', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
              Expanded(flex: 10, child: Text('Mode', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
              Expanded(flex: 14, child: Text('Amount', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
              Expanded(flex: 14, child: Text('Collected By', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
              Expanded(flex: 10, child: Text('Actions', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
            ],
          ),
        ),
        Expanded(
          child: payments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: AppTheme.textSecondary.withAlpha(80)),
                        const SizedBox(height: 12),
                        const Text('No transactions found', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, i) => _TransactionRow(
                    payment: payments[i],
                    index: i,
                    onView: onView,
                    onPrint: onPrint,
                    onDownload: onDownload,
                    onShare: onShare,
                    loadingAction: loadingAction,
                  ),
                ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Payment payment;
  final int index;
  final ValueChanged<Payment> onView;
  final ValueChanged<Payment> onPrint;
  final ValueChanged<Payment> onDownload;
  final ValueChanged<Payment> onShare;
  final String? loadingAction;

  const _TransactionRow({
    required this.payment,
    required this.index,
    required this.onView,
    required this.onPrint,
    required this.onDownload,
    required this.onShare,
    this.loadingAction,
  });

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final isOdd = index.isOdd;
    final customerName = p.customer?.name ?? 'N/A';
    final dateStr = DateFormat('dd MMM yy').format(p.paymentDate);
    final timeStr = DateFormat('hh:mm a').format(p.paymentDate);

    final isLoadingPrint = loadingAction == 'print_pay_${p.id}';
    final isLoadingDownload = loadingAction == 'dl_pay_${p.id}';
    final isInvLoading = isLoadingPrint || isLoadingDownload;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isOdd ? const Color(0xFFFAFAFC) : Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFEEEEF0), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(flex: 18, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('#${p.receiptNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)), overflow: TextOverflow.ellipsis),
              Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          )),
          Expanded(flex: 12, child: Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          Expanded(flex: 22, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
              if (p.notes?.isNotEmpty == true)
                Text(p.notes!, style: TextStyle(fontSize: 10, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis, maxLines: 1),
            ],
          )),
          Expanded(flex: 10, child: Text(p.mode.displayName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600))),
          Expanded(flex: 14, child: Text(
            AppUtils.formatCurrency(p.amount),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)),
            textAlign: TextAlign.right,
          )),
          Expanded(flex: 14, child: Text(
            p.customer?.name ?? '-',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          )),
          Expanded(flex: 10, child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Action(Icons.visibility, AppTheme.info, false, () => onView(p)),
              _Action(Icons.print, AppTheme.textSecondary, isInvLoading, isInvLoading ? () {} : () => onPrint(p)),
              _Action(Icons.download, AppTheme.success, isInvLoading, isInvLoading ? () {} : () => onDownload(p)),
              _Action(Icons.share, AppTheme.info, false, () => onShare(p)),
            ],
          )),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;
  const _Action(this.icon, this.color, this.isLoading, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: isLoading
            ? SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: color))
            : Icon(icon, size: 15, color: color),
      ),
    );
  }
}
