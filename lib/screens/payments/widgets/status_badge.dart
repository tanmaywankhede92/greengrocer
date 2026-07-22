import 'package:flutter/material.dart';
import '../../../config/theme.dart';

enum PaymentStatusType { paid, partial, unpaid, cancelled }

class StatusBadge extends StatelessWidget {
  final PaymentStatusType type;
  final String? label;
  final bool compact;

  const StatusBadge({super.key, required this.type, this.label, this.compact = false});

  factory StatusBadge.fromCustomer({required double currentDue, required double totalPaid, bool compact = false}) {
    if (currentDue <= 0) return StatusBadge(type: PaymentStatusType.paid, compact: compact);
    if (totalPaid > 0) return StatusBadge(type: PaymentStatusType.partial, compact: compact);
    return StatusBadge(type: PaymentStatusType.unpaid, compact: compact);
  }

  String get _label => label ?? switch (type) {
    PaymentStatusType.paid => 'Paid',
    PaymentStatusType.partial => 'Partial',
    PaymentStatusType.unpaid => 'Unpaid',
    PaymentStatusType.cancelled => 'Cancelled',
  };

  Color get _color => switch (type) {
    PaymentStatusType.paid => AppTheme.success,
    PaymentStatusType.partial => AppTheme.info,
    PaymentStatusType.unpaid => AppTheme.error,
    PaymentStatusType.cancelled => AppTheme.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _color.withAlpha(25),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(_label, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withAlpha(60)),
      ),
      child: Text(_label, style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
