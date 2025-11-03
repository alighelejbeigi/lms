// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lms/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:lms/routes/app_router.dart';

import 'core/tflite/face_recognizer.dart';
import 'injection_container.dart' as di;

void main() async {
  // اطمینان از مقداردهی اولیه bindings برای اجرای عملیات async
  WidgetsFlutterBinding.ensureInitialized();

  di.init(); // اجرای تزریق وابستگی

  // NEW: بارگذاری مدل TFLite به صورت همزمان (Awaited) قبل از اجرای برنامه
  try {
    // از GetIt برای گرفتن نمونه FaceRecognizer استفاده کنید
    await GetIt.instance.get<FaceRecognizer>().loadModel();
    print('TFLite FaceRecognizer model initialized successfully.');
  } catch (e) {
    print('🔴 FATAL ERROR: Failed to load FaceRecognizer model: $e');
    // در صورت عدم موفقیت در بارگذاری مدل، احتمالاً برنامه به درستی کار نخواهد کرد.
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance.get<AuthCubit>()..checkAuthStatus(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
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
