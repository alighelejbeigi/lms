// lib/features/auth/data/models/user_model.dart
import 'package:lms/features/auth/domain/entities/user.dart';

class UserModel extends UserEntity {
  const UserModel({
    required String id,
    required String username,
    required String mobile,
    required String role,
  }) : super(id: id, username: username, mobile: mobile, role: role);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      mobile: json['mobile'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'mobile': mobile, 'role': role};
  }
}
