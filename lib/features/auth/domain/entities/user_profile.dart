import 'package:equatable/equatable.dart';

class UserProfileEntity extends Equatable {
  final int? id;
  final String? nickName;
  final String? profileImage;
  final String? address;

  const UserProfileEntity({
    this.id,
    this.nickName,
    this.profileImage,
    this.address,
  });

  @override
  List<Object?> get props => [id, nickName, profileImage, address];
}
