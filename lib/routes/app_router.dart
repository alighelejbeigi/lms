// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lms/api_client.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/success_page.dart';
import '../features/auth/presentation/pages/whoami_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String whoami = '/whoami';
  static const String successPage = '/successPage';
}

final GoRouter router = GoRouter(
  // مسیر اولیه هنگام راه‌اندازی برنامه
  initialLocation: AppRoutes.login,

  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.whoami,
      builder: (context, state) => const WhoamiPage(),
    ),
    GoRoute(
      path: AppRoutes.successPage,
      builder: (context, state) => const SuccessPage(),
    ),
  ],

  // مدیریت ریدایرکت‌ها
  redirect: (context, state) async {
    // از آنجا که GoRouter قبل از BuildContext کامل اجرا می‌شود،
    // چک کردن وضعیت Cubit کمی پیچیده است. از این رو، چک کردن توکن خام
    // در سطح زیرساخت (storage) بهترین روش برای GoRouter در زمان راه‌اندازی است.

    // اگرچه GetX در main.dart تزریق شده است، ما به چک کردن storage ادامه می‌دهیم
    final token = await ApiClient.instance.storage.read(
      key: ApiClient.TOKEN_KEY,
    );

    final isAuthenticated = token != null;
    final isLoggingIn = state.uri.path == AppRoutes.login;
    final isWhoami = state.uri.path == AppRoutes.whoami;

    if (!isAuthenticated && isWhoami) {
      return AppRoutes.login;
    }

    if (isAuthenticated && isLoggingIn) {
      return AppRoutes.whoami;
    }

    return null;
  },

  // لیست خطا (اختیاری)
  errorBuilder:
      (context, state) => Scaffold(
        body: Center(child: Text('صفحه مورد نظر یافت نشد: ${state.error}')),
      ),
);
