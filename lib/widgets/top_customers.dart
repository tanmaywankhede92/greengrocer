import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../models/customer.dart';

class TopCustomers extends StatelessWidget {
  final List<Customer> customers;
  const TopCustomers({super.key, required this.customers});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Customers', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const Divider(),
            if (customers.isEmpty)
              const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No customers', style: TextStyle(color: AppTheme.textSecondary))))
            else
              ...customers.map((c) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryRed.withAlpha(20),
                  child: Text(AppUtils.initials(c.name), style: TextStyle(color: AppTheme.primaryRed, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                title: Text(c.name, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                subtitle: Text(c.mobile, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                trailing: Text(AppUtils.formatCurrency(c.currentDue), style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w600)),
                onTap: () => context.go('/customers/${c.id}'),
              )),
          ],
        ),
      ),
    );
  }
}
