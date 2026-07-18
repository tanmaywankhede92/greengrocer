import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../models/bill.dart';
import '../core/enums.dart';

class RecentTransactions extends StatelessWidget {
  final List<Bill> bills;
  const RecentTransactions({super.key, required this.bills});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Bills', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton(onPressed: () => context.go('/bills'), child: const Text('View All')),
              ],
            ),
            const Divider(),
            if (bills.isEmpty)
              const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No bills yet', style: TextStyle(color: AppTheme.textSecondary))))
            else
              ...bills.take(6).map((b) => ListTile(
                dense: true,
                leading: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: b.status == BillStatus.active ? AppTheme.success : AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(b.billNumber, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                subtitle: Text(b.customer?.name ?? '', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                trailing: Text(AppUtils.formatCurrency(b.total), style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () => context.go('/bills/${b.id}'),
              )),
          ],
        ),
      ),
    );
  }
}
