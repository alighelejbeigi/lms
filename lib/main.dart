// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lms/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:lms/routes/app_router.dart';

import 'injection_container.dart' as di;

void main() async {
  // اطمینان از initialize شدن Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Initializing app...');

  // تزریق وابستگی‌ها
  await di.init(); // <<<--- حالا async است

  print('✅ Dependencies initialized');

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
