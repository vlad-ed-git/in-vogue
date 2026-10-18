import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_remote_data_source.dart';
import 'package:in_vogue/core/domain/entities/install_id.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/persistence/app_directory.dart';
import 'package:in_vogue/core/persistence/key_value_store.dart';
import 'package:in_vogue/core/persistence/photo_fingerprints.dart';
import 'package:in_vogue/core/persistence/sqlite_cache.dart';

/// Register initialized resources; no service can observe unopened storage.
/// The YouCam client is registered only with a [youCamApiKey].
void init(
  GetIt locator, {
  required AppEnvironment environment,
  required AppDirectory directory,
  required KeyValueStore keyValueStore,
  required SqliteCache sqliteCache,
  required InstallId installId,
  String? youCamApiKey,
}) {
  final key = youCamApiKey?.trim() ?? '';
  if (key.isNotEmpty) {
    locator.registerLazySingleton<YouCamRemoteDataSource>(
      () => YouCamRemoteDataSourceImpl(
        api: Dio(
          BaseOptions(
            baseUrl: YouCamRemoteDataSourceImpl.baseUrl,
            headers: {'Authorization': 'Bearer $key'},
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
          ),
        ),
        files: Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
          ),
        ),
      ),
    );
  }
  locator
    ..registerSingleton<AppEnvironment>(environment)
    ..registerSingleton<InstallId>(installId)
    ..registerSingleton<AppDirectory>(directory)
    ..registerSingleton<LogMessages>(LogMessagesImpl())
    ..registerSingleton<PhotoFingerprints>(PhotoFingerprints())
    ..registerSingleton<KeyValueStore>(
      keyValueStore,
      dispose: (store) => store.close(),
    )
    ..registerSingleton<SqliteCache>(
      sqliteCache,
      dispose: (cache) => cache.close(),
    );
}
