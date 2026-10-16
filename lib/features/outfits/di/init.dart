import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/core/persistence/app_directory.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_asset_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/try_on_job_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/unit_budget_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/you_cam_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/repositories/outfit_repository_impl.dart';
import 'package:in_vogue/features/outfits/data/repositories/try_on_job_repository_impl.dart';
import 'package:in_vogue/features/outfits/data/repositories/try_on_repository_impl.dart';
import 'package:in_vogue/features/outfits/data/repositories/unavailable_try_on_repository.dart';
import 'package:in_vogue/features/outfits/data/repositories/unit_budget_repository_impl.dart';
import 'package:in_vogue/features/outfits/domain/repositories/outfit_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_job_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/unit_budget_repository.dart';
import 'package:in_vogue/features/outfits/domain/services/make_outfit.dart';
import 'package:in_vogue/features/outfits/domain/usecases/get_day_outfit.dart';
import 'package:path/path.dart' as path;

/// Without a [youCamApiKey] no try-on can start.
void init(GetIt locator, {String? youCamApiKey}) {
  final key = youCamApiKey?.trim() ?? '';
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
    ..registerLazySingleton<UnitBudgetRemoteDataSource>(
      () => UnitBudgetRemoteDataSourceImpl(FirebaseFirestore.instance),
    )
    ..registerLazySingleton<UnitBudgetRepository>(
      () => UnitBudgetRepositoryImpl(
        remoteDataSource: locator(),
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
      () => key.isEmpty
          ? const UnavailableTryOnRepository()
          : TryOnRepositoryImpl(
              remoteDataSource: YouCamRemoteDataSourceImpl(
                api: Dio(
                  BaseOptions(
                    baseUrl: YouCamRemoteDataSourceImpl.baseUrl,
                    headers: {'Authorization': 'Bearer $key'},
                    connectTimeout: const Duration(seconds: 15),
                    receiveTimeout: const Duration(seconds: 30),
                  ),
                ),
                files: Dio(
                  BaseOptions(
                    connectTimeout: const Duration(seconds: 15),
                    receiveTimeout: const Duration(seconds: 60),
                    sendTimeout: const Duration(seconds: 60),
                  ),
                ),
              ),
              logMessages: locator(),
            ),
    )
    ..registerLazySingleton<GetDayOutfit>(() => GetDayOutfit(locator()))
    ..registerLazySingleton<MakeOutfit>(
      () => MakeOutfit(
        outfits: locator(),
        tryOn: locator(),
        budget: locator(),
        jobs: locator(),
        photos: locator(),
        picks: locator(),
        saveSetupToAccount: locator(),
      ),
    );
}
