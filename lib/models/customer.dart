import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String mobile;
  final String? address;
  final String? gstNumber;
  final double openingBalance;
  final String? notes;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double currentDue;
  final int billCount;
  final DateTime? lastBillDate;
  final DateTime? lastPaymentDate;

  const Customer({
    required this.id,
    required this.name,
    required this.mobile,
    this.address,
    this.gstNumber,
    this.openingBalance = 0,
    this.notes,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.currentDue = 0,
    this.billCount = 0,
    this.lastBillDate,
    this.lastPaymentDate,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    mobile: json['mobile'] ?? '',
    address: json['address'],
    gstNumber: json['gstNumber'],
    openingBalance: (json['openingBalance'] ?? 0).toDouble(),
    notes: json['notes'],
    isDeleted: json['isDeleted'] ?? false,
    createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    currentDue: (json['currentDue'] ?? 0).toDouble(),
    billCount: json['billCount'] ?? 0,
    lastBillDate: json['lastBillDate'] != null ? DateTime.tryParse(json['lastBillDate']) : null,
    lastPaymentDate: json['lastPaymentDate'] != null ? DateTime.tryParse(json['lastPaymentDate']) : null,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'mobile': mobile,
    'address': address,
    'gstNumber': gstNumber,
    'openingBalance': openingBalance,
    'notes': notes,
  };

  Customer copyWith({double? currentDue}) => Customer(
    id: id, name: name, mobile: mobile, address: address,
    gstNumber: gstNumber, openingBalance: openingBalance, notes: notes,
    isDeleted: isDeleted, createdAt: createdAt, updatedAt: updatedAt,
    currentDue: currentDue ?? this.currentDue, billCount: billCount,
    lastBillDate: lastBillDate, lastPaymentDate: lastPaymentDate,
  );

  @override
  List<Object?> get props => [id, name, mobile, currentDue];
}
