import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:in_vogue/app/router/app_routes.dart';
import 'package:in_vogue/app/router/app_screens.dart';
import 'package:in_vogue/app/router/tab_shell.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/account/presentation/bloc/delete_account_bloc.dart';
import 'package:in_vogue/features/auth/presentation/bloc/log_out_bloc.dart';
import 'package:in_vogue/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/picks_bloc.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/your_picks_bloc.dart';
import 'package:in_vogue/features/catalog/presentation/screens/your_picks_screen.dart';
import 'package:in_vogue/features/colours/presentation/bloc/colours_bloc.dart';
import 'package:in_vogue/features/colours/presentation/screens/mirror_screen.dart';
import 'package:in_vogue/features/home/presentation/bloc/home_bloc.dart';
import 'package:in_vogue/features/home/presentation/bloc/shop_bloc.dart';
import 'package:in_vogue/features/home/presentation/screens/home_screen.dart';
import 'package:in_vogue/features/home/presentation/screens/shop_screen.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';
import 'package:in_vogue/features/home_widget/presentation/bloc/home_widget_bloc.dart';
import 'package:in_vogue/features/home_widget/presentation/widgets/home_widget_sync.dart';
import 'package:in_vogue/features/location/presentation/bloc/location_bloc.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:in_vogue/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:in_vogue/features/settings/presentation/screens/settings_screen.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:in_vogue/features/setup/presentation/screens/about_you_screen.dart';
import 'package:in_vogue/features/setup/presentation/screens/add_widget_screen.dart';
import 'package:in_vogue/features/setup/presentation/screens/picks_screen.dart';
import 'package:in_vogue/features/setup/presentation/screens/sign_in_screen.dart';
import 'package:in_vogue/features/setup/presentation/screens/welcome_screen.dart';
import 'package:in_vogue/features/setup/presentation/screens/your_photo_screen.dart';
import 'package:in_vogue/features/weather/presentation/bloc/forecast_bloc.dart';

/// The app's screens, with their blocs from [locator].
AppScreens inVogueScreens(GetIt locator) => AppScreens(
  tabs: (tabs) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => locator<HomeBloc>()..add(const HomeStarted()),
      ),
      BlocProvider(
        create: (_) =>
            locator<HomeWidgetBloc>()..add(const HomeWidgetStarted()),
      ),
    ],
    child: HomeWidgetSync(
      onOpenHome: (context) => context.go(AppRoutes.home),
      child: tabs,
    ),
  ),
  setup: (step) => switch (step) {
    SetupStep.welcome => BlocProvider(
      create: (_) => locator<LocationBloc>(),
      child: Builder(
        builder: (context) => WelcomeScreen(
          onLocated: () => context.go(AppRoutes.forStep(SetupStep.photo)),
        ),
      ),
    ),
    SetupStep.photo => BlocProvider(
      create: (_) =>
          locator<PhotoBloc>(param1: PhotoRole.body)..add(const PhotoLoaded()),
      child: Builder(
        builder: (context) => YourPhotoScreen(
          onBack: () => context.pop(),
          onDone: () => context.go(AppRoutes.forStep(SetupStep.picks)),
        ),
      ),
    ),
    SetupStep.picks => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              locator<ForecastBloc>()..add(const ForecastRequested()),
        ),
        BlocProvider(create: (_) => locator<PicksBloc>()),
      ],
      child: Builder(
        builder: (context) => PicksScreen(
          onBack: () => context.pop(),
          onProceed: () => context.go(AppRoutes.forStep(SetupStep.signIn)),
        ),
      ),
    ),
    SetupStep.signIn => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => locator<SignInBloc>()),
        BlocProvider(
          create: (_) =>
              locator<PhotoBloc>(param1: PhotoRole.body)
                ..add(const PhotoLoaded()),
        ),
      ],
      child: Builder(
        builder: (context) => SignInScreen(
          onBack: () => context.pop(),
          onSignedIn: (_) => context.go(AppRoutes.forStep(SetupStep.profile)),
        ),
      ),
    ),
    SetupStep.profile => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => locator<ProfileBloc>()..add(const ProfileLoaded()),
        ),
        BlocProvider(
          create: (_) =>
              locator<PhotoBloc>(param1: PhotoRole.face)
                ..add(const PhotoLoaded()),
        ),
      ],
      child: Builder(
        builder: (context) => AboutYouScreen(
          onBack: () => context.pop(),
          onDone: () => context.go(AppRoutes.forStep(SetupStep.widget)),
        ),
      ),
    ),
    SetupStep.widget => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              locator<ForecastBloc>()..add(const ForecastRequested()),
        ),
        BlocProvider(
          create: (_) =>
              locator<PhotoBloc>(param1: PhotoRole.body)
                ..add(const PhotoLoaded()),
        ),
      ],
      child: Builder(
        builder: (context) => AddWidgetScreen(
          onBack: () => context.pop(),
          onFinish: () => context.read<SetupBloc>().add(
            const SetupStepReached(SetupStep.done),
          ),
          onAddWidget: locator<HomeWidgetRepository>().requestPin,
        ),
      ),
    ),
    SetupStep.done => throw ArgumentError.value(step, 'step', 'Has no screen'),
  },
  tab: (tab) => switch (tab) {
    InVogueTab.home => BlocProvider(
      create: (_) => locator<PicksBloc>(),
      child: _OnTabShown(
        tab: InVogueTab.home,
        onShown: (context) => context.read<HomeBloc>().add(const HomeStarted()),
        child: Builder(
          builder: (context) => HomeScreen(
            onYourPicks: () => _push(
              context,
              (context) => BlocProvider(
                create: (_) =>
                    locator<YourPicksBloc>()..add(const YourPicksLoaded()),
                child: YourPicksScreen(
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            onShop: (outfit) => _push(
              context,
              (context) => BlocProvider(
                create: (_) =>
                    locator<ShopBloc>()
                      ..add(ShopRequested(outfit.outfit.outsideIn)),
                child: ShopScreen(onBack: () => Navigator.of(context).pop()),
              ),
            ),
          ),
        ),
      ),
    ),
    InVogueTab.settings => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => locator<LogOutBloc>()),
        BlocProvider(
          create: (_) => locator<SettingsBloc>()..add(const SettingsLoaded()),
        ),
        BlocProvider(
          create: (_) => locator<ProfileBloc>()..add(const ProfileLoaded()),
        ),
        BlocProvider(
          create: (_) =>
              locator<PhotoBloc>(param1: PhotoRole.face)
                ..add(const PhotoLoaded()),
        ),
        BlocProvider(create: (_) => locator<LocationBloc>()),
        BlocProvider(create: (_) => locator<DeleteAccountBloc>()),
      ],
      child: Builder(
        builder: (context) => SettingsScreen(
          onLoggedOut: () => context.read<SetupBloc>().add(
            const SetupStepReached(SetupStep.signIn),
          ),
          onAccountDeleted: () => context.read<SetupBloc>().add(
            const SetupStepReached(SetupStep.welcome),
          ),
          bodyPhoto: () => locator<PhotoBloc>(param1: PhotoRole.body),
          onAddWidget: locator<HomeWidgetRepository>().requestPin,
        ),
      ),
    ),
    InVogueTab.mirror => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => locator<ColoursBloc>()..add(const ColoursShown()),
        ),
        BlocProvider(
          create: (_) =>
              locator<PhotoBloc>(param1: PhotoRole.face)
                ..add(const PhotoLoaded()),
        ),
      ],
      child: _OnTabShown(
        tab: InVogueTab.mirror,
        // The face photo may have been replaced in Settings.
        onShown: (context) =>
            context.read<PhotoBloc>().add(const PhotoLoaded()),
        child: const MirrorScreen(),
      ),
    ),
  },
);

/// Opens a full screen over the tabs.
void _push(BuildContext context, WidgetBuilder builder) => unawaited(
  Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute<void>(builder: builder)),
);

/// Calls [onShown] each time [tab] comes back on screen, so changes made
/// on other tabs show there.
class _OnTabShown extends StatefulWidget {
  const _OnTabShown({
    required this.tab,
    required this.onShown,
    required this.child,
  });

  final InVogueTab tab;
  final void Function(BuildContext context) onShown;
  final Widget child;

  @override
  State<_OnTabShown> createState() => _OnTabShownState();
}

class _OnTabShownState extends State<_OnTabShown> {
  InVogueTab? _tab;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tab = CurrentTab.of(context);
    if (_tab != null && _tab != tab && tab == widget.tab) {
      widget.onShown(context);
    }
    _tab = tab;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
