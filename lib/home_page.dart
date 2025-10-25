// lib/home_page.dart

import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صفحه اصلی'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'ورود موفقیت‌آمیز بود! 🎉',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
