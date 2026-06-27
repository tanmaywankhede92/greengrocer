import 'package:equatable/equatable.dart';

class BusinessSettings extends Equatable {
  final String id;
  final String businessName;
  final String? tagline;
  final String? address;
  final String? phone;
  final String? gstNumber;
  final String invoicePrefix;
  final String? footerNote;

  const BusinessSettings({
    required this.id,
    required this.businessName,
    this.tagline,
    this.address,
    this.phone,
    this.gstNumber,
    this.invoicePrefix = 'RE',
    this.footerNote,
  });

  factory BusinessSettings.fromJson(Map<String, dynamic> json) => BusinessSettings(
    id: json['_id'] ?? json['id'] ?? '',
    businessName: json['businessName'] ?? '',
    tagline: json['tagline'],
    address: json['address'],
    phone: json['phone'],
    gstNumber: json['gstNumber'],
    invoicePrefix: json['invoicePrefix'] ?? 'RE',
    footerNote: json['footerNote'],
  );

  Map<String, dynamic> toJson() => {
    'businessName': businessName,
    'tagline': tagline,
    'address': address,
    'phone': phone,
    'gstNumber': gstNumber,
    'invoicePrefix': invoicePrefix,
    'footerNote': footerNote,
  };

  @override
  List<Object?> get props => [id, businessName, invoicePrefix];
}
