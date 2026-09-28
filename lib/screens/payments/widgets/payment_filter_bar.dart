import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'payment_date_filter.dart';

/// The expandable filter panel of the payments page: date range on top,
/// status / mode chips below.
class PaymentFilterBar extends StatelessWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<DateTime?> onFromDateChanged;
  final ValueChanged<DateTime?> onToDateChanged;
  final VoidCallback onClearDates;
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;

  const PaymentFilterBar({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.onFromDateChanged,
    required this.onToDateChanged,
    required this.onClearDates,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  static const _filters = [
    ('All', 'all'),
    ('Paid', 'paid'),
    ('Unpaid', 'unpaid'),
    ('Partial', 'partial'),
    ('Cash', 'cash'),
    ('UPI', 'upi'),
    ('Bank', 'bank'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PaymentDateFilter(
          from: fromDate,
          to: toDate,
          onFromChanged: onFromDateChanged,
          onToChanged: onToDateChanged,
          onClear: onClearDates,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final (label, value) = _filters[i];
              final active = activeFilter == value;
              return ChoiceChip(
                label: Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.white : AppTheme.textSecondary)),
                selected: active,
                selectedColor: AppTheme.primaryRed,
                backgroundColor: Colors.white,
                side: BorderSide(color: active ? AppTheme.primaryRed : AppTheme.border),
                onSelected: (_) => onFilterChanged(value),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              );
            },
          ),
        ),
      ],
    );
  }
}
