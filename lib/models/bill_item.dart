import 'package:equatable/equatable.dart';

class BillItem extends Equatable {
  final String id;
  final String billId;
  final String? productId;
  final String productName;
  final String unit;
  final double quantity;
  final double defaultRate;
  final double appliedRate;
  final double amount;

  const BillItem({
    required this.id,
    required this.billId,
    this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    this.defaultRate = 0,
    required this.appliedRate,
    required this.amount,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
    id: json['_id'] ?? json['id'] ?? '',
    billId: json['billId'] ?? '',
    productId: json['productId'],
    productName: json['productName'] ?? '',
    unit: json['unit'] ?? 'kg',
    quantity: (json['quantity'] ?? 0).toDouble(),
    defaultRate: (json['defaultRate'] ?? 0).toDouble(),
    appliedRate: (json['appliedRate'] ?? 0).toDouble(),
    amount: (json['amount'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    if (productId != null) 'productId': productId,
    'productName': productName,
    'unit': unit,
    'quantity': quantity,
    'defaultRate': defaultRate,
    'appliedRate': appliedRate,
  };

  @override
  List<Object?> get props => [id, productName, quantity, appliedRate, amount];
}
