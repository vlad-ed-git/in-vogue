import 'dart:convert';

import 'package:in_vogue/core/persistence/key_value_store.dart';
import 'package:in_vogue/features/makeup/data/models/makeup_job_model.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_job.dart';

/// Makeup jobs in the key-value store, by key. Every method throws
/// CacheException.
abstract interface class MakeupJobLocalDataSource {
  /// Unreadable jobs are left out.
  Map<String, MakeupJob> jobs();

  Future<void> save(Map<String, MakeupJob> jobs);
}

class MakeupJobLocalDataSourceImpl implements MakeupJobLocalDataSource {
  MakeupJobLocalDataSourceImpl(this._store);
  final KeyValueStore _store;

  static const jobsKey = 'makeup_jobs';

  @override
  Map<String, MakeupJob> jobs() {
    final saved = _store.readString(jobsKey);
    if (saved == null) return {};
    final Object? json;
    try {
      json = jsonDecode(saved);
    } on FormatException {
      return {};
    }
    if (json is! Map<String, Object?>) return {};
    final jobs = <String, MakeupJob>{};
    for (final MapEntry(:key, :value) in json.entries) {
      try {
        jobs[key] = MakeupJobModel.fromJson(value);
      } on FormatException {
        // Left out.
      }
    }
    return jobs;
  }

  @override
  Future<void> save(Map<String, MakeupJob> jobs) => _store.writeString(
    jobsKey,
    jsonEncode({
      for (final MapEntry(:key, :value) in jobs.entries)
        key: MakeupJobModel.toJson(value),
    }),
  );
}
