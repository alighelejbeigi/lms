// lib/features/auth/presentation/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lms/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:lms/features/auth/presentation/cubit/auth_state.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../routes/app_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _inputController = TextEditingController();
  final String _forgotPasswordUrl = "https://your-forget-password-url.com";

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // دسترسی به Cubit تزریق شده
    final AuthCubit authCubit = BlocProvider.of<AuthCubit>(context);

    // استفاده از BlocConsumer برای مدیریت وضعیت‌ها و رویدادها
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          // ورود موفق: هدایت به Whoami
          context.go(AppRoutes.whoami);
        }
        if (state is AuthInitial) {
          // خروج موفق یا وضعیت اولیه: مطمئن شوید که در صفحه‌ی Login هستیم
          // این خط ضروری نیست زیرا GoRouter redirect را مدیریت می‌کند،
          // اما برای اطمینان از پاک بودن URL خوب است.
          context.go(AppRoutes.login);
        }
      },
      builder: (context, state) {
        // تعیین متغیرهای UI بر اساس وضعیت فعلی
        bool isLoading = state is AuthLoading;
        AuthStep currentStep = AuthStep.identifier;
        String message = '';

        if (state is AuthInitial) {
          message = state.message;
          currentStep = AuthStep.identifier;
        } else if (state is AuthRequestSuccess) {
          message = state.message;
          currentStep = AuthStep.password;
        } else if (state is AuthError) {
          message = state.message;
          currentStep = state.step;
        } else if (state is AuthLoading) {
          message = 'در حال بارگذاری...';
          currentStep = state.step;
        }

        String buttonText =
            currentStep == AuthStep.identifier ? 'ادامه' : 'ورود';
        String labelText =
            currentStep == AuthStep.identifier
                ? 'نام کاربری، کد ملی یا شماره موبایل'
                : 'کد تایید یا رمز عبور';

        // پاک کردن فیلد پس از رفتن به مرحله جدید
        if (state is AuthRequestSuccess) {
          _inputController.clear();
        }

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
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        isLoading || state is AuthRequestSuccess
                            ? Colors.blue
                            : (state is AuthError
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
                        isLoading
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
                      currentStep == AuthStep.identifier
                          ? TextInputType.text
                          : TextInputType.visiblePassword,
                  obscureText: currentStep == AuthStep.password,
                  textDirection: TextDirection.rtl,
                  onSubmitted: (_) {
                    if (currentStep == AuthStep.identifier) {
                      authCubit.requestAuth(_inputController.text);
                    } else {
                      authCubit.verifyAuth(_inputController.text);
                    }
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () {
                              if (currentStep == AuthStep.identifier) {
                                authCubit.requestAuth(_inputController.text);
                              } else {
                                authCubit.verifyAuth(_inputController.text);
                              }
                            },
                    child: Text(buttonText),
                  ),
                ),
                if (currentStep == AuthStep.password)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: InkWell(
                      onTap: () async {
                        final uri = Uri.parse(_forgotPasswordUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('لینک قابل باز شدن نیست.'),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'فراموشی رمز ورود',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
