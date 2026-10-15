import 'package:get_it/get_it.dart';
import 'package:in_vogue/features/setup/data/data_sources/setup_local_data_source.dart';
import 'package:in_vogue/features/setup/data/repositories/setup_repository_impl.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/domain/repositories/setup_repository.dart';
import 'package:in_vogue/features/setup/domain/usecases/get_setup_step.dart';
import 'package:in_vogue/features/setup/domain/usecases/save_setup_step.dart';
import 'package:in_vogue/features/setup/presentation/bloc/setup_bloc.dart';

void init(GetIt locator) {
  locator
    ..registerLazySingleton<SetupLocalDataSource>(
      () => SetupLocalDataSourceImpl(locator()),
    )
    ..registerLazySingleton<SetupRepository>(
      () => SetupRepositoryImpl(
        localDataSource: locator(),
        logMessages: locator(),
      ),
    )
    ..registerLazySingleton<GetSetupStep>(() => GetSetupStep(locator()))
    ..registerLazySingleton<SaveSetupStep>(() => SaveSetupStep(locator()))
    ..registerFactoryParam<SetupBloc, SetupStep, void>(
      (step, _) => SetupBloc(saveSetupStep: locator(), initialStep: step),
    );
}
