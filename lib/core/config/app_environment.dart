enum AppEnvironment {
  development(firebaseProjectId: 'in-vogue-dev'),
  production(firebaseProjectId: 'in-vogue');

  const AppEnvironment({required this.firebaseProjectId});

  final String firebaseProjectId;

  /// Fail before opening storage or Firebase when the entrypoint is wrong.
  void validate({required String? nativeFlavor, required String projectId}) {
    if (nativeFlavor != name) {
      throw StateError(
        'Entrypoint $name requires --flavor $name; got $nativeFlavor.',
      );
    }
    if (projectId != firebaseProjectId) {
      throw StateError(
        'Flavor $name requires Firebase project $firebaseProjectId.',
      );
    }
  }
}
