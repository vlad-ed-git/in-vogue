import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_remote_data_source.dart';
import 'package:in_vogue/core/persistence/app_directory.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_asset_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/try_on_job_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/repositories/outfit_repository_impl.dart';
import 'package:in_vogue/features/outfits/data/repositories/try_on_job_repository_impl.dart';
import 'package:in_vogue/features/outfits/data/repositories/try_on_repository_impl.dart';
import 'package:in_vogue/features/outfits/data/repositories/unavailable_try_on_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/outfit_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_job_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_repository.dart';
import 'package:in_vogue/features/outfits/domain/services/make_outfit.dart';
import 'package:in_vogue/features/outfits/domain/usecases/get_day_outfit.dart';
import 'package:path/path.dart' as path;

/// Without a YouCam client no try-on can start.
void init(GetIt locator) {
  locator
    ..registerLazySingleton<OutfitAssetDataSource>(
      () => OutfitAssetDataSourceImpl(rootBundle),
    )
    ..registerLazySingleton<OutfitRemoteDataSource>(
      () => OutfitRemoteDataSourceImpl(
        firestore: FirebaseFirestore.instance,
        storage: FirebaseStorage.instance,
      ),
    )
    ..registerLazySingleton<OutfitPictureLocalDataSource>(
      () => OutfitPictureLocalDataSourceImpl(
        path.join(locator<AppDirectory>().path, 'outfits'),
      ),
    )
    ..registerLazySingleton<OutfitRepository>(
      () => OutfitRepositoryImpl(
        assetDataSource: locator(),
        remoteDataSource: locator(),
        pictureDataSource: locator(),
        logMessages: locator(),
      ),
    )
    ..registerLazySingleton<TryOnJobLocalDataSource>(
      () => TryOnJobLocalDataSourceImpl(locator()),
    )
    ..registerLazySingleton<TryOnJobRepository>(
      () => TryOnJobRepositoryImpl(locator()),
    )
    ..registerLazySingleton<TryOnRepository>(
      () => locator.isRegistered<YouCamRemoteDataSource>()
          ? TryOnRepositoryImpl(
              remoteDataSource: locator(),
              logMessages: locator(),
            )
          : const UnavailableTryOnRepository(),
    )
    ..registerLazySingleton<GetDayOutfit>(() => GetDayOutfit(locator()))
    ..registerLazySingleton<MakeOutfit>(
      () => MakeOutfit(
        outfits: locator(),
        tryOn: locator(),
        jobs: locator(),
        photos: locator(),
        picks: locator(),
        saveSetupToAccount: locator(),
      ),
    );
}
