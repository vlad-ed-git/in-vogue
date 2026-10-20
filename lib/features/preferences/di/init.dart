import 'package:get_it/get_it.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/features/preferences/data/data_sources/preferences_local_data_source.dart';
import 'package:in_vogue/features/preferences/data/repositories/preferences_repository_impl.dart';
import 'package:in_vogue/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:in_vogue/features/preferences/domain/usecases/get_default_day.dart';
import 'package:in_vogue/features/preferences/domain/usecases/get_language.dart';
import 'package:in_vogue/features/preferences/domain/usecases/get_occasions.dart';
import 'package:in_vogue/features/preferences/domain/usecases/set_default_day.dart';
import 'package:in_vogue/features/preferences/domain/usecases/set_language.dart';
import 'package:in_vogue/features/preferences/domain/usecases/set_occasion.dart';
import 'package:in_vogue/features/preferences/presentation/bloc/preferences_bloc.dart';

void init(GetIt locator) {
  locator
    ..registerLazySingleton<PreferencesLocalDataSource>(
      () => PreferencesLocalDataSourceImpl(locator()),
    )
    ..registerLazySingleton<PreferencesRepository>(
      () => PreferencesRepositoryImpl(
        localDataSource: locator(),
        logMessages: locator(),
      ),
    )
    ..registerLazySingleton<GetLanguage>(() => GetLanguage(locator()))
    ..registerLazySingleton<GetDefaultDay>(() => GetDefaultDay(locator()))
    ..registerLazySingleton<SetDefaultDay>(() => SetDefaultDay(locator()))
    ..registerLazySingleton<SetLanguage>(() => SetLanguage(locator()))
    ..registerLazySingleton<GetOccasions>(() => GetOccasions(locator()))
    ..registerLazySingleton<SetOccasion>(() => SetOccasion(locator()))
    ..registerFactoryParam<PreferencesBloc, SupportedLanguages, void>(
      (language, _) =>
          PreferencesBloc(setLanguage: locator(), initialLanguage: language),
    );
}
