// lib/core/errors/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([List properties = const <dynamic>[]]) : super();
}

// خطاهای مربوط به ارتباط با سرور
class ServerFailure extends Failure {
  final String message;
  final int? statusCode;

  const ServerFailure({this.message = 'خطای سرور نامشخص', this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// خطای داده‌های نامعتبر (مثلاً پاسخ نامناسب JSON)
class DataParsingFailure extends Failure {
  final String message;

  const DataParsingFailure({this.message = 'خطا در تحلیل داده'});

  @override
  List<Object> get props => [message];
}
