import 'package:equatable/equatable.dart';
import '../core/enums.dart';
import 'customer.dart';

class Payment extends Equatable {
  final String id;
  final String receiptNumber;
  final String customerId;
  final Customer? customer;
  final double amount;
  final PaymentMode mode;
  final String? reference;
  final String? notes;
  final DateTime paymentDate;
  final bool isCancelled;
  final DateTime? createdAt;

  const Payment({
    required this.id,
    required this.receiptNumber,
    required this.customerId,
    this.customer,
    required this.amount,
    this.mode = PaymentMode.cash,
    this.reference,
    this.notes,
    required this.paymentDate,
    this.isCancelled = false,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['_id'] ?? json['id'] ?? '',
    receiptNumber: json['receiptNumber'] ?? '',
    customerId: json['customerId'] is Map
        ? (json['customerId']['_id'] ?? json['customerId']['id'] ?? '')
        : (json['customerId'] ?? ''),
    customer: json['customer'] != null
        ? Customer.fromJson(json['customer'])
        : (json['customerId'] is Map ? Customer.fromJson(json['customerId']) : null),
    amount: (json['amount'] ?? 0).toDouble(),
    mode: PaymentMode.fromString(json['mode'] ?? 'cash'),
    reference: json['reference'],
    notes: json['notes'],
    paymentDate: DateTime.parse(json['paymentDate'] ?? DateTime.now().toIso8601String()),
    isCancelled: json['isCancelled'] ?? false,
    createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
  );

  @override
  List<Object?> get props => [id, receiptNumber, customerId, amount, isCancelled];
}
