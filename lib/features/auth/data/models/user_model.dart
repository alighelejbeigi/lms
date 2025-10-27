import 'package:lms/features/auth/domain/entities/user.dart';
import 'package:lms/features/auth/domain/entities/user_profile.dart';

// ------------------------------------
// Profile Model (Nested)
// ------------------------------------
class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    final int? id,
    final String? nickName,
    final String? profileImage,
    final String? address,
  }) : super(
         id: id,
         nickName: nickName,
         profileImage: profileImage,
         address: address,
       );

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as int?,
      nickName: json['nickName'] as String?,
      profileImage: json['profileImage'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickName': nickName,
      'profileImage': profileImage,
      'address': address,
    };
  }
}

// ------------------------------------
// Main User Model
// ------------------------------------
class UserModel extends UserEntity {
  const UserModel({
    required final String id,
    required final String username,
    required final String mobile,
    final String? erpCode,
    final bool? isVerified,
    final int? priceType,
    final bool? wholeSeller,
    final UserProfileModel? profile,
    required final String role,
  }) : super(
         id: id,
         username: username,
         mobile: mobile,
         erpCode: erpCode,
         isVerified: isVerified,
         priceType: priceType,
         wholeSeller: wholeSeller,
         profile: profile,
         role: role,
       );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      mobile: json['mobile'] as String,
      // این فیلدها می‌توانند null باشند
      erpCode: json['erpCode'] as String?,
      isVerified: json['isVerified'] as bool?,
      priceType: json['priceType'] as int?,
      wholeSeller: json['wholeSeller'] as bool?,
      role: json['role'] as String,
      // پردازش آبجکت تودرتوی profile
      profile:
          json['profile'] != null
              ? UserProfileModel.fromJson(
                json['profile'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'mobile': mobile,
      'erpCode': erpCode,
      'isVerified': isVerified,
      'priceType': priceType,
      'wholeSeller': wholeSeller,
      'role': role,
      'profile': (profile as UserProfileModel?)?.toJson(),
    };
  }
}
