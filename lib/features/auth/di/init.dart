import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:in_vogue/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/auth/domain/usecases/log_out.dart';
import 'package:in_vogue/features/auth/domain/usecases/sign_in.dart';
import 'package:in_vogue/features/auth/presentation/bloc/log_out_bloc.dart';
import 'package:in_vogue/features/auth/presentation/bloc/sign_in_bloc.dart';

void init(GetIt locator) {
  locator
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        googleClientId: Firebase.app().options.iosClientId,
      ),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: locator(),
        logMessages: locator(),
      ),
    )
    ..registerLazySingleton<SignIn>(() => SignIn(locator()))
    ..registerLazySingleton<GetCurrentAccount>(
      () => GetCurrentAccount(locator()),
    )
    ..registerLazySingleton<LogOut>(
      () => LogOut(
        auth: locator(),
        profile: locator(),
        days: locator(),
        analyses: locator(),
        widget: locator(),
      ),
    )
    ..registerFactory<SignInBloc>(
      () => SignInBloc(
        signIn: locator(),
        restoreFromAccount: locator(),
        saveSetupToAccount: locator(),
      ),
    )
    ..registerFactory<LogOutBloc>(() => LogOutBloc(logOut: locator()));
}
