// lib/features/auth/presentation/pages/success_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lms/routes/app_router.dart';

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('موفقیت'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'تایید چهره با موفقیت انجام شد!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                context.go(AppRoutes.whoami);
              },
              child: const Text('بازگشت به اطلاعات کاربری'),
            ),
          ],
        ),
      ),
    );
  }
}
