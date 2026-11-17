import 'package:in_vogue/core/data/errors/error_reports.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';

/// A background run's log: writes each error as [LogMessagesImpl] does,
/// marked as the background's, and files it once [reports] are set, which
/// takes Firebase.
class BackgroundLogMessages implements LogMessages {
  ErrorReports? reports;

  @override
  void logError({
    required String callerClass,
    required String callerMethod,
    required Object error,
    StackTrace? stackTrace,
  }) => LogMessagesImpl(reports: reports).logError(
    callerClass: 'background $callerClass',
    callerMethod: callerMethod,
    error: error,
    stackTrace: stackTrace,
  );
}
