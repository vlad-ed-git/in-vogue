import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';

/// Builds the screen of each setup step and tab.
class AppScreens {
  const AppScreens({required this.setup, required this.tab, this.tabs = _same});

  final Widget Function(SetupStep step) setup;
  final Widget Function(InVogueTab tab) tab;

  /// Wraps the tabs and their bar, for what they share.
  final Widget Function(Widget tabs) tabs;

  static Widget _same(Widget tabs) => tabs;
}
