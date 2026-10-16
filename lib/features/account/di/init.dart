import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/features/account/data/data_sources/account_remote_data_source.dart';
import 'package:in_vogue/features/account/data/repositories/account_repository_impl.dart';
import 'package:in_vogue/features/account/domain/repositories/account_repository.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';

void init(GetIt locator) {
  locator
    ..registerLazySingleton<AccountRemoteDataSource>(
      () => AccountRemoteDataSourceImpl(
        firestore: FirebaseFirestore.instance,
        storage: FirebaseStorage.instance,
      ),
    )
    ..registerLazySingleton<AccountRepository>(
      () => AccountRepositoryImpl(
        remoteDataSource: locator(),
        logMessages: locator(),
      ),
    )
    ..registerLazySingleton<SaveSetupToAccount>(
      () => SaveSetupToAccount(
        account: locator(),
        profile: locator(),
        location: locator(),
        photos: locator(),
        picks: locator(),
      ),
    );
}
