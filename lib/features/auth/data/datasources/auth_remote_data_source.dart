// lib/features/auth/data/datasources/auth_remote_data_source.dart

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lms/api_client.dart';
import 'package:lms/core/errors/failures.dart';
import 'package:lms/features/auth/data/models/user_model.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/tflite/face_recognizer.dart';

abstract class AuthRemoteDataSource {
  Future<bool> requestAuth(String userIdentifier);

  Future<UserModel> verifyAuth(String code);

  Future<UserModel> getCurrentUser();

  Future<bool> registerFace(String imagePath);

  Future<String> downloadAvatar(String relativeUrl); // <<<--- متد جدید
  Future<bool> compareFaceWithAvatar(String liveImagePath);

  Future<void> _saveLocalEmbedding(List<double> embedding);

  Future<List<double>?> _getLocalEmbedding();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio client;
  final ApiClient apiClient;
  final FaceRecognizer faceRecognizer;

  AuthRemoteDataSourceImpl({
    required this.client,
    required this.apiClient,
    required this.faceRecognizer,
  });
  static const String _EMBEDDING_KEY = 'user_face_embedding';

  @override
  Future<void> _saveLocalEmbedding(List<double> embedding) async {
    final embeddingString = embedding.join(',');
    await apiClient.storage.write(key: _EMBEDDING_KEY, value: embeddingString);
  }

  @override
  Future<List<double>?> _getLocalEmbedding() async {
    final embeddingString = await apiClient.storage.read(key: _EMBEDDING_KEY);
    if (embeddingString == null) return null;

    try {
      return embeddingString.split(',').map(double.parse).toList();
    } catch (e) {
      print('Error parsing saved embedding: $e');
      return null;
    }
  }

  @override
  Future<bool> compareFaceWithAvatar(String liveImagePath) async {
    try {
      final savedEmbedding = await _getLocalEmbedding();
      if (savedEmbedding == null) {
        throw const ServerFailure(
          message:
              'بردار ویژگی ذخیره شده برای مقایسه یافت نشد. ابتدا چهره را ثبت کنید.',
        );
      }

      // استفاده از TFLite FaceRecognizer برای مقایسه
      final isMatch = await faceRecognizer.compare(
        liveImagePath,
        savedEmbedding,
      );

      return isMatch;
    } on Failure catch (_) {
      rethrow;
    } catch (e) {
      throw ServerFailure(
        message: 'خطا در تشخیص چهره با TFLite: ${e.toString()}',
      );
    }
  }

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
        'username': 'superadmin',
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

  @override
  Future<String> downloadAvatar(String relativeUrl) async {
    try {
      final dir = await getTemporaryDirectory();
      final filename = relativeUrl.split('/').last;
      final path = '${dir.path}/$filename';

      final fullUrl = apiClient.dio.options.baseUrl + relativeUrl;

      final response = await client.download(
        fullUrl,
        path,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        return path;
      } else {
        throw ServerFailure(
          message: 'خطا در دانلود آواتار: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw ServerFailure(
        message: 'خطای سیستمی در دانلود فایل: ${e.toString()}',
      );
    }
  }
}
