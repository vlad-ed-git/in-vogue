import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';

class LogMessagesImpl implements LogMessages {
  @override
  void logError({
    required String callerClass,
    required String callerMethod,
    required Object error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    // Log categories and error codes, not exception messages that may
    // contain personal data.
    developer.log(
      switch (error) {
        FirebaseException(:final plugin, :final code) =>
          'FirebaseException $plugin/$code',
        _ => '${error.runtimeType}',
      },
      name: '$callerClass.$callerMethod',
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
