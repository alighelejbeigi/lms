// lib/features/auth/domain/usecases/register_face.dart

import 'package:dart_either/dart_either.dart';
import 'package:lms/core/errors/failures.dart';
import 'package:lms/features/auth/domain/repositories/auth_repository.dart';

class RegisterFace {
  final AuthRepository repository;

  RegisterFace(this.repository);

  // خروجی: Either<Failure, bool> که نشان می‌دهد ثبت موفق بوده یا نه
  Future<Either<Failure, bool>> call(String imagePath) async {
    return await repository.registerFace(imagePath);
  }
}
