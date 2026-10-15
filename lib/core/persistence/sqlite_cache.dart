import 'package:sqflite/sqflite.dart';

/// Non-sensitive, disposable cache. Never the authority for outfit history.
///
/// The caller supplies time so expiry has the same meaning in tests and in the
/// app. Future feature data sources translate database exceptions at their edge.
class SqliteCache {
  SqliteCache._(this._database);
  final Database _database;

  static Future<SqliteCache> open({
    required DatabaseFactory factory,
    required String path,
  }) async {
    final database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (database, version) => database.execute('''
        CREATE TABLE cached_documents (
          key TEXT PRIMARY KEY NOT NULL,
          value TEXT NOT NULL,
          expires_at INTEGER NOT NULL
        )
      '''),
      ),
    );
    return SqliteCache._(database);
  }

  Future<String?> read(String key, {required DateTime now}) async {
    final rows = await _database.query(
      'cached_documents',
      columns: ['value'],
      where: 'key = ? AND expires_at > ?',
      whereArgs: [key, now.millisecondsSinceEpoch],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single['value']! as String;
  }

  Future<void> write(
    String key,
    String value, {
    required DateTime expiresAt,
  }) async {
    await _database.insert('cached_documents', {
      'key': key,
      'value': value,
      'expires_at': expiresAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clear() async {
    await _database.delete('cached_documents');
  }

  Future<void> close() => _database.close();
}
