/*
// lib/login_page.dart

// وارد کردن بسته‌های مدیریت کوکی
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lms/whoami_page.dart';

import 'api_client.dart';

// مراحل احراز هویت
enum AuthStep { identifier, password }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _inputController = TextEditingController();

  // تعریف CookieJar در سطح کلاس
  final CookieJar _cookieJar = CookieJar();

  // ایجاد نمونه Dio و اضافه کردن CookieManager
  // اینترسپتور کوکی، کوکی uck_ses را به صورت خودکار مدیریت می‌کند.
  late final Dio _dio = ApiClient.instance.dio;

  String _message =
      'لطفاً نام کاربری، کد ملی یا شماره موبایل خود را وارد کنید.';
  bool _isLoading = false;
  AuthStep _currentStep = AuthStep.identifier; // شروع از مرحله اول

  // Regex برای تشخیص نوع ورودی
  final RegExp _nationalIdRegExp = RegExp(r'^\d{10}$');
  final RegExp _mobileNumberRegExp = RegExp(r'^09\d{9}$');

  String _getInputType(String input) {
    if (_nationalIdRegExp.hasMatch(input)) {
      return 'کد ملی';
    } else if (_mobileNumberRegExp.hasMatch(input)) {
      return 'شماره موبایل';
    } else if (input.isNotEmpty) {
      return 'نام کاربری';
    }
    return 'Invalid';
  }

  // --- مدیریت خطاهای Dio ---
  void _handleDioError(DioException e) {
    String errorMessage = 'خطای نامشخص در شبکه.';
    if (e.response != null) {
      final responseData = e.response!.data;
      errorMessage =
          'خطا ${e.response!.statusCode}: ${responseData['message'] ?? 'خطای سمت سرور'}';
    } else {
      errorMessage = 'خطای ارتباط با سرور: ${e.message}';
    }
    setState(() => _message = errorMessage);
  }

  // --- مرحله ۱: ارسال نام کاربری/کد ملی/موبایل به /auth ---
  Future<void> _requestAuth() async {
    final input = _inputController.text.trim();
    final inputType = _getInputType(input);

    if (inputType == 'Invalid') {
      setState(() => _message = 'لطفاً یک ورودی معتبر وارد کنید.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'در حال ارسال درخواست احراز هویت...';
    });

    // ساخت body درخواست بر اساس ساختار "method" و "user"
    final Map<String, dynamic> requestBody = {
      'method': 'username',
      'user': input,
    };

    try {
      // API اول از JSON یا form-urlencoded استفاده می‌کند. ما JSON را امتحان می‌کنیم.
      final response = await _dio.post('/auth', data: requestBody);
      final responseData = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final apiMessage = responseData['message'] ?? 'پاسخ API: موفق';

        setState(() {
          _currentStep = AuthStep.password; // تغییر به مرحله ورود رمز
          _inputController.clear();
          _message = apiMessage; // نمایش پیام "کلمه عبور را وارد نمایید"
        });
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      setState(() => _message = 'خطای غیرمنتظره: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- مرحله ۲: ارسال کد/رمز عبور به /auth/verify ---
  Future<void> _verifyAuth() async {
    final code = _inputController.text.trim();

    if (code.isEmpty) {
      setState(() => _message = 'لطفاً کد/رمز عبور را وارد کنید.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'در حال ارسال کد تایید...';
    });

    // ساخت body درخواست برای /auth/verify
    final Map<String, dynamic> requestBody = {
      'code': code, // فیلد مورد نیاز API دوم
    };

    try {
      // API دوم از application/x-www-form-urlencoded استفاده می‌کند.
      // کوکی uck_ses (در صورت وجود) به صورت خودکار توسط CookieManager ارسال می‌شود.
      final response = await _dio.post(
        '/auth/verify',
        data: requestBody,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      // در صورت موفقیت، سرور توکن‌های نهایی را برمی‌گرداند.
      // final responseData = response.data;
      final responseData = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        // هدایت به صفحه اصلی (HomePage)
        final accessToken = responseData['accessToken']; //
        if (accessToken != null) {
          await ApiClient.instance.saveToken(accessToken);
        }
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WhoamiPage()),
          );
        }
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      setState(() => _message = 'خطای غیرمنتظره: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- ساختار UI ---

  @override
  Widget build(BuildContext context) {
    // تعیین متن دکمه و لیبل فیلد بر اساس مرحله
    String buttonText = _currentStep == AuthStep.identifier ? 'ادامه' : 'ورود';
    String labelText =
        _currentStep == AuthStep.identifier
            ? 'نام کاربری، کد ملی یا شماره موبایل'
            : 'کد تایید یا رمز عبور';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ورود به سامانه'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    _isLoading
                        ? Colors.blue
                        : (_message.contains('خطا')
                            ? Colors.red
                            : Colors.black87),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: labelText,
                suffixIcon:
                    _isLoading
                        ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _inputController.clear,
                        ),
              ),
              textAlign: TextAlign.right,
              keyboardType:
                  _currentStep == AuthStep.identifier
                      ? TextInputType.text
                      : TextInputType.visiblePassword,
              obscureText: _currentStep == AuthStep.password, // مخفی کردن رمز
              textDirection: TextDirection.rtl,
              onSubmitted:
                  (_) =>
                      _currentStep == AuthStep.identifier
                          ? _requestAuth()
                          : _verifyAuth(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          if (_currentStep == AuthStep.identifier) {
                            _requestAuth();
                          } else {
                            _verifyAuth();
                          }
                        },
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
