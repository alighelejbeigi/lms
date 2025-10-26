// lib/features/auth/data/datasources/auth_remote_data_source.dart

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lms/api_client.dart';
import 'package:lms/core/errors/failures.dart';
import 'package:lms/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<bool> requestAuth(String userIdentifier);

  Future<UserModel> verifyAuth(String code);

  Future<UserModel> getCurrentUser();

  Future<bool> registerFace(String imagePath);
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

  @override
  Future<bool> registerFace(String imagePath) async {
    try {
      final imageFile = File(imagePath);

      final formData = FormData.fromMap({
        'userId': '93604b2a-49e5-4428-ac46-b73de880595c',
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'user_face_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'address': '',
        'nickName': '',
        'username': 'SuperAdmin2',
      });

      // فرض می‌کنیم API برای ثبت چهره /auth/register_face باشد
      final response = await client.patch(
        '/user', // <<<--- Endpoint جدید
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      // اگر کد 200 یا 201 باشد، ثبت موفق بوده است.
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final message = response.data['message'] ?? 'ثبت چهره ناموفق بود.';
        throw ServerFailure(message: message, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      _handleDioException(e);
      return false;
    } catch (e) {
      throw ServerFailure(
        message: 'خطای سمت کاربر یا پردازش فایل: ${e.toString()}',
      );
    }
  }
}
