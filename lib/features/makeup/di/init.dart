import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_remote_data_source.dart';
import 'package:in_vogue/core/persistence/app_directory.dart';
import 'package:in_vogue/features/makeup/data/data_sources/face_picture_data_source.dart';
import 'package:in_vogue/features/makeup/data/data_sources/look_picture_local_data_source.dart';
import 'package:in_vogue/features/makeup/data/data_sources/makeup_asset_data_source.dart';
import 'package:in_vogue/features/makeup/data/data_sources/makeup_job_local_data_source.dart';
import 'package:in_vogue/features/makeup/data/data_sources/makeup_remote_data_source.dart';
import 'package:in_vogue/features/makeup/data/repositories/makeup_job_repository_impl.dart';
import 'package:in_vogue/features/makeup/data/repositories/makeup_repository_impl.dart';
import 'package:in_vogue/features/makeup/data/repositories/makeup_service_repository_impl.dart';
import 'package:in_vogue/features/makeup/data/repositories/unavailable_makeup_service_repository.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_job_repository.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_service_repository.dart';
import 'package:in_vogue/features/makeup/domain/services/make_look.dart';
import 'package:in_vogue/features/makeup/domain/usecases/get_latest_makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/usecases/get_makeup_look.dart';
import 'package:path/path.dart' as path;

/// Without a YouCam client no makeup look can be made.
void init(GetIt locator) {
  locator
    ..registerLazySingleton<MakeupAssetDataSource>(
      () => MakeupAssetDataSourceImpl(rootBundle),
    )
    ..registerLazySingleton<MakeupRemoteDataSource>(
      () => MakeupRemoteDataSourceImpl(
        firestore: FirebaseFirestore.instance,
        storage: FirebaseStorage.instance,
      ),
    )
    ..registerLazySingleton<LookPictureLocalDataSource>(
      () => LookPictureLocalDataSourceImpl(
        path.join(locator<AppDirectory>().path, 'makeup'),
      ),
    )
    ..registerLazySingleton<MakeupRepository>(
      () => MakeupRepositoryImpl(
        assetDataSource: locator(),
        remoteDataSource: locator(),
        pictureDataSource: locator(),
        logMessages: locator(),
      ),
    )
    ..registerLazySingleton<MakeupJobLocalDataSource>(
      () => MakeupJobLocalDataSourceImpl(locator()),
    )
    ..registerLazySingleton<MakeupJobRepository>(
      () => MakeupJobRepositoryImpl(locator()),
    )
    ..registerLazySingleton<FacePictureDataSource>(
      () => const FacePictureDataSourceImpl(),
    )
    ..registerLazySingleton<MakeupServiceRepository>(
      () => locator.isRegistered<YouCamRemoteDataSource>()
          ? MakeupServiceRepositoryImpl(
              remoteDataSource: locator(),
              faceDataSource: locator(),
              logMessages: locator(),
            )
          : const UnavailableMakeupServiceRepository(),
    )
    ..registerLazySingleton<GetMakeupLook>(() => GetMakeupLook(locator()))
    ..registerLazySingleton<GetLatestMakeupLook>(
      () => GetLatestMakeupLook(locator()),
    )
    ..registerLazySingleton<MakeLook>(
      () => MakeLook(
        looks: locator(),
        service: locator(),
        budget: locator(),
        jobs: locator(),
        photos: locator(),
        saveSetupToAccount: locator(),
      ),
    );
}
