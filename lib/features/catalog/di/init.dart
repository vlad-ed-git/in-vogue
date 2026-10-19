import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/core/persistence/app_directory.dart';
import 'package:in_vogue/features/catalog/data/data_sources/catalog_asset_data_source.dart';
import 'package:in_vogue/features/catalog/data/data_sources/outfit_catalog_local_data_source.dart';
import 'package:in_vogue/features/catalog/data/data_sources/outfit_catalog_remote_data_source.dart';
import 'package:in_vogue/features/catalog/data/data_sources/picks_local_data_source.dart';
import 'package:in_vogue/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:in_vogue/features/catalog/data/repositories/outfit_catalog_repository_impl.dart';
import 'package:in_vogue/features/catalog/data/repositories/picks_repository_impl.dart';
import 'package:in_vogue/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:in_vogue/features/catalog/domain/repositories/outfit_catalog_repository.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_picks.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_shop_pieces.dart';
import 'package:in_vogue/features/catalog/domain/usecases/set_pick.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/picks_bloc.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/your_picks_bloc.dart';
import 'package:path/path.dart' as path;

void init(GetIt locator) {
  locator
    ..registerLazySingleton<CatalogAssetDataSource>(
      () => CatalogAssetDataSourceImpl(rootBundle),
    )
    ..registerLazySingleton<PicksLocalDataSource>(
      () => PicksLocalDataSourceImpl(locator()),
    )
    ..registerLazySingleton<CatalogRepository>(
      () => CatalogRepositoryImpl(locator()),
    )
    ..registerLazySingleton<OutfitCatalogRemoteDataSource>(
      () => OutfitCatalogRemoteDataSourceImpl(FirebaseFirestore.instance),
    )
    ..registerLazySingleton<OutfitCatalogLocalDataSource>(
      () => OutfitCatalogLocalDataSourceImpl(
        path.join(locator<AppDirectory>().path, 'catalog', 'outfits.json'),
      ),
    )
    ..registerLazySingleton<OutfitCatalogRepository>(
      () => OutfitCatalogRepositoryImpl(
        remote: locator(),
        local: locator(),
        logMessages: locator(),
      ),
    )
    ..registerLazySingleton<PicksRepository>(
      () => PicksRepositoryImpl(locator()),
    )
    ..registerLazySingleton<GetSampleOutfits>(() => GetSampleOutfits(locator()))
    ..registerLazySingleton<GetCatalogPage>(() => GetCatalogPage(locator()))
    ..registerLazySingleton<GetOutfits>(() => GetOutfits(locator()))
    ..registerLazySingleton<GetPicks>(() => GetPicks(locator()))
    ..registerLazySingleton<GetShopPieces>(() => GetShopPieces(locator()))
    ..registerLazySingleton<GetOutfitShop>(() => GetOutfitShop(locator()))
    ..registerLazySingleton<SetPick>(() => SetPick(locator()))
    ..registerFactory<PicksBloc>(
      () => PicksBloc(
        getSampleOutfits: locator(),
        getCatalogPage: locator(),
        getPicks: locator(),
        setPick: locator(),
      ),
    )
    ..registerFactory<YourPicksBloc>(
      () => YourPicksBloc(
        getPicks: locator(),
        getOutfits: locator(),
        setPick: locator(),
      ),
    );
}
