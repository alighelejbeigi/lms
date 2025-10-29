// lib/features/auth/presentation/pages/whoami_page.dart

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

  // متد برای باز کردن دیالوگ دوربین (با پارامتر تعیین حالت)
  void _showFaceVerificationDialog(
    BuildContext context, {
    required bool isRegistration,
  }) async {
    // <<<--- MODIFIED
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => BlocProvider.value(
            value: BlocProvider.of<AuthCubit>(context),
            child: FaceVerificationDialog(
              isRegistrationMode: isRegistration, // <<<--- Pass the mode
            ),
          ),
    );

    if (context.mounted) {
      if (result == true) {
        final message =
            isRegistration
                ? 'ثبت چهره با موفقیت انجام شد.'
                : 'تایید هویت با موفقیت انجام شد.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        // فقط اگر ثبت چهره بود (Registration)، به صفحه موفقیت هدایت شود
        if (isRegistration) {
          context.go(AppRoutes.successPage);
        }
      } else if (result == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عملیات ناموفق بود یا لغو شد.')),
        );
      }
    }
  }

  // ویجت کمکی برای نمایش اطلاعات کاربر
  Widget _buildUserInfo(UserEntity user) {
    const String baseUrl = "http://192.168.192.185:3001/";
    final String profileImagePath = user.profile?.profileImage ?? '';

    final String fullImageUrl =
        profileImagePath.startsWith('http')
            ? profileImagePath
            : (profileImagePath.isNotEmpty ? baseUrl + profileImagePath : '');

    final ImageProvider avatarImage =
        fullImageUrl.isNotEmpty
            ? NetworkImage(fullImageUrl) as ImageProvider
            : const AssetImage('assets/images/placeholder.png');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // عکس پروفایل
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: avatarImage,
            ),
            const SizedBox(height: 16),

            // نام و نام مستعار
            Text(
              user.profile?.nickName ?? '---',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
            Text(
              'نقش: ${user.role}',
              style: const TextStyle(fontSize: 16, color: Colors.blueAccent),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 30),

            // جدول جزئیات
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  _buildDetailRow('شناسه کاربری', user.id),
                  _buildDetailRow('نام کاربری', user.username),
                  _buildDetailRow('شماره موبایل', user.mobile),
                  _buildDetailRow('کد ERP', user.erpCode),
                  _buildDetailRow(
                    'تایید هویت',
                    user.isVerified == true ? 'تایید شده' : 'تایید نشده',
                  ),
                  _buildDetailRow(
                    'فروشنده عمده',
                    user.wholeSeller == true ? 'بله' : 'خیر',
                  ),
                  _buildDetailRow('نوع قیمت', user.priceType?.toString()),
                  _buildDetailRow(
                    'شناسه پروفایل',
                    user.profile?.id?.toString(),
                  ),
                  _buildDetailRow('آدرس', user.profile?.address),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ویجت کمکی برای نمایش یک ردیف جزئیات
  Widget _buildDetailRow(String label, dynamic value) {
    String displayValue =
        (value == null || value.toString().isEmpty) ? '---' : value.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              displayValue,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.left,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
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
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            context.go(AppRoutes.login);
          }
        },
        builder: (context, state) {
          if (state is AuthSuccess) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildUserInfo(state.user),
                  const SizedBox(height: 40),

                  // دکمه ثبت چهره (Registration - ML Kit)
                  ElevatedButton.icon(
                    onPressed:
                        () => _showFaceVerificationDialog(
                          context,
                          isRegistration: true,
                        ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text(
                      'ثبت چهره (ML Kit)',
                    ), // <<<--- For Registration
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // دکمه تایید هویت (Comparison - TFLite)
                  ElevatedButton.icon(
                    onPressed:
                        () => _showFaceVerificationDialog(
                          context,
                          isRegistration: false,
                        ),
                    icon: const Icon(Icons.verified_user),
                    label: const Text(
                      'تایید هویت (TFLite)',
                    ), // <<<--- For Comparison
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // دکمه رفرش
                  ElevatedButton(
                    onPressed: () => authCubit.checkAuthStatus(),
                    child: const Text('بارگذاری مجدد اطلاعات'),
                  ),
                ],
              ),
            );
          } else if (state is AuthError) {
            return Center(
              child: Text(
                'خطا در بارگذاری اطلاعات: ${state.message}',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            );
          }

          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          );
        },
      ),
    );
  }
}
