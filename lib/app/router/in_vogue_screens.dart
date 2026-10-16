import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:in_vogue/app/router/app_routes.dart';
import 'package:in_vogue/app/router/app_screens.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/auth/presentation/bloc/log_out_bloc.dart';
import 'package:in_vogue/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/picks_bloc.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/your_picks_bloc.dart';
import 'package:in_vogue/features/catalog/presentation/screens/your_picks_screen.dart';
import 'package:in_vogue/features/home/presentation/bloc/home_bloc.dart';
import 'package:in_vogue/features/home/presentation/bloc/shop_bloc.dart';
import 'package:in_vogue/features/home/presentation/screens/home_screen.dart';
import 'package:in_vogue/features/home/presentation/screens/shop_screen.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';
import 'package:in_vogue/features/location/presentation/bloc/location_bloc.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/profile/presentation/bloc/profile_bloc.dart';
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
    InVogueTab.home => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => locator<HomeBloc>()..add(const HomeStarted()),
        ),
        BlocProvider(create: (_) => locator<PicksBloc>()),
      ],
      child: Builder(
        builder: (context) => HomeScreen(
          onYourPicks: () => _push(
            context,
            (context) => BlocProvider(
              create: (_) =>
                  locator<YourPicksBloc>()..add(const YourPicksLoaded()),
              child: YourPicksScreen(onBack: () => Navigator.of(context).pop()),
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
    InVogueTab.settings => BlocProvider(
      create: (_) => locator<LogOutBloc>(),
      child: Builder(
        builder: (context) => SettingsScreen(
          onLoggedOut: () => context.read<SetupBloc>().add(
            const SetupStepReached(SetupStep.signIn),
          ),
        ),
      ),
    ),
    InVogueTab.makeup => const SizedBox.shrink(),
  },
);

/// Opens a full screen over the tabs.
void _push(BuildContext context, WidgetBuilder builder) => unawaited(
  Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute<void>(builder: builder)),
);
