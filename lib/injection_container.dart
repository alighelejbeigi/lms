// lib/injection_container.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// حذف ایمپورت get/get.dart
import 'package:get_it/get_it.dart'; // <<<--- تزریق وابستگی با GetIt
import 'package:lms/api_client.dart';
import 'package:lms/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lms/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lms/features/auth/domain/repositories/auth_repository.dart';
import 'package:lms/features/auth/domain/usecases/request_auth.dart';
import 'package:lms/features/auth/domain/usecases/verify_auth.dart';
import 'package:lms/features/auth/presentation/cubit/auth_cubit.dart';

import 'core/tflite/face_recognizer.dart';
import 'features/auth/domain/usecases/compare_face_with_avatar.dart';
import 'features/auth/domain/usecases/register_face.dart';

final sl = GetIt.instance; // Service Locator

Future<void> init() async {
  print('🔧 Starting dependency injection...');

  // Presentation layer
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      requestAuthUseCase: sl(),
      verifyAuthUseCase: sl(),
      authRepository: sl(),
      registerFaceUseCase: sl(),
      compareFaceUseCase: sl(),
    ),
  );

  // Domain layer (Use Cases)
  sl.registerLazySingleton(() => RequestAuth(sl()));
  sl.registerLazySingleton(() => VerifyAuth(sl()));
  sl.registerLazySingleton(() => RegisterFace(sl()));
  sl.registerLazySingleton(() => CompareFaceWithAvatar(sl()));

  // Domain layer (Repository)
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), apiClient: sl()),
  );

  // Data layer (Data Sources)
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      client: sl(),
      apiClient: sl(),
      faceRecognizer: sl(),
    ),
  );

  // External (Infrastructure)
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<ApiClient>(() => ApiClient.instance);
  sl.registerLazySingleton<Dio>(() => ApiClient.instance.dio);
  sl.registerLazySingleton<FaceRecognizer>(() => FaceRecognizer());

  // Load TFLite model (CRITICAL)
  print('🤖 Loading TFLite model...');
  try {
    await sl.get<FaceRecognizer>().loadModel();
    print('✅ TFLite model loaded successfully');
  } catch (e) {
    print('❌ Failed to load TFLite model: $e');
    print('⚠️ Face recognition will not work!');
  }

  print('✅ Dependency injection completed');
}
