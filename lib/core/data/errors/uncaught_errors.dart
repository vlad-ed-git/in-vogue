import 'package:flutter/foundation.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';

/// Logs the errors nothing caught to [log] too: the framework's, after its
/// own handling, and those that reached the platform.
void reportUncaughtErrors(LogMessages log) {
  final framework = FlutterError.onError;
  FlutterError.onError = (details) {
    framework?.call(details);
    log.logError(
      callerClass: 'Flutter',
      callerMethod: details.library ?? 'framework',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  final platform = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    platform?.call(error, stack);
    log.logError(
      callerClass: 'Uncaught',
      callerMethod: 'error',
      error: error,
      stackTrace: stack,
    );
    return true;
  };
}
