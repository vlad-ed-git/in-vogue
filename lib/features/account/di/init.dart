import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/core/persistence/app_directory.dart';
import 'package:in_vogue/features/account/data/data_sources/account_remote_data_source.dart';
import 'package:in_vogue/features/account/data/repositories/account_repository_impl.dart';
import 'package:in_vogue/features/account/domain/repositories/account_repository.dart';
import 'package:in_vogue/features/account/domain/usecases/delete_account.dart';
import 'package:in_vogue/features/account/domain/usecases/ensure_account.dart';
import 'package:in_vogue/features/account/domain/usecases/get_plan.dart';
import 'package:in_vogue/features/account/domain/usecases/restore_from_account.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
import 'package:in_vogue/features/account/presentation/bloc/delete_account_bloc.dart';
import 'package:path/path.dart' as path;

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
        downloadsDirectory: path.join(
          locator<AppDirectory>().path,
          'downloads',
        ),
        logMessages: locator(),
      ),
    )
    ..registerLazySingleton<RestoreFromAccount>(
      () => RestoreFromAccount(
        account: locator(),
        profile: locator(),
        photos: locator(),
        picks: locator(),
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
    )
    ..registerLazySingleton<GetPlan>(() => GetPlan(locator()))
    ..registerLazySingleton<DeleteAccount>(
      () => DeleteAccount(
        auth: locator(),
        account: locator(),
        photos: locator(),
        picks: locator(),
        profile: locator(),
        location: locator(),
        days: locator(),
        jobs: locator(),
        makeup: locator(),
        makeupJobs: locator(),
      ),
    )
    ..registerFactory<DeleteAccountBloc>(
      () => DeleteAccountBloc(deleteAccount: locator()),
    )
    ..registerLazySingleton<EnsureAccount>(
      () => EnsureAccount(
        auth: locator(),
        account: locator(),
        saveSetupToAccount: locator(),
      ),
    );
}
