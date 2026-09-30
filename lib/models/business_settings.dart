import 'package:equatable/equatable.dart';

class BusinessSettings extends Equatable {
  final String id;
  final String businessName;
  final String? tagline;
  final String? address;
  final String? phone;
  final String? gstNumber;
  final String billPrefix;
  final String invoicePrefix;
  final String? footerNote;

  const BusinessSettings({
    required this.id,
    required this.businessName,
    this.tagline,
    this.address,
    this.phone,
    this.gstNumber,
    this.billPrefix = '',
    this.invoicePrefix = 'INV',
    this.footerNote,
  });

  factory BusinessSettings.fromJson(Map<String, dynamic> json) => BusinessSettings(
    id: json['_id'] ?? json['id'] ?? '',
    businessName: json['businessName'] ?? '',
    tagline: json['tagline'],
    address: json['address'],
    phone: json['phone'],
    gstNumber: json['gstNumber'],
    billPrefix: json['billPrefix'] ?? '',
    invoicePrefix: json['invoicePrefix'] ?? 'INV',
    footerNote: json['footerNote'],
  );

  Map<String, dynamic> toJson() => {
    'businessName': businessName,
    'tagline': tagline,
    'address': address,
    'phone': phone,
    'gstNumber': gstNumber,
    'billPrefix': billPrefix,
    'invoicePrefix': invoicePrefix,
    'footerNote': footerNote,
  };

  @override
  List<Object?> get props => [id, businessName, billPrefix, invoicePrefix];
}
