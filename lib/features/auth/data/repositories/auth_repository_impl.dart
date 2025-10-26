// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:dart_either/dart_either.dart';
import 'package:lms/core/errors/failures.dart';
import 'package:lms/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lms/features/auth/domain/entities/user.dart';
import 'package:lms/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, bool>> requestAuth(String userIdentifier) async {
    try {
      final result = await remoteDataSource.requestAuth(userIdentifier);
      return Right(result);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyAuth(String code) async {
    try {
      final userModel = await remoteDataSource.verifyAuth(code);
      return Right(userModel);
    } on Failure catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentUser();
      return Right(userModel);
    } on Failure catch (e) {
      return Left(e);
    }
  }
}
