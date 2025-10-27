import 'package:equatable/equatable.dart';

import 'user_profile.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String mobile;
  final String? erpCode;
  final bool? isVerified;
  final int? priceType;
  final bool? wholeSeller;
  final UserProfileEntity? profile;
  final String role;

  // فیلدهای 'code' و 'null'ها در سطح Entity اختیاری در نظر گرفته شده‌اند

  const UserEntity({
    required this.id,
    required this.username,
    required this.mobile,
    this.erpCode,
    this.isVerified,
    this.priceType,
    this.wholeSeller,
    this.profile,
    required this.role,
  });

  @override
  List<Object?> get props => [
    id,
    username,
    mobile,
    erpCode,
    isVerified,
    priceType,
    wholeSeller,
    profile,
    role,
  ];
}
