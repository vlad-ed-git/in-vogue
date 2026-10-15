import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/design_system/design_system.dart';

import '../../helpers/pump_in_vogue.dart';

void main() {
  final theme = InVogueTheme.paper;

  test('maps the tokens onto Material roles as the Flutter guide says', () {
    final scheme = theme.colorScheme;
    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.light);
    expect(scheme.primary, InVogueColors.signal);
    expect(scheme.onPrimary, InVogueColors.onSignal);
    expect(scheme.secondary, InVogueColors.accent);
    expect(scheme.onSecondary, InVogueColors.onAccent);
    expect(scheme.surface, InVogueColors.paper);
    expect(scheme.onSurface, InVogueColors.ink);
    expect(scheme.onSurfaceVariant, InVogueColors.graphite);
    expect(scheme.surfaceContainerHighest, InVogueColors.accent);
    expect(scheme.outline, InVogueColors.line);
    expect(scheme.outlineVariant, InVogueColors.rule);
    expect(scheme.error, InVogueColors.ink, reason: 'no error red');
    expect(scheme.onError, InVogueColors.paper);
    expect(scheme.scrim, InVogueColors.ink);
    expect(scheme.shadow.a, 0, reason: 'nothing casts a shadow');
    expect(scheme.surfaceTint.a, 0, reason: 'no elevation tint');
    expect(theme.scaffoldBackgroundColor, InVogueColors.paper);
    expect(theme.splashFactory, NoSplash.splashFactory);
  });

  test('maps the type roles onto the text theme', () {
    final text = theme.textTheme;
    void same(TextStyle? actual, TextStyle expected) {
      expect(actual!.fontFamily, expected.fontFamily);
      expect(actual.fontSize, expected.fontSize);
      expect(actual.height, expected.height);
      expect(actual.fontWeight, expected.fontWeight);
      expect(actual.letterSpacing, expected.letterSpacing);
      expect(actual.leadingDistribution, TextLeadingDistribution.even);
    }

    same(text.displayLarge, InVogueType.numeral);
    same(text.displayMedium, InVogueType.headline);
    same(text.headlineLarge, InVogueType.title);
    same(text.headlineSmall, InVogueType.section);
    same(text.titleMedium, InVogueType.bodyStrong);
    same(text.titleSmall, InVogueType.item);
    same(text.bodyLarge, InVogueType.body);
    same(text.bodyMedium, InVogueType.meta);
    same(text.labelLarge, InVogueType.button);
    same(text.labelSmall, InVogueType.label);
    same(text.bodySmall, InVogueType.caption);
    for (final style in [
      text.displaySmall,
      text.headlineMedium,
      text.titleLarge,
      text.labelMedium,
    ]) {
      expect(style!.letterSpacing, isNotNull, reason: 'no Material tracking');
    }
  });

  test('cuts every surface square and flat', () {
    expect(theme.bottomSheetTheme.shape, const RoundedRectangleBorder());
    expect(theme.bottomSheetTheme.elevation, 0);
    expect(theme.bottomSheetTheme.modalBarrierColor, InVogueColors.veil);
    expect(theme.dialogTheme.shape, const RoundedRectangleBorder());
    expect(theme.dialogTheme.elevation, 0);
    expect(theme.cardTheme.elevation, 0);
    expect(theme.appBarTheme.elevation, 0);
    expect(theme.appBarTheme.scrolledUnderElevation, 0);
    expect(theme.snackBarTheme.shape, const RoundedRectangleBorder());
    final filled = theme.filledButtonTheme.style!;
    expect(filled.shape!.resolve({}), const RoundedRectangleBorder());
    expect(filled.elevation!.resolve({}), 0);
    expect(filled.minimumSize!.resolve({}), const Size(0, 52));
  });

  testWidgets('stock filled buttons follow the button tokens', (tester) async {
    await pumpInVogue(
      tester,
      Column(
        children: [
          FilledButton(onPressed: () {}, child: const Text('Primary')),
          FilledButton.tonal(onPressed: () {}, child: const Text('Second')),
          const FilledButton(onPressed: null, child: Text('Disabled')),
        ],
      ),
    );
    Color background(String label) {
      final material = tester.widget<Material>(
        find.descendant(
          of: find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          ),
          matching: find.byType(Material),
        ),
      );
      return material.color!;
    }

    expect(background('Primary'), InVogueColors.signal);
    expect(background('Second'), InVogueColors.accent);
    expect(background('Disabled'), InVogueColors.studio);
  });

  testWidgets('ignores the phone appearance and caps text at 200%', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    late BuildContext captured;
    await pumpInVogue(
      tester,
      Builder(
        builder: (context) {
          captured = context;
          return const Text('In Vogue');
        },
      ),
      textScale: 3.1,
    );
    expect(Theme.of(captured).brightness, Brightness.light);
    expect(MediaQuery.platformBrightnessOf(captured), Brightness.light);
    expect(MediaQuery.textScalerOf(captured).scale(10), 20);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor ??
          Theme.of(captured).scaffoldBackgroundColor,
      InVogueColors.paper,
    );
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
    );
    expect(region.value.statusBarIconBrightness, Brightness.dark);
    expect(region.value.statusBarBrightness, Brightness.light);
    expect(region.value.systemNavigationBarColor, InVogueColors.paper);
  });
}
