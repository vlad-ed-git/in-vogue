import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:in_vogue/app/router/app_routes.dart';
import 'package:in_vogue/app/router/app_screens.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/location/presentation/bloc/location_bloc.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/settings/presentation/screens/settings_screen.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/presentation/screens/welcome_screen.dart';
import 'package:in_vogue/features/setup/presentation/screens/your_photo_screen.dart';
import 'package:in_vogue/features/setup/presentation/setup_step_folio.dart';

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
          onDone: () => context.go(AppRoutes.forStep(SetupStep.firstOutfit)),
        ),
      ),
    ),
    _ => _PendingStep(step),
  },
  tab: (tab) => switch (tab) {
    InVogueTab.settings => const SettingsScreen(),
    InVogueTab.home || InVogueTab.makeup => const SizedBox.shrink(),
  },
);

/// A setup step whose screen is still to be built: Back and the folio.
class _PendingStep extends StatelessWidget {
  const _PendingStep(this.step);

  final SetupStep step;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: PageMargin(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (step.folio != null)
              BackBar(
                onBack: () => context.pop(),
                step: step.folio,
                total: SetupStepFolio.total,
              ),
          ],
        ),
      ),
    ),
  );
}
