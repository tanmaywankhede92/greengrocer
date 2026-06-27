import 'package:equatable/equatable.dart';

class DailyRate extends Equatable {
  final String id;
  final String productId;
  final double rate;
  final DateTime rateDate;

  const DailyRate({
    required this.id,
    required this.productId,
    required this.rate,
    required this.rateDate,
  });

  factory DailyRate.fromJson(Map<String, dynamic> json) => DailyRate(
    id: json['_id'] ?? json['id'] ?? '',
    productId: json['productId'] ?? '',
    rate: (json['rate'] ?? 0).toDouble(),
    rateDate: DateTime.parse(json['rateDate'] ?? DateTime.now().toIso8601String()),
  );

  @override
  List<Object?> get props => [id, productId, rate, rateDate];
}
