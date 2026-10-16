import 'dart:convert';

import 'package:in_vogue/core/persistence/key_value_store.dart';
import 'package:in_vogue/features/outfits/data/models/try_on_job_model.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';

/// Try-on jobs in the key-value store, by key. Every method throws
/// CacheException.
abstract interface class TryOnJobLocalDataSource {
  /// Unreadable jobs are left out.
  Map<String, TryOnJob> jobs();

  Future<void> save(Map<String, TryOnJob> jobs);
}

class TryOnJobLocalDataSourceImpl implements TryOnJobLocalDataSource {
  TryOnJobLocalDataSourceImpl(this._store);
  final KeyValueStore _store;

  static const jobsKey = 'try_on_jobs';

  @override
  Map<String, TryOnJob> jobs() {
    final saved = _store.readString(jobsKey);
    if (saved == null) return {};
    final Object? json;
    try {
      json = jsonDecode(saved);
    } on FormatException {
      return {};
    }
    if (json is! Map<String, Object?>) return {};
    final jobs = <String, TryOnJob>{};
    for (final MapEntry(:key, :value) in json.entries) {
      try {
        jobs[key] = TryOnJobModel.fromJson(value);
      } on FormatException {
        // Left out.
      }
    }
    return jobs;
  }

  @override
  Future<void> save(Map<String, TryOnJob> jobs) => _store.writeString(
    jobsKey,
    jsonEncode({
      for (final MapEntry(:key, :value) in jobs.entries)
        key: TryOnJobModel.toJson(value),
    }),
  );
}
