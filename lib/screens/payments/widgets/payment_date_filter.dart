import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils.dart';

/// Compact from/to date filter for the payments page.
///
/// Deliberately two small pickers side by side instead of
/// `showDateRangePicker` - the range picker opens a full screen dialog which is
/// far too heavy for filtering a table that already sits right below it.
class PaymentDateFilter extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  final ValueChanged<DateTime?> onFromChanged;
  final ValueChanged<DateTime?> onToChanged;
  final VoidCallback onClear;

  const PaymentDateFilter({
    super.key,
    required this.from,
    required this.to,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onClear,
  });

  bool get _isActive => from != null || to != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _isActive ? AppTheme.primaryRed.withAlpha(70) : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'From',
                  date: from,
                  onChanged: onFromChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateField(
                  label: 'To',
                  date: to,
                  onChanged: onToChanged,
                ),
              ),
              if (_isActive)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  color: AppTheme.textSecondary,
                  tooltip: 'Clear dates',
                  visualDensity: VisualDensity.compact,
                  onPressed: onClear,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _QuickRange('Today', _isSameDay(from, to, _startOfToday, _endOfToday), () {
                onFromChanged(_startOfToday);
                onToChanged(_endOfToday);
              }),
              _QuickRange('This Week', _isSameDay(from, to, _startOfWeek, DateTime.now()), () {
                onFromChanged(_startOfWeek);
                onToChanged(_endOfToday);
              }),
              _QuickRange('This Month', _isSameDay(from, to, _startOfMonth, _endOfToday), () {
                onFromChanged(_startOfMonth);
                onToChanged(_endOfToday);
              }),
              _QuickRange('Last 30 Days', _isSameDay(from, to, _startOfLast30, _endOfToday), () {
                onFromChanged(_startOfLast30);
                onToChanged(_endOfToday);
              }),
              _QuickRange('All', !_isActive, onClear),
            ],
          ),
        ],
      ),
    );
  }

  static DateTime get _startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime get _endOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  }

  static DateTime get _startOfWeek {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  }

  static DateTime get _startOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static DateTime get _startOfLast30 {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
  }

  static bool _isSameDay(DateTime? from, DateTime? to, DateTime a, DateTime b) {
    if (from == null || to == null) return false;
    return AppUtils.formatDate(from) == AppUtils.formatDate(a) &&
        AppUtils.formatDate(to) == AppUtils.formatDate(b);
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;

  const _DateField({required this.label, required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? now,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
          helpText: 'Select $label date',
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        isEmpty: date == null,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1.2),
          ),
          suffixIcon: const Icon(Icons.calendar_today, size: 15),
        ),
        child: date == null
            ? null
            : Text(
                AppUtils.formatDate(date!),
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
              ),
      ),
    );
  }
}

class _QuickRange extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _QuickRange(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryRed.withAlpha(20) : AppTheme.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? AppTheme.primaryRed : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? AppTheme.primaryRed : AppTheme.textSecondary,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
