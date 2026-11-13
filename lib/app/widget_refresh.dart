import 'dart:io';
import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:in_vogue/app/background_outfits.dart';
import 'package:in_vogue/app/widget_background_task.dart';
import 'package:in_vogue/core/config/app_check.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/persistence/photo_fingerprints.dart';
import 'package:in_vogue/features/catalog/data/data_sources/outfit_catalog_local_data_source.dart';
import 'package:in_vogue/features/catalog/data/data_sources/outfit_catalog_remote_data_source.dart';
import 'package:in_vogue/features/catalog/data/repositories/outfit_catalog_repository_impl.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/widget_refresh_scheduler.dart';
import 'package:in_vogue/features/home_widget/data/repositories/home_widget_repository_impl.dart';
import 'package:in_vogue/features/home_widget/di/init.dart' as home_widget_di;
import 'package:in_vogue/features/home_widget/domain/entities/widget_refresh_context.dart';
import 'package:in_vogue/features/home_widget/domain/services/refresh_widget.dart';
import 'package:in_vogue/features/home_widget/domain/services/widget_schedule.dart';
import 'package:in_vogue/features/home_widget/presentation/widget_content_text.dart';
import 'package:in_vogue/features/outfits/data/data_sources/day_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/repositories/day_repository_impl.dart';
import 'package:in_vogue/features/weather/data/data_sources/memory_weather_local_data_source.dart';
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

/// Entry point for weather refresh and daily outfit preparation.
@pragma('vm:entry-point')
void widgetRefreshDispatcher() {
  var stopped = false;
  Workmanager().executeTask(
    (task, input) async {
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();
      return runWidgetBackgroundTask(
        task: task,
        input: input,
        nativeFlavor: appFlavor,
        isIOS: Platform.isIOS,
        log: LogMessagesImpl(),
        refresh: (environment, prepare) => refreshWidgetInBackground(
          environment,
          prepareOutfits: prepare,
          isStopped: () => stopped,
        ),
      );
    },
    onTaskStopped: (_, _) async {
      stopped = true;
    },
  );
}

/// Runs from persisted context and the phone's authenticated account.
Future<bool> refreshWidgetInBackground(
  AppEnvironment environment, {
  bool prepareOutfits = true,
  bool Function()? isStopped,
}) async {
  final log = LogMessagesImpl();
  final scheduler = WorkmanagerWidgetRefreshScheduler(
    widgetRefreshDispatcher,
    environment: environment.name,
  );
  WidgetRefreshContext? expectedContext;
  late final HomeWidgetRepositoryImpl? widget;
  Future<bool> stillCurrent() async =>
      !(isStopped?.call() ?? false) &&
      expectedContext != null &&
      FirebaseAuth.instance.currentUser?.uid == expectedContext.accountId &&
      (await widget!.savedRefresh())?.context == expectedContext;
  widget = home_widget_di.platformHomeWidgetRepository(
    canPublish: stillCurrent,
    environment: environment,
    scheduler: scheduler,
    logMessages: log,
  );
  if (widget == null) return true;
  final saved = await widget.savedRefresh();
  if (saved == null ||
      saved.environment != environment.name ||
      saved.context.accountId == null) {
    return true;
  }
  expectedContext = saved.context;
  // A processing task is one-off; rearm before any network work can fail.
  if (prepareOutfits) {
    await scheduler.scheduleOutfits(
      WorkmanagerWidgetRefreshScheduler.retryDelay,
    );
  }
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
  if (user == null || user.uid != saved.context.accountId) {
    if ((await widget.savedRefresh())?.context == saved.context) {
      await widget.clear();
    }
    return true;
  }
  final deadline = clock.now().add(const Duration(minutes: 7));
  Future<bool> canContinue() async =>
      clock.now().isBefore(deadline) && await stillCurrent();
  final support = await getApplicationSupportDirectory();
  final folder = path.join(support.path, 'in_vogue', environment.name);
  final weatherClient = Dio(
    BaseOptions(
      baseUrl: WeatherRemoteDataSourceImpl.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  final weather = WeatherRepositoryImpl(
    remoteDataSource: WeatherRemoteDataSourceImpl(weatherClient),
    localDataSource: MemoryWeatherLocalDataSource(),
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
      path.join(folder, 'catalog', 'background-outfits.json'),
    ),
    logMessages: log,
  );
  final context = saved.context;
  final l10n = lookupAppLocalizations(Locale(context.language.languageCode));
  BackgroundOutfits? outfits;
  try {
    final complete = await RefreshWidget(
      makeOutfit: prepareOutfits
          ? (params) async* {
              outfits ??= await BackgroundOutfits.open(
                environment: environment,
                context: context,
                folder: folder,
                firestore: FirebaseFirestore.instance,
                days: days,
                catalog: catalog,
                log: log,
                canContinue: canContinue,
              );
              yield* outfits!.make(params);
            }
          : null,
      loadOutfits: prepareOutfits,
      lookAhead: true,
      stillCurrent: stillCurrent,
      getWeatherReport: GetWeatherReport(weather),
      days: days,
      catalog: catalog,
      widget: widget,
      accountId: user.uid,
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
    if (prepareOutfits && await stillCurrent()) {
      await scheduler.scheduleOutfits(
        complete
            ? WidgetSchedule.refreshEvery
            : WorkmanagerWidgetRefreshScheduler.retryDelay,
      );
    }
    return complete;
  } finally {
    outfits?.close();
    weatherClient.close(force: true);
  }
}
