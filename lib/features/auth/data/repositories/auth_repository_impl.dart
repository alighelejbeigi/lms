// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:dart_either/dart_either.dart';
import 'package:lms/core/errors/failures.dart';
import 'package:lms/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lms/features/auth/domain/entities/user.dart';
import 'package:lms/features/auth/domain/repositories/auth_repository.dart';

import '../../../../api_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource, required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<Either<Failure, bool>> requestAuth(String userIdentifier) async {
    try {
      final result = await remoteDataSource.requestAuth(userIdentifier);
      return Right(result);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyAuth(String code) async {
    try {
      final userModel = await remoteDataSource.verifyAuth(code);
      return Right(userModel);
    } on Failure catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentUser();

      // NEW: اگر عکس پروفایل وجود داشت، آن را دانلود کرده و Embedding را ذخیره کنید.
      final profileImageUrl = userModel.profile?.profileImage;

      if (profileImageUrl != null) {
        // تغییر مهم: await را حذف کنید. این کار باید در پس‌زمینه اجرا شود
        // تا صفحه اصلی به سرعت بارگذاری شود و در Loading گیر نکند.
        remoteDataSource.downloadAvatar(profileImageUrl).catchError((error) {
          // در صورت بروز خطا در دانلود یا استخراج Embedding، آن را فقط لاگ کنید
          // و ادامه دهید تا برنامه به خطا نخورد.
          print('⚠️ Error in background face setup: $error');
        });
      }

      // بلافاصله پس از دریافت اطلاعات کاربر از API، آن را برگردانید تا صفحه نمایش داده شود.
      return Right(userModel);
    } on Failure catch (e) {
      // خطای API (مانند عدم احراز هویت) همچنان باید کاربر را به صفحه ورود برگرداند.
      return Left(e);
    }
  }

  @override
  Future<void> logout() async {
    // 1. پاک کردن Access Token از Secure Storage
    await apiClient
        .deleteToken(); // از ApiClient متد حذف توکن را فراخوانی می‌کند

    // 2. پاک کردن کوکی‌ها (شامل uck_ses) از CookieJar
    await apiClient.clearCookies(); // <<<--- اضافه شده
  }

  @override
  Future<Either<Failure, bool>> registerFace(String imagePath) async {
    try {
      final result = await remoteDataSource.registerFace(imagePath);
      return Right(result);
    } on Failure catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<Failure, bool>> compareFaceWithAvatar(
    String liveImagePath,
  ) async {
    try {
      final isMatch = await remoteDataSource.compareFaceWithAvatar(
        liveImagePath,
      );
      return Right(isMatch);
    } on Failure catch (e) {
      return Left(e);
    }
  }
}
