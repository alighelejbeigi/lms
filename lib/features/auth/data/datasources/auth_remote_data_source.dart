// lib/features/auth/data/datasources/auth_remote_data_source.dart

import 'package:dio/dio.dart';
import 'package:lms/api_client.dart';
import 'package:lms/core/errors/failures.dart';
import 'package:lms/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<bool> requestAuth(String userIdentifier);
  Future<UserModel> verifyAuth(String code);
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio client;
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.client, required this.apiClient});

  // متد کمکی برای مدیریت خطای Dio
  void _handleDioException(DioException e) {
    if (e.response != null) {
      final message = e.response!.data['message'] ?? 'خطای سمت سرور';
      throw ServerFailure(message: message, statusCode: e.response!.statusCode);
    } else {
      throw const ServerFailure(message: 'خطای ارتباط با شبکه');
    }
  }

  // --- مرحله ۱: ارسال اطلاعات کاربر ---
  @override
  Future<bool> requestAuth(String userIdentifier) async {
    final Map<String, dynamic> requestBody = {
      'method': 'username',
      'user': userIdentifier,
    };

    try {
      await client.post('/auth', data: requestBody);
      // کوکی uck_ses در اینجا توسط CookieManager در ApiClient ذخیره می‌شود.
      return true;
    } on DioException catch (e) {
      _handleDioException(e);
      return false; // برای پوشش‌دهی تایپ متد
    }
  }

  // --- مرحله ۲: تأیید رمز عبور و دریافت توکن ---
  @override
  Future<UserModel> verifyAuth(String code) async {
    final Map<String, dynamic> requestBody = {'code': code};

    try {
      final response = await client.post(
        '/auth/verify',
        data: requestBody,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final responseData = response.data;
      if (responseData['accessToken'] != null) {
        // ذخیره توکن برای درخواست‌های بعدی
        await apiClient.saveToken(responseData['accessToken']);
      } else {
        throw const DataParsingFailure(message: 'توکن در پاسخ یافت نشد.');
      }

      // فراخوانی whoami برای دریافت اطلاعات کامل کاربر پس از ورود موفق
      return await getCurrentUser();
    } on DioException catch (e) {
      _handleDioException(e);
      return UserModel(
        id: '',
        username: '',
        mobile: '',
        role: '',
      ); // برای پوشش‌دهی تایپ متد
    }
  }

  // --- مرحله Whoami: دریافت اطلاعات کاربر ---
  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await client.get('/auth/whoami');

      if (response.data is Map<String, dynamic>) {
        return UserModel.fromJson(response.data);
      } else {
        throw const DataParsingFailure();
      }
    } on DioException catch (e) {
      _handleDioException(e);
      return UserModel(
        id: '',
        username: '',
        mobile: '',
        role: '',
      ); // برای پوشش‌دهی تایپ متد
    }
  }
}
