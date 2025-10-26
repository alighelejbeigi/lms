// lib/api_client.dart

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// یک کلاس برای مدیریت توکن و نمونه Dio در سراسر برنامه
class ApiClient {
  final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final CookieJar _cookieJar = CookieJar();

  static const String _TOKEN_KEY = 'access_token';

  ApiClient._internal()
    : dio = Dio(
        BaseOptions(
          baseUrl: 'http://192.168.192.185:3001',
          contentType: 'application/json',
        ),
      ) {
    // 1. اضافه کردن Cookie Manager برای مدیریت کوکی uck_ses
    dio.interceptors.add(CookieManager(_cookieJar));

    // 2. اضافه کردن Token Interceptor برای مدیریت Access Token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _TOKEN_KEY);
          if (token != null &&
              options.path != '/auth' &&
              options.path != '/auth/verify') {
            // افزودن توکن به هدر Authorization به صورت Bearer
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  static final ApiClient _instance = ApiClient._internal();

  // دسترسی به نمونه سینگلتون Dio
  static ApiClient get instance => _instance;

  // متد ذخیره توکن
  Future<void> saveToken(String token) async {
    await _storage.write(key: _TOKEN_KEY, value: token);
  }

  // عمومی کردن TOKEN_KEY
  static const String TOKEN_KEY = 'access_token'; // <<<--- تغییر یافته

  // Getter عمومی برای دسترسی به storage
  FlutterSecureStorage get storage => _storage; // <<<--- متد Getter جدید
  // متد حذف توکن (برای خروج از حساب)
  Future<void> deleteToken() async {
    await _storage.delete(key: _TOKEN_KEY);
  }

  Future<void> clearCookies() async {
    await _cookieJar.deleteAll(); // <<<--- اضافه شده
  }
}
