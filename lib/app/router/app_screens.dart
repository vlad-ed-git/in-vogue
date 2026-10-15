import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';

/// Builds the screen of each setup step and tab.
class AppScreens {
  const AppScreens({required this.setup, required this.tab});

  final Widget Function(SetupStep step) setup;
  final Widget Function(InVogueTab tab) tab;
}
