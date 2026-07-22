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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Top Customers', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton.icon(
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text('View All', style: TextStyle(fontSize: 12)),
                onPressed: () => context.go('/customers'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (customers.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No customers', style: TextStyle(color: AppTheme.textSecondary))))
          else
            Expanded(
              child: ListView.separated(
                itemCount: customers.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                itemBuilder: (context, index) {
                  final c = customers[index];
                  return InkWell(
                    onTap: () => context.go('/customers/${c.id}'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryRed.withAlpha(15),
                            child: Text(AppUtils.initials(c.name),
                              style: TextStyle(color: AppTheme.primaryRed, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(c.mobile, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(AppUtils.formatCurrency(c.currentDue),
                            style: TextStyle(color: c.currentDue > 0 ? AppTheme.warning : AppTheme.success,
                              fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
