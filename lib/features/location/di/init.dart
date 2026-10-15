import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/features/location/data/data_sources/location_device_data_source.dart';
import 'package:in_vogue/features/location/data/data_sources/location_local_data_source.dart';
import 'package:in_vogue/features/location/data/repositories/location_repository_impl.dart';
import 'package:in_vogue/features/location/domain/repositories/location_repository.dart';
import 'package:in_vogue/features/location/domain/usecases/get_saved_location.dart';
import 'package:in_vogue/features/location/domain/usecases/locate_user.dart';
import 'package:in_vogue/features/location/domain/usecases/open_location_settings.dart';
import 'package:in_vogue/features/location/presentation/bloc/location_bloc.dart';

void init(GetIt locator) {
  locator
    ..registerLazySingleton<LocationDeviceDataSource>(
      () => LocationDeviceDataSourceImpl(
        geolocator: GeolocatorPlatform.instance,
        geocoding: Geocoding(),
      ),
    )
    ..registerLazySingleton<LocationLocalDataSource>(
      () => LocationLocalDataSourceImpl(locator()),
    )
    ..registerLazySingleton<LocationRepository>(
      () => LocationRepositoryImpl(
        deviceDataSource: locator(),
        localDataSource: locator(),
        logMessages: locator(),
      ),
    )
    ..registerLazySingleton<LocateUser>(() => LocateUser(locator()))
    ..registerLazySingleton<GetSavedLocation>(() => GetSavedLocation(locator()))
    ..registerLazySingleton<OpenLocationSettings>(
      () => OpenLocationSettings(locator()),
    )
    ..registerFactory<LocationBloc>(
      () =>
          LocationBloc(locateUser: locator(), openLocationSettings: locator()),
    );
}
