import 'package:equatable/equatable.dart';
import '../core/enums.dart';
import 'customer.dart';

class Bill extends Equatable {
  final String id;
  final String billNumber;
  final String customerId;
  final Customer? customer;
  final DateTime billDate;
  final double subtotal;
  final String deliveryBoyName;
  final double total;
  final double paidNow;
  final double newDue;
  final String? paymentType;
  final String? notes;
  final BillStatus status;
  final DateTime? createdAt;

  const Bill({
    required this.id,
    required this.billNumber,
    required this.customerId,
    this.customer,
    required this.billDate,
    this.subtotal = 0,
    this.deliveryBoyName = '',
    this.total = 0,
    this.paidNow = 0,
    this.newDue = 0,
    this.paymentType,
    this.notes,
    this.status = BillStatus.active,
    this.createdAt,
  });

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: json['_id'] ?? json['id'] ?? '',
    billNumber: json['billNumber'] ?? '',
    customerId: json['customerId'] is Map
        ? (json['customerId']['_id'] ?? json['customerId']['id'] ?? '')
        : (json['customerId'] ?? ''),
    customer: json['customer'] != null
        ? Customer.fromJson(json['customer'])
        : (json['customerId'] is Map ? Customer.fromJson(json['customerId']) : null),
    billDate: DateTime.parse(json['billDate'] ?? DateTime.now().toIso8601String()),
    subtotal: (json['subtotal'] ?? 0).toDouble(),
    deliveryBoyName: json['deliveryBoyName'] ?? '',
    total: (json['total'] ?? 0).toDouble(),
    paidNow: (json['paidNow'] ?? 0).toDouble(),
    newDue: (json['newDue'] ?? 0).toDouble(),
    paymentType: json['paymentType'],
    notes: json['notes'],
    status: BillStatus.fromString(json['status'] ?? 'active'),
    createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
  );

  @override
  List<Object?> get props => [id, billNumber, customerId, total, status];
}
