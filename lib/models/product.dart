import 'package:equatable/equatable.dart';
import '../core/enums.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final ProductUnit unit;
  final bool isActive;
  final bool isDeleted;

  const Product({
    required this.id,
    required this.name,
    required this.unit,
    this.isActive = true,
    this.isDeleted = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    unit: ProductUnit.fromString(json['unit'] ?? 'kg'),
    isActive: json['isActive'] ?? true,
    isDeleted: json['isDeleted'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'unit': unit.value,
  };

  @override
  List<Object?> get props => [id, name, unit];
}
