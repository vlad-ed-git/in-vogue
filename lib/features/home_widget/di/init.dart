import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/home_widget_data_source.dart';
import 'package:in_vogue/features/home_widget/data/repositories/home_widget_repository_impl.dart';
import 'package:in_vogue/features/home_widget/data/repositories/unavailable_home_widget_repository.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';
import 'package:in_vogue/features/home_widget/domain/usecases/publish_widget.dart';
import 'package:in_vogue/features/home_widget/domain/usecases/watch_widget_taps.dart';
import 'package:in_vogue/features/home_widget/presentation/bloc/home_widget_bloc.dart';

void init(GetIt locator) {
  locator
    // The widget is built for Android; iPhone's waits for WidgetKit.
    ..registerLazySingleton<HomeWidgetRepository>(
      () => defaultTargetPlatform == TargetPlatform.android
          ? HomeWidgetRepositoryImpl(
              dataSource: const HomeWidgetDataSourceImpl(),
              logMessages: locator(),
            )
          : const UnavailableHomeWidgetRepository(),
    )
    ..registerLazySingleton<PublishWidget>(() => PublishWidget(locator()))
    ..registerLazySingleton<WatchWidgetTaps>(() => WatchWidgetTaps(locator()))
    ..registerFactory<HomeWidgetBloc>(
      () =>
          HomeWidgetBloc(publishWidget: locator(), watchWidgetTaps: locator()),
    );
}
