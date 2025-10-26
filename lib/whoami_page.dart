/*
// lib/whoami_page.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lms/api_client.dart';

import 'login_page.dart';

class WhoamiPage extends StatefulWidget {
  const WhoamiPage({super.key});

  @override
  State<WhoamiPage> createState() => _WhoamiPageState();
}

class _WhoamiPageState extends State<WhoamiPage> {
  String _userInfo = 'در حال بارگذاری اطلاعات...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      setState(() => _isLoading = true);

      // فراخوانی API محافظت‌شده. توکن Bearer به‌طور خودکار توسط Interceptor اضافه می‌شود.
      final response = await ApiClient.instance.dio.get('/auth/whoami'); //

      final responseData = response.data;

      if (response.statusCode == 200) {
        //
        String username = responseData['username'] ?? 'نام کاربری نامشخص'; //
        String mobile = responseData['mobile'] ?? 'شماره موبایل نامشخص'; //
        String role = responseData['role'] ?? 'نقش نامشخص'; //

        setState(() {
          _userInfo =
              'خوش آمدید، $username!\n'
              'شماره موبایل: $mobile\n'
              'نقش: $role';
        });
      }
    } on DioException catch (e) {
      String message = 'خطا در بارگذاری اطلاعات.';
      if (e.response?.statusCode == 401) {
        message = 'خطای احراز هویت: توکن نامعتبر یا منقضی شده است.';
      } else if (e.response != null) {
        message = 'خطای سرور ${e.response!.statusCode}';
      }
      setState(() => _userInfo = message);
    } catch (e) {
      setState(() => _userInfo = 'خطای غیرمنتظره: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اطلاعات کاربری (Whoami)'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                    _userInfo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                    textDirection: TextDirection.rtl,
                  ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchUserInfo,
                child: const Text('بارگذاری مجدد اطلاعات'),
              ),
              const SizedBox(height: 20),
              // دکمه خروج (برای مثال)
              ElevatedButton(
                onPressed: () async {
                  await ApiClient.instance.deleteToken();
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  }
                },
                child: const Text('خروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
