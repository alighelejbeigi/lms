// lib/features/auth/domain/usecases/request_auth.dart

import 'package:dart_either/dart_either.dart';
import 'package:lms/core/errors/failures.dart';
import 'package:lms/features/auth/domain/repositories/auth_repository.dart';

class RequestAuth {
  final AuthRepository repository;

  RequestAuth(this.repository);

  Future<Either<Failure, bool>> call(String userIdentifier) async {
    return await repository.requestAuth(userIdentifier);
  }
}
