/// Analyses under way on this phone, so one cut short is read again rather
/// than paid for twice. Failures to read or write are ignored.
abstract interface class AnalysisJobRepository {
  /// The task under way for [key]; null when there is none.
  Future<String?> task(String key);

  Future<void> save(String key, String taskId);

  Future<void> clear(String key);

  /// Forgets the account's analyses.
  Future<void> forgetAccount(String accountId);
}
