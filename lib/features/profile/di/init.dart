import 'package:get_it/get_it.dart';
import 'package:in_vogue/features/profile/data/data_sources/profile_local_data_source.dart';
import 'package:in_vogue/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:in_vogue/features/profile/domain/repositories/profile_repository.dart';
import 'package:in_vogue/features/profile/domain/usecases/get_profile_name.dart';
import 'package:in_vogue/features/profile/domain/usecases/save_profile_name.dart';
import 'package:in_vogue/features/profile/presentation/bloc/profile_bloc.dart';

void init(GetIt locator) {
  locator
    ..registerLazySingleton<ProfileLocalDataSource>(
      () => ProfileLocalDataSourceImpl(locator()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(locator()),
    )
    ..registerLazySingleton<GetProfileName>(() => GetProfileName(locator()))
    ..registerLazySingleton<SaveProfileName>(() => SaveProfileName(locator()))
    ..registerFactory<ProfileBloc>(
      () => ProfileBloc(
        getProfileName: locator(),
        saveProfileName: locator(),
        getCurrentAccount: locator(),
        accountSync: locator(),
      ),
    );
}
