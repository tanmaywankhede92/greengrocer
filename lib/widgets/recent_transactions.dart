import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../models/bill.dart';
import '../core/enums.dart';

class RecentTransactions extends StatelessWidget {
  final List<Bill> bills;
  const RecentTransactions({super.key, required this.bills});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              const SizedBox(height: 8),
              if (bills.isEmpty)
                const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No bills yet', style: TextStyle(color: AppTheme.textSecondary))))
              else if (isMobile)
                Expanded(child: ListView.builder(
                  itemCount: bills.length > 6 ? 6 : bills.length,
                  itemBuilder: (_, i) => _mobileRow(context, bills[i]),
                ))
              else
                Expanded(
                  child: Column(
                    children: [
                      _colHeader(),
                      const Divider(height: 1, color: AppTheme.border),
                      Expanded(
                        child: ListView.builder(
                          itemCount: bills.length > 6 ? 6 : bills.length,
                          itemBuilder: (_, i) => _desktopRow(context, bills[i], i),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Recent Bills', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        TextButton.icon(
          icon: const Icon(Icons.arrow_forward, size: 14),
          label: const Text('View All', style: TextStyle(fontSize: 12)),
          onPressed: () => context.go('/bills'),
        ),
      ],
    );
  }

  Widget _colHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _hCell('Bill No', 2),
          _hCell('Customer', 3),
          _hCell('Date', 1.5),
          _hCell('Amount', 1.5, align: TextAlign.right),
          _hCell('Status', 1.2, align: TextAlign.center),
          _hCell('', 0.8),
        ],
      ),
    );
  }

  Widget _hCell(String label, double flex, {TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex.ceil(),
      child: Text(label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 0.3),
        textAlign: align),
    );
  }

  Widget _desktopRow(BuildContext context, Bill b, int index) {
    final statusColor = b.status == BillStatus.active ? AppTheme.success : AppTheme.error;
    final statusLabel = b.status == BillStatus.active ? 'Active' : 'Cancelled';
    return InkWell(
      onTap: () => context.go('/bills/${b.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: index > 0 ? const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
        ) : null,
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(b.billNumber, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
            Expanded(flex: 3, child: Text(b.customer?.name ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
            Expanded(flex: 1, child: Text(DateFormat('dd/MM/yy').format(b.billDate), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
            Expanded(flex: 1, child: Text(AppUtils.formatCurrency(b.total), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
            Expanded(flex: 1, child: Center(child: _statusBadge(statusLabel, statusColor))),
            Expanded(flex: 0, child: Container(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
            )),
          ],
        ),
      ),
    );
  }

  Widget _mobileRow(BuildContext context, Bill b) {
    final statusColor = b.status == BillStatus.active ? AppTheme.success : AppTheme.error;
    final statusLabel = b.status == BillStatus.active ? 'Active' : 'Cancelled';
    return InkWell(
      onTap: () => context.go('/bills/${b.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.billNumber, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(b.customer?.name ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Text(DateFormat('dd/MM/yy').format(b.billDate), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(AppUtils.formatCurrency(b.total), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                _statusBadge(statusLabel, statusColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
