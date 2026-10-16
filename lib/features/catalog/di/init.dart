import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/features/catalog/data/data_sources/catalog_asset_data_source.dart';
import 'package:in_vogue/features/catalog/data/data_sources/picks_local_data_source.dart';
import 'package:in_vogue/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:in_vogue/features/catalog/data/repositories/picks_repository_impl.dart';
import 'package:in_vogue/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_picks.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_pieces_for_weather.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_shop_pieces.dart';
import 'package:in_vogue/features/catalog/domain/usecases/set_pick.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/picks_bloc.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/your_picks_bloc.dart';

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
    ..registerLazySingleton<PicksRepository>(
      () => PicksRepositoryImpl(locator()),
    )
    ..registerLazySingleton<GetPiecesForWeather>(
      () => GetPiecesForWeather(locator()),
    )
    ..registerLazySingleton<GetPicks>(() => GetPicks(locator()))
    ..registerLazySingleton<GetShopPieces>(() => GetShopPieces(locator()))
    ..registerLazySingleton<SetPick>(() => SetPick(locator()))
    ..registerFactory<PicksBloc>(
      () => PicksBloc(
        getPiecesForWeather: locator(),
        getPicks: locator(),
        setPick: locator(),
      ),
    )
    ..registerFactory<YourPicksBloc>(
      () => YourPicksBloc(
        getPicks: locator(),
        getShopPieces: locator(),
        setPick: locator(),
      ),
    );
}
