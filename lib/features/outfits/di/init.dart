import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_remote_data_source.dart';
import 'package:in_vogue/core/persistence/app_directory.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
import 'package:in_vogue/features/outfits/data/data_sources/day_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/try_on_job_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/repositories/day_repository_impl.dart';
import 'package:in_vogue/features/outfits/data/repositories/shared_try_on_job_repository.dart';
import 'package:in_vogue/features/outfits/data/repositories/try_on_job_repository_impl.dart';
import 'package:in_vogue/features/outfits/data/repositories/try_on_repository_impl.dart';
import 'package:in_vogue/features/outfits/data/repositories/unavailable_try_on_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/day_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_job_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_repository.dart';
import 'package:in_vogue/features/outfits/domain/services/follow_day.dart';
import 'package:in_vogue/features/outfits/domain/services/make_outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';
import 'package:in_vogue/features/stylist/domain/usecases/record_signal.dart';
import 'package:path/path.dart' as path;

/// Without a YouCam client no try-on can start.
void init(GetIt locator) {
  locator
    ..registerLazySingleton<OutfitPictureLocalDataSource>(
      () => OutfitPictureLocalDataSourceImpl(
        path.join(locator<AppDirectory>().path, 'outfits'),
      ),
    )
    ..registerLazySingleton<DayRemoteDataSource>(
      () => DayRemoteDataSourceImpl(FirebaseFirestore.instance),
    )
    ..registerLazySingleton<OutfitPictureRemoteDataSource>(
      () => OutfitPictureRemoteDataSourceImpl(FirebaseStorage.instance),
    )
    ..registerLazySingleton<DayRepository>(
      () => DayRepositoryImpl(
        remoteDataSource: locator(),
        pictureRemoteDataSource: locator(),
        pictureLocalDataSource: locator(),
        fingerprints: locator(),
        logMessages: locator(),
      ),
    )
    ..registerLazySingleton<TryOnJobLocalDataSource>(
      () => TryOnJobLocalDataSourceImpl(locator()),
    )
    ..registerLazySingleton<TryOnJobRepository>(
      () => SharedTryOnJobRepository(
        path.join(locator<AppDirectory>().path, 'try_on_jobs'),
        legacy: TryOnJobRepositoryImpl(locator()),
      ),
    )
    ..registerLazySingleton<TryOnRepository>(
      () => locator.isRegistered<YouCamRemoteDataSource>()
          ? TryOnRepositoryImpl(
              remoteDataSource: locator(),
              logMessages: locator(),
            )
          : const UnavailableTryOnRepository(),
    )
    ..registerLazySingleton<MakeOutfit>(
      () => MakeOutfit(
        logMessages: locator(),
        catalog: locator(),
        recommend: locator(),
        colours: locator(),
        taste: locator(),
        recordSignal: locator<RecordSignal>().call,
        days: locator(),
        tryOn: locator(),
        jobs: locator(),
        loadBodyPhoto: () => locator<PhotoRepository>().kept(PhotoRole.body),
        saveSetupToAccount: locator<SaveSetupToAccount>().call,
        installId: locator(),
      ),
    )
    ..registerLazySingleton<FollowDay>(
      () => FollowDay(
        days: locator(),
        catalog: locator(),
        makeOutfit: locator(),
        installId: locator(),
      ),
    );
}
