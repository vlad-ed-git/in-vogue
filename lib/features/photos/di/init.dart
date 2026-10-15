import 'package:get_it/get_it.dart';
import 'package:in_vogue/core/persistence/app_directory.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_check_data_source.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_picker_data_source.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_store_data_source.dart';
import 'package:in_vogue/features/photos/data/repositories/photo_repository_impl.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';
import 'package:in_vogue/features/photos/domain/usecases/check_full_length.dart';
import 'package:in_vogue/features/photos/domain/usecases/choose_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/get_kept_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/keep_photo.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:path/path.dart' as path;

void init(GetIt locator) {
  locator
    ..registerLazySingleton<PhotoPickerDataSource>(
      PhotoPickerDataSourceImpl.new,
    )
    ..registerLazySingleton<PhotoCheckDataSource>(PhotoCheckDataSourceImpl.new)
    ..registerLazySingleton<PhotoStoreDataSource>(
      () => PhotoStoreDataSourceImpl(
        directory: path.join(locator<AppDirectory>().path, 'photos'),
        store: locator(),
      ),
    )
    ..registerLazySingleton<PhotoRepository>(
      () => PhotoRepositoryImpl(
        pickerDataSource: locator(),
        checkDataSource: locator(),
        storeDataSource: locator(),
        logMessages: locator(),
      ),
    )
    ..registerLazySingleton<ChoosePhoto>(() => ChoosePhoto(locator()))
    ..registerLazySingleton<CheckFullLength>(() => CheckFullLength(locator()))
    ..registerLazySingleton<KeepPhoto>(() => KeepPhoto(locator()))
    ..registerLazySingleton<GetKeptPhoto>(() => GetKeptPhoto(locator()))
    ..registerFactoryParam<PhotoBloc, PhotoRole, void>(
      (role, _) => PhotoBloc(
        role: role,
        choosePhoto: locator(),
        checkFullLength: locator(),
        keepPhoto: locator(),
        getKeptPhoto: locator(),
      ),
    );
}
