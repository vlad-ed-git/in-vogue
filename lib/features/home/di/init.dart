import 'package:get_it/get_it.dart';
import 'package:in_vogue/features/home/presentation/bloc/home_bloc.dart';
import 'package:in_vogue/features/home/presentation/bloc/shop_bloc.dart';

void init(GetIt locator) {
  locator
    ..registerFactory<HomeBloc>(
      () => HomeBloc(
        getCurrentAccount: locator(),
        getSavedLocation: locator(),
        getKeptPhoto: locator(),
        getWeatherReport: locator(),
        followDay: locator(),
        getDefaultDay: locator(),
      ),
    )
    ..registerFactory<ShopBloc>(() => ShopBloc(getShopPieces: locator()));
}
