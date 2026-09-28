import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/utils.dart';
import '../../../models/payment.dart';
import 'table_actions.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2330),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 18, child: Text('Receipt No', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                Expanded(flex: 12, child: Text('Date', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                Expanded(flex: 20, child: Text('Customer', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                Expanded(flex: 10, child: Text('Mode', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                Expanded(flex: 14, child: Text('Amount', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
                Expanded(flex: 12, child: Text('Collected By', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                Expanded(flex: 14, child: TableActionsHeader()),
              ],
            ),
          ),
          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 48, color: Color(0xFFBDBDBD)),
                  SizedBox(height: 12),
                  Text('No transactions found', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
        ],
      ),
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
    final canGenerate = p.customer != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isOdd ? const Color(0xFFFAFAFC) : Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFEEEEF0), width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 18, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('#${p.receiptNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)), overflow: TextOverflow.ellipsis),
              Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          )),
          Expanded(flex: 12, child: Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          Expanded(flex: 20, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(customerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
              if (p.notes?.isNotEmpty == true)
                Text(p.notes!, style: TextStyle(fontSize: 10, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis, maxLines: 1),
            ],
          )),
          Expanded(flex: 10, child: Text(p.mode.displayName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 14, child: Text(
            AppUtils.formatCurrency(p.amount),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)),
            textAlign: TextAlign.right,
          )),
          Expanded(flex: 12, child: Text(
            customerName,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          )),
          Expanded(flex: 14, child: TableActions(actions: [
            TableAction(icon: Icons.visibility, tooltip: 'View Details', color: AppTheme.info, onPressed: () => onView(p)),
            TableAction(
              icon: isLoadingPrint ? Icons.hourglass_empty : Icons.print,
              tooltip: 'Print Invoice',
              color: AppTheme.textSecondary,
              isLoading: isLoadingPrint,
              visible: canGenerate,
              onPressed: isLoadingPrint ? () {} : () => onPrint(p),
            ),
            TableAction(
              icon: isLoadingDownload ? Icons.hourglass_empty : Icons.download,
              tooltip: 'Download Invoice',
              color: AppTheme.success,
              isLoading: isLoadingDownload,
              visible: canGenerate,
              onPressed: isLoadingDownload ? () {} : () => onDownload(p),
            ),
            TableAction(icon: Icons.share, tooltip: 'Share Invoice', color: AppTheme.info, onPressed: () => onShare(p)),
          ])),
        ],
      ),
    );
  }
}
