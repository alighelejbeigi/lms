// lib/features/auth/presentation/cubit/auth_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:lms/core/errors/failures.dart';
import 'package:lms/features/auth/domain/repositories/auth_repository.dart';
import 'package:lms/features/auth/domain/usecases/request_auth.dart';
import 'package:lms/features/auth/domain/usecases/verify_auth.dart';
import 'package:lms/features/auth/presentation/cubit/auth_state.dart';

import '../../domain/usecases/compare_face_with_avatar.dart';
import '../../domain/usecases/register_face.dart';

class AuthCubit extends Cubit<AuthState> {
  final RequestAuth requestAuthUseCase;
  final VerifyAuth verifyAuthUseCase;
  final RegisterFace registerFaceUseCase;
  final AuthRepository authRepository;
  final CompareFaceWithAvatar compareFaceUseCase;

  AuthCubit({
    required this.requestAuthUseCase,
    required this.verifyAuthUseCase,
    required this.authRepository,
    required this.registerFaceUseCase,
    required this.compareFaceUseCase,
  }) : super(const AuthInitial());

  // --- متد مقایسه چهره ---
  Future<void> compareFace(String imagePath) async {
    print('🔵 AuthCubit: compareFace called with: $imagePath');
    emit(const FaceProcessingLoading());

    final failureOrIsMatch = await compareFaceUseCase(imagePath);

    failureOrIsMatch.fold(
      ifLeft: (failure) {
        print(
          '🔴 AuthCubit: compareFace failed: ${_mapFailureToMessage(failure)}',
        );
        emit(FaceProcessingError(message: _mapFailureToMessage(failure)));
      },
      ifRight: (isMatch) {
        print('🟢 AuthCubit: compareFace result: $isMatch');
        emit(FaceProcessingSuccess(success: isMatch));
      },
    );
  }

  // --- متد ثبت چهره ---
  Future<void> registerFace(String imagePath) async {
    print('🔵 AuthCubit: registerFace called with: $imagePath');
    emit(const FaceProcessingLoading());

    final failureOrSuccess = await registerFaceUseCase(imagePath);

    failureOrSuccess.fold(
      ifLeft: (failure) {
        print(
          '🔴 AuthCubit: registerFace failed: ${_mapFailureToMessage(failure)}',
        );
        emit(FaceProcessingError(message: _mapFailureToMessage(failure)));
      },
      ifRight: (success) {
        print('🟢 AuthCubit: registerFace success: $success');
        emit(FaceProcessingSuccess(success: success));
      },
    );
  }

  Future<void> requestAuth(String userIdentifier) async {
    emit(const AuthLoading(step: AuthStep.identifier));

    final failureOrSuccess = await requestAuthUseCase(userIdentifier);

    failureOrSuccess.fold(
      ifLeft:
          (failure) => emit(
            AuthError(
              message: _mapFailureToMessage(failure),
              step: AuthStep.identifier,
            ),
          ),
      ifRight:
          (success) => emit(
            const AuthRequestSuccess(
              message: 'لطفاً کد تایید یا رمز عبور را وارد کنید.',
            ),
          ),
    );
  }

  Future<void> verifyAuth(String code) async {
    emit(const AuthLoading(step: AuthStep.password));

    final failureOrUser = await verifyAuthUseCase(code);

    failureOrUser.fold(
      ifLeft:
          (failure) => emit(
            AuthError(
              message: _mapFailureToMessage(failure),
              step: AuthStep.password,
            ),
          ),
      ifRight: (user) => emit(AuthSuccess(user: user)),
    );
  }

  Future<void> checkAuthStatus() async {
    final failureOrUser = await authRepository.getCurrentUser();

    failureOrUser.fold(
      ifLeft: (failure) => emit(const AuthInitial()),
      ifRight: (user) => emit(AuthSuccess(user: user)),
    );
  }

  Future<void> logout() async {
    await authRepository.logout();
    emit(const AuthInitial());
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'خطای سرور: ${failure.message}';
    } else if (failure is DataParsingFailure) {
      return 'خطا در تحلیل داده: ${failure.message}';
    }
    return 'خطای ناشناخته رخ داده است.';
  }
}
