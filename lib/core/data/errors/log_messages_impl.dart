import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:in_vogue/core/data/errors/error_reports.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';

/// Writes each error to the debug console in debug builds, and files it
/// with [ErrorReports] when given them.
class LogMessagesImpl implements LogMessages {
  const LogMessagesImpl({this._reports});

  final ErrorReports? _reports;

  @override
  void logError({
    required String callerClass,
    required String callerMethod,
    required Object error,
    StackTrace? stackTrace,
  }) {
    final category = categoryOf(error);
    final where = '$callerClass.$callerMethod';
    if (kDebugMode) {
      developer.log(category, name: where, stackTrace: stackTrace, level: 1000);
    }
    _reports?.add(where: where, error: category, stackTrace: stackTrace);
  }

  /// The error's kind and code, never its message, which may carry personal
  /// data.
  static String categoryOf(Object error) => switch (error) {
    FirebaseException(:final plugin, :final code) =>
      'FirebaseException $plugin/$code',
    _ => '${error.runtimeType}',
  };
}
