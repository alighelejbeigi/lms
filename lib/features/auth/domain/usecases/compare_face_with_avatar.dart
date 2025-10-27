// lib/features/auth/domain/usecases/compare_face_with_avatar.dart
import 'package:dart_either/dart_either.dart';
import 'package:lms/core/errors/failures.dart';
import 'package:lms/features/auth/domain/repositories/auth_repository.dart';

class CompareFaceWithAvatar {
  final AuthRepository repository;

  CompareFaceWithAvatar(this.repository);

  Future<Either<Failure, bool>> call(String liveImagePath) async {
    return await repository.compareFaceWithAvatar(liveImagePath);
  }
}
