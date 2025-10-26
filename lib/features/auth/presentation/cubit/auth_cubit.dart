// lib/features/auth/presentation/cubit/auth_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:lms/core/errors/failures.dart';
import 'package:lms/features/auth/domain/repositories/auth_repository.dart'; // برای متد logout
import 'package:lms/features/auth/domain/usecases/request_auth.dart';
import 'package:lms/features/auth/domain/usecases/verify_auth.dart';
import 'package:lms/features/auth/presentation/cubit/auth_state.dart';

import '../../domain/usecases/register_face.dart';

class AuthCubit extends Cubit<AuthState> {
  final RequestAuth requestAuthUseCase;
  final VerifyAuth verifyAuthUseCase;
  final RegisterFace registerFaceUseCase;
  final AuthRepository authRepository; // برای متد logout

  AuthCubit({
    required this.requestAuthUseCase,
    required this.verifyAuthUseCase,
    required this.authRepository,
    required this.registerFaceUseCase,
  }) : super(const AuthInitial());

  // --- متدها ---

  Future<void> registerFace(String imagePath) async {
    emit(const FaceProcessingLoading()); // <<<--- وضعیت جدید

    final failureOrSuccess = await registerFaceUseCase(
      imagePath,
    ); // <<<--- Use Case جدید

    failureOrSuccess.fold(
      ifLeft:
          (failure) =>
              emit(FaceProcessingError(message: _mapFailureToMessage(failure))),
      // <<<--- وضعیت جدید
      ifRight:
          (success) => emit(
            FaceProcessingSuccess(success: success),
          ), // <<<--- وضعیت جدید
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

  // چک کردن وضعیت احراز هویت در زمان راه‌اندازی برنامه
  Future<void> checkAuthStatus() async {
    final failureOrUser = await authRepository.getCurrentUser();

    failureOrUser.fold(
      ifLeft: (failure) => emit(const AuthInitial()),
      ifRight: (user) => emit(AuthSuccess(user: user)),
    );
  }

  // متد خروج از حساب
  Future<void> logout() async {
    await authRepository.logout(); // پاکسازی کامل داده‌ها (توکن + کوکی)
    emit(const AuthInitial()); // بازگشت به وضعیت اولیه برای هدایت UI
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
