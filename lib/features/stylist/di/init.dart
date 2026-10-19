import 'package:get_it/get_it.dart';
import 'package:in_vogue/features/stylist/domain/usecases/recommend_outfit.dart';

void init(GetIt locator) {
  locator.registerLazySingleton<RecommendOutfit>(
    () => RecommendOutfit(locator()),
  );
}
