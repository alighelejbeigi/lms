// lib/features/auth/domain/repositories/auth_repository.dart

import 'package:dart_either/dart_either.dart';
import 'package:lms/core/errors/failures.dart';
import 'package:lms/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  // مرحله ۱: ارسال اطلاعات کاربر
  Future<Either<Failure, bool>> requestAuth(String userIdentifier);

  // مرحله ۲: تأیید رمز عبور و دریافت توکن
  Future<Either<Failure, UserEntity>> verifyAuth(String code);

  // مرحله Whoami: دریافت اطلاعات کاربر
  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, bool>> registerFace(String imagePath);

  Future<Either<Failure, bool>> compareFaceWithAvatar(
    String imagePath,
  ); // <<<--- متد جدید
  Future<void> logout(); // <<<--- اضافه شده
}
