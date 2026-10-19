import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/features/stylist/data/data_sources/taste_local_data_source.dart';
import 'package:in_vogue/features/stylist/data/data_sources/taste_remote_data_source.dart';
import 'package:in_vogue/features/stylist/data/repositories/taste_repository_impl.dart';
import 'package:in_vogue/features/stylist/domain/repositories/taste_repository.dart';
import 'package:in_vogue/features/stylist/domain/usecases/recommend_outfit.dart';
import 'package:in_vogue/features/stylist/domain/usecases/record_signal.dart';

void init(GetIt locator) {
  locator
    ..registerLazySingleton<RecommendOutfit>(() => RecommendOutfit(locator()))
    ..registerLazySingleton<TasteLocalDataSource>(
      () => TasteLocalDataSourceImpl(locator()),
    )
    ..registerLazySingleton<TasteRemoteDataSource>(
      () => TasteRemoteDataSourceImpl(FirebaseFirestore.instance),
    )
    ..registerLazySingleton<TasteRepository>(
      () => TasteRepositoryImpl(
        local: locator(),
        remote: locator(),
        logMessages: locator(),
      ),
    )
    ..registerLazySingleton<RecordSignal>(
      () => RecordSignal(taste: locator(), getCurrentAccount: locator()),
    );
}
