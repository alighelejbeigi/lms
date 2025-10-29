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
  Future<String> downloadAvatar(String relativeUrl);
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
    print('✅ Embedding saved locally: ${embedding.length} values');
  }

  @override
  Future<List<double>?> _getLocalEmbedding() async {
    final embeddingString = await apiClient.storage.read(key: _EMBEDDING_KEY);
    if (embeddingString == null) {
      print('❌ No saved embedding found');
      return null;
    }

    try {
      final embedding = embeddingString.split(',').map(double.parse).toList();
      print('✅ Embedding loaded: ${embedding.length} values');
      return embedding;
    } catch (e) {
      print('❌ Error parsing saved embedding: $e');
      return null;
    }
  }

  @override
  Future<bool> compareFaceWithAvatar(String liveImagePath) async {
    try {
      print('🔍 Starting face comparison...');

      final savedEmbedding = await _getLocalEmbedding();
      if (savedEmbedding == null) {
        throw const ServerFailure(
          message: 'بردار ویژگی ذخیره شده یافت نشد. ابتدا چهره را ثبت کنید.',
        );
      }

      print('📸 Extracting embedding from live image...');
      final isMatch = await faceRecognizer.compare(
        liveImagePath,
        savedEmbedding,
      );

      print('✅ Comparison result: ${isMatch ? "MATCH ✓" : "NO MATCH ✗"}');
      return isMatch;
    } on Failure catch (_) {
      rethrow;
    } catch (e) {
      print('❌ Comparison error: $e');
      throw ServerFailure(message: 'خطا در تشخیص چهره: ${e.toString()}');
    }
  }

  void _handleDioException(DioException e) {
    if (e.response != null) {
      final message = e.response!.data['message'] ?? 'خطای سمت سرور';
      throw ServerFailure(message: message, statusCode: e.response!.statusCode);
    } else {
      throw const ServerFailure(message: 'خطای ارتباط با شبکه');
    }
  }

  @override
  Future<bool> requestAuth(String userIdentifier) async {
    final Map<String, dynamic> requestBody = {
      'method': 'username',
      'user': userIdentifier,
    };

    try {
      await client.post('/auth', data: requestBody);
      return true;
    } on DioException catch (e) {
      _handleDioException(e);
      return false;
    }
  }

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
        await apiClient.saveToken(responseData['accessToken']);
      } else {
        throw const DataParsingFailure(message: 'توکن در پاسخ یافت نشد.');
      }

      return await getCurrentUser();
    } on DioException catch (e) {
      _handleDioException(e);
      return UserModel(id: '', username: '', mobile: '', role: '');
    }
  }

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
      return UserModel(id: '', username: '', mobile: '', role: '');
    }
  }

  @override
  Future<bool> registerFace(String imagePath) async {
    try {
      print('📤 Starting face registration...');

      // مرحله 1: ارسال تصویر به سرور
      final imageFile = File(imagePath);
      final formData = FormData.fromMap({
        'userId': '93604b2a-49e5-4428-ac46-b73de880595c',
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'user_face_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'address': '',
        'nickName': '',
        'username': 'superadmin2',
      });

      final response = await client.patch(
        '/user',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final message = response.data['message'] ?? 'ثبت چهره ناموفق بود.';
        throw ServerFailure(message: message, statusCode: response.statusCode);
      }

      print('✅ Image uploaded to server successfully');

      // مرحله 2: استخراج و ذخیره بردار ویژگی محلی
      print('🔄 Extracting face embedding from registered image...');
      final embedding = await faceRecognizer.getFaceEmbedding(imagePath);

      if (embedding == null) {
        throw const ServerFailure(
          message: 'خطا در استخراج بردار ویژگی از تصویر ثبت شده',
        );
      }

      print('💾 Saving embedding locally...');
      await _saveLocalEmbedding(embedding);

      print('✅ Face registration completed successfully!');
      return true;
    } on DioException catch (e) {
      _handleDioException(e);
      return false;
    } catch (e) {
      print('❌ Registration error: $e');
      throw ServerFailure(message: 'خطا در ثبت چهره: ${e.toString()}');
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
