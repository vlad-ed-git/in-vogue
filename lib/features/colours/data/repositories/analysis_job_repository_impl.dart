import 'dart:convert';

import 'package:in_vogue/core/persistence/key_value_store.dart';
import 'package:in_vogue/features/colours/domain/repositories/analysis_job_repository.dart';

/// Analyses under way, as task ids by key in the key-value store.
class AnalysisJobRepositoryImpl implements AnalysisJobRepository {
  AnalysisJobRepositoryImpl(this._store);

  final KeyValueStore _store;

  static const tasksKey = 'analysis_tasks';

  Map<String, String> _tasks() {
    try {
      final saved = _store.readString(tasksKey);
      if (saved == null) return {};
      final json = jsonDecode(saved);
      if (json is! Map<String, Object?>) return {};
      return {
        for (final MapEntry(:key, :value) in json.entries)
          if (value is String) key: value,
      };
    } on Object {
      return {};
    }
  }

  Future<void> _write(Map<String, String> tasks) async {
    try {
      await _store.writeString(tasksKey, jsonEncode(tasks));
    } on Object {
      // A lost task is read again from the start.
    }
  }

  @override
  Future<String?> task(String key) async => _tasks()[key];

  @override
  Future<void> save(String key, String taskId) =>
      _write({..._tasks(), key: taskId});

  @override
  Future<void> clear(String key) => _write(_tasks()..remove(key));

  @override
  Future<void> forgetAccount(String accountId) =>
      _write(_tasks()..removeWhere((key, _) => key.startsWith('$accountId/')));
}
