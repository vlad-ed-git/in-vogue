import 'package:get_it/get_it.dart';
import 'package:in_vogue/features/settings/presentation/bloc/settings_bloc.dart';

void init(GetIt locator) {
  locator.registerFactory<SettingsBloc>(
    () => SettingsBloc(
      getCurrentAccount: locator(),
      getPlan: locator(),
      getSavedLocation: locator(),
      getDefaultDay: locator(),
      setDefaultDay: locator(),
      saveSetupToAccount: locator(),
    ),
  );
}
