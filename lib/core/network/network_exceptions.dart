/// The server answered with an error or an unreadable body. Translated to a
/// ServerFailure at repository boundaries.
class ServerException implements Exception {
  const ServerException(this.cause, this.stackTrace);

  final Object cause;
  final StackTrace stackTrace;
}

/// The request did not reach the server. Translated to a NetworkFailure at
/// repository boundaries.
class NetworkException implements Exception {
  const NetworkException(this.cause, this.stackTrace);

  final Object cause;
  final StackTrace stackTrace;
}
