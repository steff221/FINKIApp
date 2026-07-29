import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// What actually went wrong, from the student's point of view.
///
/// The distinction that matters is not the status code but what the student can
/// do about it: wait for signal, sign in again, or nothing at all.
enum AppErrorKind {
  /// No route to the server — aeroplane mode, no signal, campus wifi captive.
  offline,

  /// The server is reachable but did not answer in time.
  timeout,

  /// The session is gone (401/403). The app signs out on its own.
  auth,

  /// The server answered with a failure of its own (5xx, or an unexpected 4xx).
  server,

  /// Anything we did not anticipate — a decoding failure, a bug.
  unknown,
}

/// A failure with a Macedonian sentence attached, so screens never have to
/// interpret a [DioException] themselves.
class AppError implements Exception {
  final AppErrorKind kind;
  final int? statusCode;

  /// The underlying failure, kept for logs — never shown.
  final Object? cause;

  const AppError(this.kind, {this.statusCode, this.cause});

  /// Classifies anything thrown below the UI.
  factory AppError.from(Object error) {
    if (error is AppError) return error;

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return AppError(AppErrorKind.timeout, cause: error);
        case DioExceptionType.connectionError:
          return AppError(AppErrorKind.offline, cause: error);
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode;
          if (code == 401 || code == 403) {
            return AppError(AppErrorKind.auth, statusCode: code, cause: error);
          }
          return AppError(AppErrorKind.server, statusCode: code, cause: error);
        case DioExceptionType.cancel:
        case DioExceptionType.badCertificate:
        case DioExceptionType.unknown:
          // A dead socket surfaces as `unknown` with a SocketException inside.
          if (error.error is SocketException) {
            return AppError(AppErrorKind.offline, cause: error);
          }
          return AppError(AppErrorKind.unknown, cause: error);
      }
    }

    if (error is SocketException) {
      return AppError(AppErrorKind.offline, cause: error);
    }
    return AppError(AppErrorKind.unknown, cause: error);
  }

  /// The headline: what happened.
  String get message => switch (kind) {
        AppErrorKind.offline => 'Нема интернет врска',
        AppErrorKind.timeout => 'Серверот не одговара',
        AppErrorKind.auth => 'Сесијата истече',
        AppErrorKind.server => 'Серверот има проблем',
        AppErrorKind.unknown => 'Нешто тргна наопаку',
      };

  /// The line under it: what to do about it.
  String get hint => switch (kind) {
        AppErrorKind.offline =>
          'Проверете ја вашата интернет врска и обидете се повторно.',
        AppErrorKind.timeout =>
          'Врската е бавна или серверот е зафатен. Обидете се повторно.',
        AppErrorKind.auth => 'Најавете се повторно за да продолжите.',
        AppErrorKind.server =>
          'Не е до вас — обидете се повторно за неколку минути.',
        AppErrorKind.unknown => 'Обидете се повторно.',
      };

  /// Reaching for the phone's own vocabulary: a cloud for the server's
  /// problems, a crossed-out signal for ours.
  IconData get icon => switch (kind) {
        AppErrorKind.offline => Icons.wifi_off_rounded,
        AppErrorKind.timeout => Icons.hourglass_disabled_rounded,
        AppErrorKind.auth => Icons.lock_outline_rounded,
        AppErrorKind.server => Icons.cloud_off_rounded,
        AppErrorKind.unknown => Icons.error_outline_rounded,
      };

  /// Retrying an expired session only produces the same 401.
  bool get isRetryable => kind != AppErrorKind.auth;

  @override
  String toString() => 'AppError(${kind.name}, status: $statusCode, cause: $cause)';
}
