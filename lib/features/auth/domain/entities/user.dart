// lib/features/auth/domain/entities/user.dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String mobile;
  final String role;

  const UserEntity({
    required this.id,
    required this.username,
    required this.mobile,
    required this.role,
  });

  @override
  List<Object> get props => [id, username, mobile, role];
}
