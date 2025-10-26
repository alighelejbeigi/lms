// lib/features/auth/presentation/pages/whoami_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lms/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:lms/features/auth/presentation/cubit/auth_state.dart';
import 'package:lms/routes/app_router.dart';

import '../../domain/entities/user.dart';

class WhoamiPage extends StatelessWidget {
  const WhoamiPage({super.key});

  // --- متدهای کمکی برای نمایش وضعیت ---

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
        ),
        Text('شماره موبایل: ${user.mobile}', textDirection: TextDirection.rtl),
        Text('نقش: ${user.role}', textDirection: TextDirection.rtl),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthCubit authCubit = BlocProvider.of<AuthCubit>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('اطلاعات کاربری (Whoami)'),
        backgroundColor: Colors.blueGrey,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            if (context.mounted) {
              context.go(AppRoutes.login); // <<<--- تضمین هدایت به Login
            }
          }
        },
        builder: (context, state) {
          Widget content;

          if (state is AuthSuccess) {
            content = _buildUserInfo(state.user);
          } else {
            // این حالت‌ها نباید رخ دهند، زیرا GoRouter از ورود به این صفحه جلوگیری می‌کند
            content = const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text(
                  'در حال بررسی وضعیت یا بارگذاری اطلاعات...',
                  textDirection: TextDirection.rtl,
                ),
              ],
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  content,
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed:
                        () =>
                            authCubit
                                .checkAuthStatus(), // یا متد مجزا برای whoami
                    child: const Text('بارگذاری مجدد اطلاعات'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => authCubit.logout(),
                    child: const Text('خروج'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
