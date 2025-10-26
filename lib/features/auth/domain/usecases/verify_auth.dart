// lib/features/auth/domain/usecases/verify_auth.dart

import 'package:dart_either/dart_either.dart';
import 'package:lms/core/errors/failures.dart';
import 'package:lms/features/auth/domain/entities/user.dart';
import 'package:lms/features/auth/domain/repositories/auth_repository.dart';

class VerifyAuth {
  final AuthRepository repository;

  VerifyAuth(this.repository);

  Future<Either<Failure, UserEntity>> call(String code) async {
    return await repository.verifyAuth(code);
  }
}
