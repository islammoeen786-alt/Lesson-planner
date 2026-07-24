import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AppError {
  final String message;
  final String? technicalDetail;
  final bool isRetryable;
  final int? statusCode;
  final AppErrorSeverity severity;

  const AppError({
    required this.message,
    this.technicalDetail,
    this.isRetryable = false,
    this.statusCode,
    this.severity = AppErrorSeverity.medium,
  });
}

enum AppErrorSeverity { low, medium, high, critical }

class AppErrorHandler {
  static const _networkError = AppError(
    message: 'No internet connection. Please check your connection and try again.',
    isRetryable: true,
    severity: AppErrorSeverity.high,
  );

  static const _serverUnavailable = AppError(
    message: 'Our server is temporarily unavailable. Please try again in a few moments.',
    isRetryable: true,
    severity: AppErrorSeverity.high,
  );

  static const _timeoutError = AppError(
    message: 'The request took too long. Please try again.',
    isRetryable: true,
    severity: AppErrorSeverity.medium,
  );

  static const _unauthorized = AppError(
    message: 'Your session has expired. Please sign in again.',
    severity: AppErrorSeverity.critical,
  );

  static const _forbidden = AppError(
    message: "You don't have permission to perform this action.",
    severity: AppErrorSeverity.high,
  );

  static const _unknownError = AppError(
    message: 'Something went wrong. Please try again later.',
    severity: AppErrorSeverity.medium,
  );

  static AppError fromDioException(DioException e) {
    _logTechnical('[DioException] type=${e.type} status=${e.response?.statusCode} msg=${e.message}');

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return _timeoutError;
    }

    if (e.type == DioExceptionType.connectionError) {
      if (e.error is SocketException || e.error is HandshakeException) {
        return _networkError;
      }
      return _serverUnavailable;
    }

    if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      final body = e.response?.data;
      String? serverMsg;
      if (body is Map) {
        serverMsg = body['error'] as String? ?? body['message'] as String?;
      }

      switch (statusCode) {
        case 400:
          return const AppError(
            message: 'Invalid request. Please check your input.',
            statusCode: 400,
            severity: AppErrorSeverity.medium,
          );
        case 401:
          return _unauthorized;
        case 403:
          return _forbidden;
        case 404:
          return AppError(
            message: serverMsg ?? 'The requested resource was not found.',
            statusCode: 404,
            severity: AppErrorSeverity.medium,
          );
        case 408:
          return _timeoutError;
        case 429:
          return AppError(
            message: 'Too many requests. Please wait a moment and try again.',
            isRetryable: true,
            statusCode: 429,
            severity: AppErrorSeverity.medium,
          );
        case 500:
        case 502:
        case 503:
        case 504:
          return _serverUnavailable;
        default:
          return AppError(
            message: serverMsg ?? _unknownError.message,
            statusCode: statusCode,
            severity: AppErrorSeverity.medium,
          );
      }
    }

    if (e.type == DioExceptionType.cancel) {
      return AppError(
        message: 'Request was cancelled.',
        severity: AppErrorSeverity.low,
      );
    }

    return _unknownError;
  }

  static AppError fromFirebaseException(FirebaseAuthException e) {
    _logTechnical('[FirebaseAuthException] code=${e.code} msg=${e.message}');

    switch (e.code) {
      case 'user-not-found':
        return const AppError(message: 'No account found with this email.');
      case 'wrong-password':
        return const AppError(message: 'Incorrect password.');
      case 'invalid-credential':
        return const AppError(message: 'Invalid email or password.');
      case 'invalid-email':
        return const AppError(message: 'Please enter a valid email address.');
      case 'user-disabled':
        return const AppError(message: 'This account has been disabled.');
      case 'too-many-requests':
        return AppError(
          message: 'Too many attempts. Please try again later.',
          isRetryable: true,
          severity: AppErrorSeverity.medium,
        );
      case 'email-already-in-use':
        return const AppError(message: 'An account with this email already exists.');
      case 'weak-password':
        return const AppError(message: 'Password must be at least 8 characters.');
      case 'operation-not-allowed':
        return const AppError(message: 'Email/password sign in is not enabled.');
      case 'network-request-failed':
        return _networkError;
      default:
        return AppError(
          message: 'Unable to sign in. Please verify your email and password.',
          technicalDetail: 'Unhandled Firebase code: ${e.code}',
          severity: AppErrorSeverity.medium,
        );
    }
  }

  static AppError fromException(dynamic e) {
    if (e is DioException) return fromDioException(e);
    if (e is FirebaseAuthException) return fromFirebaseException(e);
    if (e is SocketException || e is HandshakeException) return _networkError;
    if (e is TimeoutException) return _timeoutError;
    if (e is FormatException) {
      return const AppError(
        message: 'Unexpected response from server.',
        severity: AppErrorSeverity.medium,
      );
    }

    _logTechnical('[UnknownException] $e');
    return _unknownError;
  }

  static String friendlyMessage(String category) {
    switch (category) {
      case 'generate':
        return 'Unable to generate your lesson plan. Please try again.';
      case 'ai_service':
        return 'The AI service is temporarily unavailable.';
      case 'pdf_export':
        return 'Unable to generate the PDF.';
      case 'share':
        return 'Unable to share the lesson plan.';
      case 'save':
        return 'Unable to save changes.';
      case 'delete':
        return 'Unable to delete the lesson plan.';
      case 'upload':
        return 'Upload failed. Please try again.';
      case 'load':
        return 'Unable to load data. Please try again.';
      case 'network':
        return _networkError.message;
      default:
        return _unknownError.message;
    }
  }

  static void _logTechnical(String message) {
    debugPrint('[AppErrorHandler] $message');
  }
}
