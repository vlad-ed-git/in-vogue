import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/design_system/design_system.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';

/// Pumps [child] the way the app shows it: the Paper theme, its builder and
/// the app's localizations, on a 390 × 844 phone unless [size] says otherwise.
Future<void> pumpInVogue(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
  double textScale = 1,
  Locale locale = const Locale('en'),
  TargetPlatform? platform,
  bool disableAnimations = false,
  bool scroll = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: disableAnimations);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final theme = platform == null
      ? InVogueTheme.paper
      : InVogueTheme.paper.copyWith(platform: platform);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      themeMode: ThemeMode.light,
      builder: InVogueTheme.builder,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SafeArea(
          child: scroll
              ? SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: InVogueLayout.pageMargin,
                  ),
                  child: child,
                )
              : child,
        ),
      ),
    ),
  );
}

/// A 1 × 1 transparent PNG, for components that need a photograph.
final testImage = MemoryImage(
  Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
);

/// The colour of the first [DecoratedBox] or [ColoredBox] painted for
/// [finder], whichever it is.
Color? fillOf(WidgetTester tester, Finder finder) {
  final widget = tester.widget(finder);
  if (widget is ColoredBox) return widget.color;
  if (widget is DecoratedBox) return (widget.decoration as BoxDecoration).color;
  if (widget is Container) return widget.color;
  throw ArgumentError('$widget has no fill');
}
