import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

/// The design spec lives beside the app repository. When it is present, the
/// Dart tokens must match it exactly; a fresh checkout without it skips.
final _spec = File('../design-spec/tokens.json');

Map<String, dynamic> _readSpec() =>
    jsonDecode(_spec.readAsStringSync()) as Map<String, dynamic>;

Iterable<Map<String, dynamic>> _tokens(Map<String, dynamic> group) =>
    (group['tokens'] as List<dynamic>).cast<Map<String, dynamic>>();

double _px(Object? value) =>
    double.parse((value! as String).replaceAll(RegExp('px|ms'), ''));

Color _hex(String value) {
  final hex = value.substring(1);
  final rgb = int.parse(hex.substring(0, 6), radix: 16);
  final alpha = hex.length == 8 ? int.parse(hex.substring(6), radix: 16) : 255;
  return Color((alpha << 24) | rgb);
}

double _luminance(Color color) {
  double channel(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4) as double;
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('colour tokens', () {
    const colors = {
      'paper': InVogueColors.paper,
      'studio': InVogueColors.studio,
      'ink': InVogueColors.ink,
      'graphite': InVogueColors.graphite,
      'rule': InVogueColors.rule,
      'line': InVogueColors.line,
      'signal': InVogueColors.signal,
      'signal-pressed': InVogueColors.signalPressed,
      'on-signal': InVogueColors.onSignal,
      'accent': InVogueColors.accent,
      'accent-pressed': InVogueColors.accentPressed,
      'on-accent': InVogueColors.onAccent,
      'veil': InVogueColors.veil,
      'wallpaper': InVogueColors.wallpaper,
      'rouge': InVogueColors.rouge,
      'rose': InVogueColors.rose,
      'rose-muted': InVogueColors.roseMuted,
    };

    test('match the design spec', () {
      if (!_spec.existsSync()) return markTestSkipped('design-spec absent');
      final spec = _tokens(_readSpec()['color'] as Map<String, dynamic>);
      final names = spec.map((token) => token['name']).toSet();
      expect(names, {...colors.keys, 'alert'});
      for (final token in spec) {
        final name = token['name'] as String;
        if (name == 'alert') {
          expect(token['value'], '{ink}');
          expect(InVogueColors.alert, InVogueColors.ink);
        } else {
          expect(colors[name], _hex(token['value'] as String), reason: name);
        }
      }
    });

    test('meet the contrast ratios the colour guide promises', () {
      // The guide rounds its ratios; each pair must reach at least that.
      void expectRatio(Color text, Color on, double ratio) => expect(
        _contrast(text, on),
        greaterThanOrEqualTo(ratio - 0.05),
        reason: '$text on $on',
      );
      expectRatio(InVogueColors.ink, InVogueColors.paper, 18.4);
      expectRatio(InVogueColors.graphite, InVogueColors.paper, 6.5);
      expectRatio(InVogueColors.onSignal, InVogueColors.signal, 9.5);
      expectRatio(InVogueColors.onSignal, InVogueColors.signalPressed, 11.6);
      expectRatio(InVogueColors.ink, InVogueColors.accent, 13.4);
      expectRatio(InVogueColors.graphite, InVogueColors.accent, 4.7);
      expectRatio(InVogueColors.ink, InVogueColors.accentPressed, 11.8);
      expectRatio(InVogueColors.line, InVogueColors.paper, 3.5);
      expectRatio(InVogueColors.rose, InVogueColors.rouge, 6.9);
      // The guide documents 5.3:1; it measures 5.07:1, still AA for text.
      expectRatio(InVogueColors.roseMuted, InVogueColors.rouge, 4.55);
      expectRatio(InVogueColors.ink, InVogueColors.studio, 15.7);
      expectRatio(InVogueColors.graphite, InVogueColors.studio, 5.5);
    });
  });

  group('type tokens', () {
    const styles = {
      'numeral': InVogueType.numeral,
      'numeral-s': InVogueType.numeralSmall,
      'headline': InVogueType.headline,
      'title': InVogueType.title,
      'section': InVogueType.section,
      'tab': InVogueType.tab,
      'figure': InVogueType.figure,
      'body-strong': InVogueType.bodyStrong,
      'item': InVogueType.item,
      'body': InVogueType.body,
      'meta': InVogueType.meta,
      'button': InVogueType.button,
      'link': InVogueType.link,
      'label': InVogueType.label,
      'caption': InVogueType.caption,
      'nav': InVogueType.nav,
    };

    test('match the design spec size, line, weight and tracking', () {
      if (!_spec.existsSync()) return markTestSkipped('design-spec absent');
      final type = _readSpec()['type'] as Map<String, dynamic>;
      final families = type['families'] as Map<String, dynamic>;
      final seen = <String>{};
      for (final group in (type['groups'] as List<dynamic>)) {
        group as Map<String, dynamic>;
        final family = group['family'] == 'display'
            ? InVogueType.displayFamily
            : InVogueType.textFamily;
        expect(families[group['family']] as String, contains('"$family"'));
        for (final raw in (group['styles'] as List<dynamic>)) {
          final spec = raw as Map<String, dynamic>;
          final name = spec['name'] as String;
          final style = styles[name]!;
          seen.add(name);
          final size = _px(spec['fontSize']);
          final weight = spec['fontWeight'] as int;
          expect(style.fontFamily, family, reason: name);
          expect(style.fontSize, size, reason: name);
          expect(
            style.fontSize! * style.height!,
            closeTo(_px(spec['lineHeight']), 1e-9),
            reason: name,
          );
          expect(
            style.fontWeight,
            FontWeight.values[weight ~/ 100 - 1],
            reason: name,
          );
          expect(style.fontVariations, [
            FontVariation('wght', weight.toDouble()),
          ], reason: name);
          final em = spec['letterSpacing'] == null
              ? 0.0
              : double.parse(
                  (spec['letterSpacing'] as String).replaceAll('em', ''),
                );
          expect(
            style.letterSpacing ?? 0,
            closeTo(em * size, 1e-9),
            reason: name,
          );
          expect(
            style.leadingDistribution,
            TextLeadingDistribution.even,
            reason: name,
          );
          expect(
            style.fontFamilyFallback,
            InVogueType.cjkFallback,
            reason: name,
          );
        }
      }
      expect(seen, styles.keys.toSet());
    });

    test('active tab and nav styles only change weight and colour', () {
      for (final (inactive, active) in [
        (InVogueType.tab, InVogueType.tabActive),
        (InVogueType.nav, InVogueType.navActive),
      ]) {
        expect(inactive.color, InVogueColors.graphite);
        expect(active.color, InVogueColors.ink);
        expect(active.fontWeight, FontWeight.w700);
        expect(active.fontSize, inactive.fontSize);
        expect(active.height, inactive.height);
      }
    });

    test('every line height but the title sits on the 4-point baseline', () {
      // tokens.json sets the title at 40 / 38, the spec's one exception.
      for (final style in styles.values.where((s) => s != InVogueType.title)) {
        final line = style.fontSize! * style.height!;
        expect(
          line % InVogueLayout.baseline,
          closeTo(0, 1e-9),
          reason: '$style',
        );
      }
    });

    test('the degree sign is Sofia Sans 200 at 86% on the numeral line', () {
      final degree = InVogueType.degreeFor(InVogueType.numeral);
      expect(degree.fontFamily, InVogueType.textFamily);
      expect(degree.fontWeight, FontWeight.w200);
      expect(degree.fontSize, closeTo(84 * 0.86, 1e-9));
      expect(degree.fontSize! * degree.height!, closeTo(64, 1e-9));
      final relative = InVogueType.degreeFor(
        InVogueType.numeral.copyWith(fontSize: 150, height: 0.74),
        relativeLineHeight: true,
      );
      expect(relative.height, 0.74);
      expect(relative.fontSize, closeTo(129, 1e-9));
    });
  });

  group('space, layout, motion', () {
    test('match the design spec', () {
      if (!_spec.existsSync()) return markTestSkipped('design-spec absent');
      final spec = _readSpec();
      Map<String, Object?> values(String group) => {
        for (final token in _tokens(spec[group] as Map<String, dynamic>))
          token['name'] as String: token['value'],
      };

      expect(values('spacing').map((k, v) => MapEntry(k, _px(v))), {
        'space-1': InVogueSpace.s1,
        'space-2': InVogueSpace.s2,
        'space-3': InVogueSpace.s3,
        'space-4': InVogueSpace.s4,
        'space-5': InVogueSpace.s5,
        'space-6': InVogueSpace.s6,
        'space-8': InVogueSpace.s8,
        'space-10': InVogueSpace.s10,
        'space-12': InVogueSpace.s12,
        'space-16': InVogueSpace.s16,
      });

      final layout = values('layout');
      expect(_px(layout['page-margin']), InVogueLayout.pageMargin);
      expect(
        _px(layout['page-margin-compact']),
        InVogueLayout.pageMarginCompact,
      );
      expect(_px(layout['gutter']), InVogueLayout.gutter);
      expect(int.parse(layout['columns']! as String), InVogueLayout.columns);
      expect(_px(layout['baseline']), InVogueLayout.baseline);
      expect(_px(layout['control-height']), InVogueLayout.controlHeight);
      expect(_px(layout['target-min']), InVogueLayout.targetMin);
      expect(_px(layout['topbar-height']), InVogueLayout.topBarHeight);
      expect(_px(layout['tabbar-height']), InVogueLayout.tabBarHeight);
      expect(_px(layout['stage-min']), InVogueLayout.stageMin);

      final stroke = values('stroke');
      expect(_px(stroke['stroke-hairline']), InVogueLayout.strokeHairline);
      expect(_px(stroke['stroke-select']), InVogueLayout.strokeSelect);
      final radius = values('radius');
      expect(radius['radius-none'], '0');
      expect(_px(radius['radius-round']), InVogueLayout.radiusRound);
      final opacity = values('opacity');
      expect(
        double.parse(opacity['opacity-waiting']! as String),
        InVogueLayout.opacityWaiting,
      );
      expect(
        double.parse(opacity['opacity-locked']! as String),
        InVogueLayout.opacityLocked,
      );

      final durations = values('duration');
      expect(
        {
          for (final entry in durations.entries)
            entry.key: Duration(milliseconds: _px(entry.value).round()),
        },
        {
          'duration-press': InVogueMotion.press,
          'duration-quick': InVogueMotion.quick,
          'duration-base': InVogueMotion.base,
          'duration-sheet': InVogueMotion.sheet,
          'duration-draw': InVogueMotion.draw,
          'duration-reveal': InVogueMotion.reveal,
        },
      );

      Cubic cubic(Object? css) {
        final numbers = RegExp(r'[\d.]+')
            .allMatches(css! as String)
            .map((m) => double.parse(m.group(0)!))
            .toList();
        return Cubic(numbers[0], numbers[1], numbers[2], numbers[3]);
      }

      final easing = values('easing');
      for (final (name, curve) in [
        ('easing-standard', InVogueMotion.standard),
        ('easing-enter', InVogueMotion.enter),
        ('easing-exit', InVogueMotion.exit),
        ('easing-curtain', InVogueMotion.curtain),
      ]) {
        final expected = cubic(easing[name]);
        curve as Cubic;
        expect(
          [curve.a, curve.b, curve.c, curve.d],
          [expected.a, expected.b, expected.c, expected.d],
          reason: name,
        );
      }
    });

    test('page margin narrows below 360 points', () {
      expect(InVogueLayout.pageMarginFor(320), 16);
      expect(InVogueLayout.pageMarginFor(359.9), 16);
      expect(InVogueLayout.pageMarginFor(360), 20);
      expect(InVogueLayout.pageMarginFor(430), 20);
    });

    test('grid spans fill the 350-point content width of a 390 phone', () {
      const content = 390 - 2 * InVogueLayout.pageMargin;
      expect(InVogueLayout.columnSpan(content, 6), closeTo(content, 1e-9));
      // Three tiles in a row span two columns each; two span three.
      expect(
        InVogueLayout.columnSpan(content, 2) * 3 + 2 * 12,
        closeTo(content, 1e-9),
      );
      expect(InVogueLayout.columnSpan(content, 3), closeTo(169, 1e-9));
    });
  });
}
