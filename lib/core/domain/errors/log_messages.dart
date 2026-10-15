abstract interface class LogMessages {
  /// Must never throw. Remote reporting requires a separate consented service.
  void logError({
    required String callerClass,
    required String callerMethod,
    required Object error,
    StackTrace? stackTrace,
  });
}
