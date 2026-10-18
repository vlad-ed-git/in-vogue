import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/home_widget_data_source.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/widget_picture_data_source.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/widget_refresh_scheduler.dart';
import 'package:in_vogue/features/home_widget/data/repositories/home_widget_repository_impl.dart';
import 'package:in_vogue/features/home_widget/data/repositories/unavailable_home_widget_repository.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';
import 'package:in_vogue/features/home_widget/domain/usecases/publish_widget.dart';
import 'package:in_vogue/features/home_widget/domain/usecases/watch_widget_taps.dart';
import 'package:in_vogue/features/home_widget/presentation/bloc/home_widget_bloc.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';

void init(GetIt locator) {
  locator
    ..registerLazySingleton<HomeWidgetRepository>(
      () =>
          platformHomeWidgetRepository(
            environment: locator(),
            scheduler: locator(),
            logMessages: locator(),
          ) ??
          const UnavailableHomeWidgetRepository(),
    )
    ..registerLazySingleton<PublishWidget>(() => PublishWidget(locator()))
    ..registerLazySingleton<WatchWidgetTaps>(() => WatchWidgetTaps(locator()))
    ..registerFactory<HomeWidgetBloc>(
      () =>
          HomeWidgetBloc(publishWidget: locator(), watchWidgetTaps: locator()),
    );
}

/// The widget on this phone: Android's, and iPhone's where the flavor has an
/// App Group; null elsewhere. The app and the morning refresh both use it.
HomeWidgetRepositoryImpl? platformHomeWidgetRepository({
  required AppEnvironment environment,
  required WidgetRefreshScheduler scheduler,
  required LogMessages logMessages,
}) {
  final HomeWidgetDataSource dataSource;
  final WidgetPictureDataSource pictures;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      dataSource = HomeWidgetDataSourceImpl();
      pictures = const InPlaceWidgetPictureDataSource();
    case TargetPlatform.iOS:
      final group = HomeWidgetDataSourceImpl.appGroupOf(environment);
      if (group == null) return null;
      dataSource = HomeWidgetDataSourceImpl(appGroupId: group);
      pictures = AppGroupWidgetPictureDataSource(
        () => PathProviderFoundation().getContainerPath(
          appGroupIdentifier: group,
        ),
      );
    default:
      return null;
  }
  return HomeWidgetRepositoryImpl(
    dataSource: dataSource,
    pictures: pictures,
    scheduler: scheduler,
    environment: environment.name,
    logMessages: logMessages,
  );
}
