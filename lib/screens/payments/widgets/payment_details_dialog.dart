import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/utils.dart';
import '../../../models/payment.dart';
import 'payment_helpers.dart';

class PaymentDetailsDialog extends StatelessWidget {
  final Payment payment;
  final String? loadingAction;
  final VoidCallback? onPrint;
  final VoidCallback? onDownload;

  const PaymentDetailsDialog({
    super.key,
    required this.payment,
    this.loadingAction,
    this.onPrint,
    this.onDownload,
  });

  static void show(BuildContext context, {required Payment payment, String? loadingAction, VoidCallback? onPrint, VoidCallback? onDownload}) {
    showDialog(
      context: context,
      builder: (_) => PaymentDetailsDialog(payment: payment, loadingAction: loadingAction, onPrint: onPrint, onDownload: onDownload),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final isPrintLoading = loadingAction == 'dlg_print_${p.customer?.id}';
    final isDlLoading = loadingAction == 'dlg_dl_${p.customer?.id}';
    final isAnyLoading = isPrintLoading || isDlLoading;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long, size: 22, color: AppTheme.success),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Details', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                        Text('#${p.receiptNumber}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.success.withAlpha(40)),
                ),
                child: Column(
                  children: [
                    const Text('Amount Received', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(AppUtils.formatCurrency(p.amount), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.success)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    dialogRow('Receipt No.', p.receiptNumber),
                    const Divider(height: 16),
                    dialogRow('Customer', p.customer?.name ?? 'N/A'),
                    dialogRow('Mobile', p.customer?.mobile ?? '-'),
                    const Divider(height: 16),
                    dialogRow('Payment Date', DateFormat('dd MMM yyyy').format(p.paymentDate)),
                    dialogRow('Payment Time', DateFormat('hh:mm a').format(p.paymentDate)),
                    dialogRow('Mode', p.mode.displayName),
                    if (p.reference?.isNotEmpty == true) ...[
                      const Divider(height: 16),
                      dialogRow('Reference', p.reference!),
                    ],
                    if (p.notes?.isNotEmpty == true) ...[
                      const Divider(height: 16),
                      dialogRow('Remarks', p.notes!),
                    ],
                    if (p.isCancelled) ...[
                      const Divider(height: 16),
                      dialogRow('Status', 'Cancelled', valueColor: AppTheme.error),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: isPrintLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.print, size: 18),
                      label: Text(isPrintLoading ? 'Printing...' : 'Print Invoice'),
                      onPressed: (isAnyLoading || onPrint == null) ? null : onPrint,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      icon: isDlLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.download, size: 18),
                      label: Text(isDlLoading ? 'Downloading...' : 'Download Invoice'),
                      onPressed: (isAnyLoading || onDownload == null) ? null : onDownload,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
