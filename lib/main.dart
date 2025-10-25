// lib/main.dart

import 'package:flutter/material.dart';
import 'package:lms/login_page.dart';
// import 'package:lms/home_page.dart'; // اگرچه در LoginPage استفاده می‌شود، بهتر است اینجا هم برای جلوگیری از خطای وابستگی در مراحل بعدی باشد

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LMS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(), // صفحه اصلی شما
    );
  }
}
