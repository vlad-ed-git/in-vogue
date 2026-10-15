import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/di/init.dart' as core_di;
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/core/persistence/hive_key_value_store.dart';
import 'package:in_vogue/core/persistence/sqlite_cache.dart';
import 'package:in_vogue/features/location/di/init.dart' as location_di;
import 'package:in_vogue/features/preferences/di/init.dart' as preferences_di;
import 'package:in_vogue/features/preferences/domain/usecases/get_language.dart';
import 'package:in_vogue/features/setup/di/init.dart' as setup_di;
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/domain/usecases/get_setup_step.dart';
import 'package:in_vogue/features/weather/di/init.dart' as weather_di;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// What the first frame shows, read before it is drawn.
typedef StartupState = ({SupportedLanguages language, SetupStep setupStep});

abstract final class MainInit {
  /// Only initializes SDKs and local resources. No sign-in or network fetches.
  static Future<StartupState> init({
    required AppEnvironment environment,
    required FirebaseOptions firebaseOptions,
  }) async {
    environment.validate(
      nativeFlavor: appFlavor,
      projectId: firebaseOptions.projectId,
    );
    final locator = GetIt.I;
    if (locator.isRegistered<AppEnvironment>()) {
      throw StateError('MainInit has already initialized this application.');
    }
    await Firebase.initializeApp(options: firebaseOptions);
    final support = await getApplicationSupportDirectory();
    final directory = Directory(
      path.join(support.path, 'in_vogue', environment.name),
    );
    await directory.create(recursive: true);
    final store = await HiveKeyValueStore.open(
      directory: directory.path,
      boxName: 'preferences_${environment.name}',
    );
    final SqliteCache cache;
    try {
      cache = await SqliteCache.open(
        factory: databaseFactory,
        path: path.join(directory.path, 'cache.sqlite'),
      );
    } catch (_) {
      await store.close();
      rethrow;
    }
    core_di.init(
      locator,
      environment: environment,
      keyValueStore: store,
      sqliteCache: cache,
    );
    try {
      preferences_di.init(locator);
      setup_di.init(locator);
      location_di.init(locator);
      weather_di.init(locator);
      final language = await locator<GetLanguage>()(const NoParams());
      final setupStep = await locator<GetSetupStep>()(const NoParams());
      _registerErrorHandlers(locator<LogMessages>());
      // Read before runApp to avoid a flash of the wrong language or screen.
      return (
        language: language.fold(
          (_) => SupportedLanguages.defaultLanguage,
          (value) => value,
        ),
        setupStep: setupStep.fold((_) => SetupStep.welcome, (value) => value),
      );
    } catch (_) {
      await locator.reset();
      rethrow;
    }
  }

  static void _registerErrorHandlers(LogMessages logger) {
    FlutterError.onError = (details) {
      logger.logError(
        callerClass: 'FlutterError',
        callerMethod: details.library ?? 'unknown',
        error: details.exception,
        stackTrace: details.stack,
      );
      if (kDebugMode) FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      logger.logError(
        callerClass: 'PlatformDispatcher',
        callerMethod: 'onError',
        error: error,
        stackTrace: stack,
      );
      return true;
    };
  }
}
