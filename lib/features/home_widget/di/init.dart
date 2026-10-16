import 'package:get_it/get_it.dart';
import 'package:in_vogue/features/home_widget/data/repositories/unavailable_home_widget_repository.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';

void init(GetIt locator) {
  locator.registerLazySingleton<HomeWidgetRepository>(
    UnavailableHomeWidgetRepository.new,
  );
}
