import 'package:equatable/equatable.dart';
import 'customer.dart';
import '../widgets/bill_item_row.dart';

class DraftBill extends Equatable {
  final String id;
  final String draftId;
  final String? customerId;
  final Customer? customer;
  final String customerName;
  final String customerMobile;
  final String customerAddress;
  final DateTime billDate;
  final List<LineItem> items;
  final double subtotal;
  final double deliveryCharge;
  final double discount;
  final double total;
  final String notes;
  final double paymentAmount;
  final String paymentMode;
  final String status;
  final String? convertedBillId;
  final String? convertedBillNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DraftBill({
    required this.id,
    required this.draftId,
    this.customerId,
    this.customer,
    this.customerName = '',
    this.customerMobile = '',
    this.customerAddress = '',
    required this.billDate,
    this.items = const [],
    this.subtotal = 0,
    this.deliveryCharge = 0,
    this.discount = 0,
    this.total = 0,
    this.notes = '',
    this.paymentAmount = 0,
    this.paymentMode = 'cash',
    this.status = 'draft',
    this.convertedBillId,
    this.convertedBillNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory DraftBill.fromJson(Map<String, dynamic> json) {
    Customer? parsedCustomer;
    String? custId;
    if (json['customerId'] is Map) {
      parsedCustomer = Customer.fromJson(json['customerId'] as Map<String, dynamic>);
      custId = parsedCustomer.id;
    } else if (json['customerId'] is String) {
      custId = json['customerId'] as String;
    }

    final rawItems = json['items'] as List? ?? [];
    final itemsList = rawItems.map((e) => LineItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();

    return DraftBill(
      id: json['_id'] ?? json['id'] ?? '',
      draftId: json['draftId'] ?? '',
      customerId: custId,
      customer: parsedCustomer,
      customerName: json['customerName'] ?? parsedCustomer?.name ?? '',
      customerMobile: json['customerMobile'] ?? parsedCustomer?.mobile ?? '',
      customerAddress: json['customerAddress'] ?? parsedCustomer?.address ?? '',
      billDate: json['billDate'] != null ? DateTime.tryParse(json['billDate']) ?? DateTime.now() : DateTime.now(),
      items: itemsList,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] ?? '',
      paymentAmount: (json['paymentAmount'] as num?)?.toDouble() ?? 0,
      paymentMode: json['paymentMode'] ?? 'cash',
      status: json['status'] ?? 'draft',
      convertedBillId: json['convertedBillId'] as String?,
      convertedBillNumber: json['convertedBillNumber'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Customer? toCustomer() {
    if (customer != null) return customer;
    if (customerId != null && customerId!.isNotEmpty) {
      return Customer(
        id: customerId!,
        name: customerName.isNotEmpty ? customerName : 'Customer',
        mobile: customerMobile,
        address: customerAddress,
      );
    }
    if (customerName.isNotEmpty) {
      return Customer(
        id: '',
        name: customerName,
        mobile: customerMobile,
        address: customerAddress,
      );
    }
    return null;
  }

  @override
  List<Object?> get props => [id, draftId, customerId, total, status, updatedAt];
}
