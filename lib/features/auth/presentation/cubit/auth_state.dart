// lib/features/auth/presentation/cubit/auth_state.dart
import 'package:equatable/equatable.dart';
import 'package:lms/features/auth/domain/entities/user.dart';

enum AuthStep { identifier, password }

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

// وضعیت اولیه یا پس از خروج
class AuthInitial extends AuthState {
  final String message;
  const AuthInitial({
    this.message = 'لطفاً نام کاربری، کد ملی یا شماره موبایل خود را وارد کنید.',
  });

  @override
  List<Object> get props => [message];
}

// در حال بارگذاری
class AuthLoading extends AuthState {
  final AuthStep step;
  const AuthLoading({required this.step});

  @override
  List<Object> get props => [step];
}

// مرحله اول موفقیت‌آمیز بود، به مرحله رمز عبور بروید
class AuthRequestSuccess extends AuthState {
  final String message;
  const AuthRequestSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

// احراز هویت کامل شد و کاربر وارد شد
class AuthSuccess extends AuthState {
  final UserEntity user;
  const AuthSuccess({required this.user});

  @override
  List<Object> get props => [user];
}

// خطای عمومی
class AuthError extends AuthState {
  final String message;
  final AuthStep step;
  const AuthError({required this.message, required this.step});

  @override
  List<Object> get props => [message, step];
}
