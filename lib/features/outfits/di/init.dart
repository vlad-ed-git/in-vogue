import 'package:get_it/get_it.dart';
import 'package:in_vogue/features/outfits/data/repositories/unavailable_try_on_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_repository.dart';
import 'package:in_vogue/features/outfits/domain/usecases/try_on_outfit.dart';

void init(GetIt locator) {
  locator
    ..registerLazySingleton<TryOnRepository>(UnavailableTryOnRepository.new)
    ..registerLazySingleton<TryOnOutfit>(() => TryOnOutfit(locator()));
}
