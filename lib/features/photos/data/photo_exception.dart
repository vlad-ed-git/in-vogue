/// A photo could not be chosen or read. Translated to a PhotoFailure at
/// repository boundaries.
class PhotoException implements Exception {
  const PhotoException(this.cause, this.stackTrace);

  final Object cause;
  final StackTrace stackTrace;
}
