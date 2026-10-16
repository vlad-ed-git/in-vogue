import 'package:get_it/get_it.dart';
import 'package:in_vogue/features/auth/data/repositories/unavailable_auth_repository.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';
import 'package:in_vogue/features/auth/domain/usecases/sign_in.dart';
import 'package:in_vogue/features/auth/presentation/bloc/sign_in_bloc.dart';

void init(GetIt locator) {
  locator
    ..registerLazySingleton<AuthRepository>(UnavailableAuthRepository.new)
    ..registerLazySingleton<SignIn>(() => SignIn(locator()))
    ..registerFactory<SignInBloc>(() => SignInBloc(signIn: locator()));
}
