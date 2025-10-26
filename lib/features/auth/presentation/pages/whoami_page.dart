// lib/features/auth/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lms/features/auth/domain/entities/user.dart';
import 'package:lms/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:lms/features/auth/presentation/cubit/auth_state.dart';
import 'package:lms/features/auth/presentation/widgets/face_verification_dialog.dart';
import 'package:lms/routes/app_router.dart';

class WhoamiPage extends StatelessWidget {
  const WhoamiPage({super.key});

  // متد برای باز کردن دیالوگ دوربین
  void _showFaceVerificationDialog(BuildContext context) async {
    // باز کردن دیالوگ و دریافت نتیجه (true/false)
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => BlocProvider.value(
            // ارسال Cubit موجود به دیالوگ برای اجرای compareFace
            value: BlocProvider.of<AuthCubit>(context),
            child: const FaceVerificationDialog(),
          ),
    );

    if (context.mounted) {
      if (result == true) {
        context.go(AppRoutes.successPage); // مطابقت داشت
      } else if (result == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تایید چهره ناموفق بود یا لغو شد.')),
        );
      }
    }
  }

  // ویجت کمکی برای نمایش اطلاعات کاربر
  Widget _buildUserInfo(UserEntity user) {
    return Column(
      children: [
        const Text(
          'اطلاعات کاربری:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 10),
        Text(
          'خوش آمدید، ${user.username}!',
          style: const TextStyle(fontSize: 18),
          textDirection: TextDirection.rtl,
        ), //
        Text(
          'شماره موبایل: ${user.mobile}',
          textDirection: TextDirection.rtl,
        ), //
        Text('نقش: ${user.role}', textDirection: TextDirection.rtl), //
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthCubit authCubit = BlocProvider.of<AuthCubit>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('پروفایل کاربری'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authCubit.logout(),
          ),
        ],
      ),
      // BlocConsumer برای شنیدن تغییرات وضعیت (مثل خروج) و نمایش داده (AuthSuccess)
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            // خروج موفقیت‌آمیز، هدایت به صفحه ورود
            context.go(AppRoutes.login);
          }
        },
        builder: (context, state) {
          if (state is AuthSuccess) {
            // وضعیت موفقیت احراز هویت: نمایش داده‌های Whoami
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildUserInfo(state.user),
                    const SizedBox(height: 40),

                    ElevatedButton.icon(
                      onPressed: () => _showFaceVerificationDialog(context),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('شروع تایید چهره هوشمند'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => authCubit.checkAuthStatus(),
                      child: const Text('بارگذاری مجدد اطلاعات'),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is AuthLoading &&
              state.step == AuthStep.identifier) {
            // در حال بارگذاری اولیه اطلاعات کاربر (whoami)
            return const Center(child: CircularProgressIndicator());
          } else if (state is AuthError) {
            // اگر در بارگذاری whoami خطا رخ داد
            return Center(
              child: Text(
                'خطا در بارگذاری اطلاعات: ${state.message}',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            );
          }

          // حالت پیش‌فرض (مثل زمانی که AuthCubit هنوز AuthSuccess را Emit نکرده یا در حال پردازش‌های دیگر است)
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
