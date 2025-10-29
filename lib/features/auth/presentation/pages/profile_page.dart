/*
// lib/features/auth/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lms/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:lms/features/auth/presentation/cubit/auth_state.dart';
import 'package:lms/features/auth/presentation/widgets/face_verification_dialog.dart';
import 'package:lms/routes/app_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showFaceVerificationDialog(BuildContext context) async {
    // باز کردن دیالوگ و ارسال Cubit به آن
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // جلوگیری از بسته شدن با کلیک خارج از دیالوگ
      builder:
          (ctx) => BlocProvider.value(
            // ارسال Cubit موجود
            value: BlocProvider.of<AuthCubit>(context),
            child: const FaceVerificationDialog(),
          ),
    );

    if (context.mounted) {
      if (result == true) {
        context.go(AppRoutes.successPage); // مطابقت داشت، هدایت به صفحه موفقیت
      } else if (result == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تایید چهره ناموفق بود. دوباره تلاش کنید.'),
          ),
        );
      }
    }
  }

  // ... (کد _buildUserInfo و build)

  @override
  Widget build(BuildContext context) {
    final AuthCubit authCubit = BlocProvider.of<AuthCubit>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('پروفایل کاربری و خدمات'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authCubit.logout(),
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // _buildUserInfo(state.user), // نمایش اطلاعات کاربر
                    Text(
                      'اطلاعات کاربر: ${state.user.username}',
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 40),

                    // --- دکمه باز کردن دیالوگ دوربین ---
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
                  ],
                ),
              ),
            );
          }
          // ... (سایر وضعیت‌ها)
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
*/
