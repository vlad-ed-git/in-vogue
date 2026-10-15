import 'dart:developer' as developer;

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
    // Log categories, not exception messages that may contain personal data.
    developer.log(
      '${error.runtimeType}',
      name: '$callerClass.$callerMethod',
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
