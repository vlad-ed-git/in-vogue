import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/core/persistence/app_directory.dart';
import 'package:in_vogue/features/wardrobe/data/data_sources/wardrobe_photo_local_data_source.dart';
import 'package:in_vogue/features/wardrobe/data/data_sources/wardrobe_remote_data_source.dart';
import 'package:in_vogue/features/wardrobe/data/repositories/wardrobe_repository_impl.dart';
import 'package:in_vogue/features/wardrobe/domain/repositories/wardrobe_repository.dart';
import 'package:in_vogue/features/wardrobe/domain/usecases/wardrobe_usecases.dart';
import 'package:in_vogue/features/wardrobe/presentation/bloc/add_outfit_bloc.dart';
import 'package:in_vogue/features/wardrobe/presentation/bloc/wardrobe_bloc.dart';
import 'package:path/path.dart' as path;

void init(GetIt locator) {
  locator
    ..registerLazySingleton<WardrobeRemoteDataSource>(
      () => WardrobeRemoteDataSourceImpl(
        firestore: FirebaseFirestore.instance,
        storage: FirebaseStorage.instance,
      ),
    )
    ..registerLazySingleton<WardrobePhotoLocalDataSource>(
      () => WardrobePhotoLocalDataSourceImpl(
        path.join(locator<AppDirectory>().path, 'wardrobe'),
      ),
    )
    ..registerLazySingleton<WardrobeRepository>(
      () => WardrobeRepositoryImpl(
        remoteDataSource: locator(),
        photoDataSource: locator(),
        logMessages: locator(),
      ),
    )
    ..registerLazySingleton<WatchWardrobe>(() => WatchWardrobe(locator()))
    ..registerLazySingleton<AddToWardrobe>(() => AddToWardrobe(locator()))
    ..registerLazySingleton<RemoveFromWardrobe>(
      () => RemoveFromWardrobe(locator()),
    )
    ..registerFactory<WardrobeBloc>(
      () => WardrobeBloc(
        getCurrentAccount: locator(),
        watchWardrobe: locator(),
        removeFromWardrobe: locator(),
      ),
    )
    ..registerFactory<AddOutfitBloc>(
      () => AddOutfitBloc(
        getCurrentAccount: locator(),
        choosePhoto: locator(),
        addToWardrobe: locator(),
      ),
    );
}
