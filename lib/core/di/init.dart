import 'package:get_it/get_it.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/persistence/app_directory.dart';
import 'package:in_vogue/core/persistence/key_value_store.dart';
import 'package:in_vogue/core/persistence/sqlite_cache.dart';

/// Register initialized resources; no service can observe unopened storage.
void init(
  GetIt locator, {
  required AppEnvironment environment,
  required AppDirectory directory,
  required KeyValueStore keyValueStore,
  required SqliteCache sqliteCache,
}) {
  locator
    ..registerSingleton<AppEnvironment>(environment)
    ..registerSingleton<AppDirectory>(directory)
    ..registerSingleton<LogMessages>(LogMessagesImpl())
    ..registerSingleton<KeyValueStore>(
      keyValueStore,
      dispose: (store) => store.close(),
    )
    ..registerSingleton<SqliteCache>(
      sqliteCache,
      dispose: (cache) => cache.close(),
    );
}
