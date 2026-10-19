import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/config/app_check.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/persistence/photo_fingerprints.dart';
import 'package:in_vogue/features/catalog/data/data_sources/outfit_catalog_local_data_source.dart';
import 'package:in_vogue/features/catalog/data/data_sources/outfit_catalog_remote_data_source.dart';
import 'package:in_vogue/features/catalog/data/repositories/outfit_catalog_repository_impl.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/widget_refresh_scheduler.dart';
import 'package:in_vogue/features/home_widget/di/init.dart' as home_widget_di;
import 'package:in_vogue/features/home_widget/domain/services/refresh_widget.dart';
import 'package:in_vogue/features/home_widget/presentation/widget_content_text.dart';
import 'package:in_vogue/features/outfits/data/data_sources/day_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/repositories/day_repository_impl.dart';
import 'package:in_vogue/features/weather/data/data_sources/uncached_weather_local_data_source.dart';
import 'package:in_vogue/features/weather/data/data_sources/weather_remote_data_source.dart';
import 'package:in_vogue/features/weather/data/repositories/weather_repository_impl.dart';
import 'package:in_vogue/features/weather/domain/usecases/get_weather_report.dart';
import 'package:in_vogue/firebase_options_development.dart' as development;
import 'package:in_vogue/firebase_options_production.dart' as production;
import 'package:in_vogue/l10n/generated/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

/// The widget's morning refresh, run in the background by WorkManager on
/// Android and by background app refresh on iPhone. A refresh that fails keeps what the widget shows; the next
/// morning tries again.
@pragma('vm:entry-point')
void widgetRefreshDispatcher() {
  Workmanager().executeTask((task, input) async {
    final environment =
        AppEnvironment.values
            .asNameMap()[input?[WorkmanagerWidgetRefreshScheduler
            .environmentInput]];
    if (environment == null) return true;
    try {
      await refreshWidgetInBackground(environment);
    } on Object catch (error, stack) {
      LogMessagesImpl().logError(
        callerClass: 'widgetRefreshDispatcher',
        callerMethod: 'executeTask',
        error: error,
        stackTrace: stack,
      );
    }
    return true;
  });
}

/// Redraws the widget with today's and tomorrow's weather again and the
/// pictures already made for them, for the account signed in on this phone.
/// It never calls YouCam.
Future<void> refreshWidgetInBackground(AppEnvironment environment) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  final log = LogMessagesImpl();
  final widget = home_widget_di.platformHomeWidgetRepository(
    environment: environment,
    scheduler: WorkmanagerWidgetRefreshScheduler(
      widgetRefreshDispatcher,
      environment: environment.name,
    ),
    logMessages: log,
  );
  if (widget == null) return;
  final saved = await widget.savedRefresh();
  if (saved == null) return;
  await initializeDateFormatting();
  await Firebase.initializeApp(
    options: switch (environment) {
      AppEnvironment.development =>
        development.DefaultFirebaseOptions.currentPlatform,
      AppEnvironment.production =>
        production.DefaultFirebaseOptions.currentPlatform,
    },
  );
  await activateAppCheck();
  final user = await FirebaseAuth.instance.authStateChanges().first;
  final support = await getApplicationSupportDirectory();
  final folder = path.join(support.path, 'in_vogue', environment.name);
  final weather = WeatherRepositoryImpl(
    remoteDataSource: WeatherRemoteDataSourceImpl(
      Dio(
        BaseOptions(
          baseUrl: WeatherRemoteDataSourceImpl.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      ),
    ),
    localDataSource: const UncachedWeatherLocalDataSource(),
    logMessages: log,
  );
  final days = DayRepositoryImpl(
    remoteDataSource: DayRemoteDataSourceImpl(FirebaseFirestore.instance),
    pictureRemoteDataSource: OutfitPictureRemoteDataSourceImpl(
      FirebaseStorage.instance,
    ),
    pictureLocalDataSource: OutfitPictureLocalDataSourceImpl(
      path.join(folder, 'outfits'),
    ),
    fingerprints: PhotoFingerprints(),
    logMessages: log,
  );
  final catalog = OutfitCatalogRepositoryImpl(
    remote: OutfitCatalogRemoteDataSourceImpl(FirebaseFirestore.instance),
    local: OutfitCatalogLocalDataSourceImpl(
      path.join(folder, 'catalog', 'outfits.json'),
    ),
    logMessages: log,
  );
  final context = saved.context;
  final l10n = lookupAppLocalizations(Locale(context.language.languageCode));
  await RefreshWidget(
    getWeatherReport: GetWeatherReport(weather),
    days: days,
    catalog: catalog,
    widget: widget,
    accountId: user?.uid,
    describe: (widgetDays, context) => WidgetContentText.of(
      days: widgetDays,
      preferred: context.preferred,
      countryCode: context.place.countryCode,
      bodyPhoto: context.bodyPhoto,
      l10n: l10n,
      language: context.language,
      now: clock.now(),
    ),
  )(context);
}
