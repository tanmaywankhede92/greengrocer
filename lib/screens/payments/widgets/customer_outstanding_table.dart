import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils.dart';
import '../../../models/customer.dart';
import 'status_badge.dart';

class CustomerOutstandingTable extends StatelessWidget {
  final List<Customer> customers;
  final ValueChanged<Customer> onPay;
  final ValueChanged<Customer> onStatement;
  final ValueChanged<Customer> onInvoice;
  final ValueChanged<Customer> onViewLedger;
  final String? loadingAction;

  const CustomerOutstandingTable({
    super.key,
    required this.customers,
    required this.onPay,
    required this.onStatement,
    required this.onInvoice,
    required this.onViewLedger,
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
              Expanded(flex: 25, child: Text('Customer', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
              Expanded(flex: 15, child: Text('Mobile', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
              Expanded(flex: 15, child: Text('Outstanding', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
              Expanded(flex: 12, child: Text('Paid', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
              Expanded(flex: 10, child: Text('Status', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
              Expanded(flex: 23, child: Text('Actions', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
            ],
          ),
        ),
        Expanded(
          child: customers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: AppTheme.textSecondary.withAlpha(80)),
                        const SizedBox(height: 12),
                        const Text('No customers found', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, i) {
                    final c = customers[i];
                    return _CustomerRow(
                      customer: c,
                      index: i,
                      onPay: onPay,
                      onStatement: onStatement,
                      onInvoice: onInvoice,
                      onViewLedger: onViewLedger,
                      loadingAction: loadingAction,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CustomerRow extends StatelessWidget {
  final Customer customer;
  final int index;
  final ValueChanged<Customer> onPay;
  final ValueChanged<Customer> onStatement;
  final ValueChanged<Customer> onInvoice;
  final ValueChanged<Customer> onViewLedger;
  final String? loadingAction;

  const _CustomerRow({
    required this.customer,
    required this.index,
    required this.onPay,
    required this.onStatement,
    required this.onInvoice,
    required this.onViewLedger,
    this.loadingAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final isOdd = index.isOdd;
    final isInvLoading = loadingAction == 'inv_${c.id}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isOdd ? const Color(0xFFFAFAFC) : Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFEEEEF0), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(flex: 25, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)), overflow: TextOverflow.ellipsis),
              Text(c.mobile, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          )),
          Expanded(flex: 15, child: Text(c.mobile, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          Expanded(flex: 15, child: Text(
            AppUtils.formatCurrency(c.currentDue),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.currentDue > 0 ? AppTheme.error : AppTheme.success),
            textAlign: TextAlign.right,
          )),
          Expanded(flex: 12, child: Text(
            AppUtils.formatCurrency(c.totalPaid),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.right,
          )),
          Expanded(flex: 10, child: Center(child: StatusBadge.fromCustomer(currentDue: c.currentDue, totalPaid: c.totalPaid))),
          Expanded(flex: 23, child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (c.currentDue > 0)
                _Action(Icons.payments, 'Pay', AppTheme.primaryRed, false, () => onPay(c)),
              _Action(Icons.description_outlined, 'Stmt', AppTheme.info, false, () => onStatement(c)),
              _Action(isInvLoading ? Icons.hourglass_empty : Icons.receipt_long, 'Inv', AppTheme.textSecondary, isInvLoading, isInvLoading ? () {} : () => onInvoice(c)),
              _Action(Icons.account_balance, 'Ledger', AppTheme.primaryRedDark, false, () => onViewLedger(c)),
            ],
          )),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;
  const _Action(this.icon, this.tooltip, this.color, this.isLoading, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: isLoading
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color))
              : Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
