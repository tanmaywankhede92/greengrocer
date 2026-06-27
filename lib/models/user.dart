import 'package:equatable/equatable.dart';
import '../core/enums.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.role = UserRole.staff,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] ?? json['_id'] ?? '',
    email: json['email'] ?? '',
    fullName: json['fullName'] ?? '',
    role: UserRole.fromString(json['role'] ?? 'staff'),
    createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'role': role.value,
  };

  @override
  List<Object?> get props => [id, email, fullName, role];
}
