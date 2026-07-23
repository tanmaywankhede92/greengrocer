import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils.dart';
import '../../../models/customer.dart';
import '../../../widgets/customer_select.dart';

class CustomerSection extends StatelessWidget {
  final Customer? customer;
  final ValueChanged<Customer> onSelected;
  final VoidCallback onCleared;

  const CustomerSection({
    super.key,
    required this.customer,
    required this.onSelected,
    required this.onCleared,
  });

  @override
  Widget build(BuildContext context) {
    if (customer == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: CustomerSelect(onSelected: onSelected),
      );
    }
    return _buildChip();
  }

  Widget _buildChip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.person, size: 18, color: AppTheme.primaryRed),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(customer!.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(customer!.mobile, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              if (customer!.currentDue > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.error.withAlpha(15), borderRadius: BorderRadius.circular(6)),
                  child: Text('Due: ${AppUtils.formatCurrency(customer!.currentDue)}',
                      style: const TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onCleared,
                child: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
