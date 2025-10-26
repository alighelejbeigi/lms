// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart'; // <<<--- استفاده از GetIt
import 'package:lms/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:lms/routes/app_router.dart';

import 'injection_container.dart' as di;

void main() {
  di.init(); // اجرای تزریق وابستگی
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // استفاده از BlocProvider برای در دسترس قرار دادن AuthCubit
    return BlocProvider(
      // استفاده از sl<AuthCubit>() برای گرفتن AuthCubit تزریق شده
      create: (context) => GetIt.instance.get<AuthCubit>()..checkAuthStatus(),
      child: MaterialApp.router(
        title: 'LMS',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}
