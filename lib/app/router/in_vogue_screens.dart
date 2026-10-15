import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:in_vogue/app/router/app_screens.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/settings/presentation/screens/settings_screen.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/presentation/setup_step_folio.dart';

/// The app's screens.
const inVogueScreens = AppScreens(setup: _setupScreen, tab: _tabScreen);

Widget _setupScreen(SetupStep step) => _PendingStep(step);

Widget _tabScreen(InVogueTab tab) => switch (tab) {
  InVogueTab.settings => const SettingsScreen(),
  InVogueTab.home || InVogueTab.makeup => const SizedBox.shrink(),
};

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
