/// Infrastructure errors are translated to a Failure at repository boundaries.
class CacheException implements Exception {
  const CacheException(this.cause, this.stackTrace);

  final Object cause;
  final StackTrace stackTrace;
}
