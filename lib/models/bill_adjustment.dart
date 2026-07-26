import 'package:equatable/equatable.dart';

class BillAdjustment extends Equatable {
  final String id;
  final String billId;
  final String customerId;
  final double amount;
  final String reason;
  final String note;
  final DateTime adjustmentDate;
  final DateTime? createdAt;

  const BillAdjustment({
    required this.id,
    required this.billId,
    required this.customerId,
    required this.amount,
    required this.reason,
    this.note = '',
    required this.adjustmentDate,
    this.createdAt,
  });

  factory BillAdjustment.fromJson(Map<String, dynamic> json) => BillAdjustment(
    id: json['_id'] ?? json['id'] ?? '',
    billId: json['billId'] ?? '',
    customerId: json['customerId'] ?? '',
    amount: (json['amount'] ?? 0).toDouble(),
    reason: json['reason'] ?? 'other',
    note: json['note'] ?? '',
    adjustmentDate: DateTime.parse(json['adjustmentDate'] ?? DateTime.now().toIso8601String()),
    createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
  );

  String get reasonLabel {
    switch (reason) {
      case 'damaged':
        return 'Damaged';
      case 'missing':
        return 'Missing';
      case 'short_supply':
        return 'Short Supply';
      case 'rate_diff':
        return 'Rate Difference';
      default:
        return 'Other';
    }
  }

  @override
  List<Object?> get props => [id, billId, amount, reason, note];
}
