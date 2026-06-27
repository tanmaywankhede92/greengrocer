import 'package:equatable/equatable.dart';
import '../core/enums.dart';

class LedgerEntry extends Equatable {
  final String id;
  final String customerId;
  final LedgerEntryType entryType;
  final DateTime entryDate;
  final String description;
  final double debit;
  final double credit;
  final DateTime? createdAt;

  const LedgerEntry({
    required this.id,
    required this.customerId,
    required this.entryType,
    required this.entryDate,
    required this.description,
    this.debit = 0,
    this.credit = 0,
    this.createdAt,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
    id: json['_id'] ?? json['id'] ?? '',
    customerId: json['customerId'] ?? '',
    entryType: LedgerEntryType.fromString(json['entryType'] ?? 'bill'),
    entryDate: DateTime.parse(json['entryDate'] ?? DateTime.now().toIso8601String()),
    description: json['description'] ?? '',
    debit: (json['debit'] ?? 0).toDouble(),
    credit: (json['credit'] ?? 0).toDouble(),
    createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
  );

  @override
  List<Object?> get props => [id, customerId, entryType, debit, credit];
}
