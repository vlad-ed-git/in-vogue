import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

import '../../../helpers/pump_in_vogue.dart';

/// An image that never finishes loading.
class _PendingImage extends ImageProvider<_PendingImage> {
  const _PendingImage();

  @override
  Future<_PendingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_PendingImage key, ImageDecoderCallback _) =>
      OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
}

void main() {
  Finder rule({Color? color}) => color == null
      ? find.byType(RunningRule)
      : find.byWidgetPredicate(
          (widget) => widget is RunningRule && widget.color == color,
        );

  group('InVogueButton', () {
    testWidgets('busy, it keeps its fill, runs a white rule and ignores '
        'taps', (tester) async {
      var taps = 0;
      await pumpInVogue(
        tester,
        InVogueButton.primary(label: 'Go', onPressed: () => taps++, busy: true),
      );
      expect(rule(color: InVogueColors.onSignal), findsOneWidget);
      final fill = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect((fill.decoration! as BoxDecoration).color, InVogueColors.signal);
      await tester.tap(find.text('Go'));
      expect(taps, 0);
      expect(
        tester.getSemantics(find.byType(InVogueButton)),
        isSemantics(label: 'Go', value: 'Loading', isEnabled: false),
      );
    });

    testWidgets('a Rose button runs an ink rule', (tester) async {
      await pumpInVogue(
        tester,
        InVogueButton.secondary(label: 'Go', onPressed: () {}, busy: true),
      );
      expect(rule(color: InVogueColors.ink), findsOneWidget);
    });

    testWidgets('not busy, there is no rule', (tester) async {
      await pumpInVogue(
        tester,
        InVogueButton.primary(label: 'Go', onPressed: () {}),
      );
      expect(rule(), findsNothing);
    });
  });

  group('SignInButtons', () {
    testWidgets('the provider signing in runs its rule and keeps its fill; '
        'the other is off', (tester) async {
      await pumpInVogue(
        tester,
        SignInButtons(
          onApple: () {},
          onGoogle: () {},
          busy: SignInProvider.apple,
        ),
        platform: TargetPlatform.iOS,
      );
      final apple = find.widgetWithText(SignInButton, 'Sign in with Apple');
      final google = find.widgetWithText(SignInButton, 'Sign in with Google');
      expect(
        find.descendant(
          of: apple,
          matching: rule(color: InVogueColors.paper),
        ),
        findsOneWidget,
      );
      expect(find.descendant(of: google, matching: rule()), findsNothing);
      Color fillOfButton(Finder button) => tester
          .widget<ColoredBox>(
            find
                .descendant(of: button, matching: find.byType(ColoredBox))
                .first,
          )
          .color;
      expect(fillOfButton(apple), InVogueColors.ink);
      expect(fillOfButton(google), InVogueColors.studio);
    });

    testWidgets('Google signing in runs an ink rule', (tester) async {
      await pumpInVogue(
        tester,
        SignInButtons(
          onApple: () {},
          onGoogle: () {},
          busy: SignInProvider.google,
        ),
        platform: TargetPlatform.android,
      );
      expect(rule(color: InVogueColors.ink), findsOneWidget);
    });
  });

  group('TextLink', () {
    testWidgets('busy, the rule runs in place of the underline and taps do '
        'nothing', (tester) async {
      var taps = 0;
      await pumpInVogue(
        tester,
        TextLink(label: 'Replace', onTap: () => taps++, busy: true),
      );
      expect(rule(color: InVogueColors.ink), findsOneWidget);
      expect(
        tester.widget<MarkedText>(find.byType(MarkedText)).underline,
        false,
      );
      await tester.tap(find.byType(TextLink));
      expect(taps, 0);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Replace')),
        isSemantics(label: 'Replace', value: 'Loading'),
      );
    });
  });

  group('SettingsRow', () {
    testWidgets('a busy action runs its link\'s rule', (tester) async {
      var taps = 0;
      await pumpInVogue(
        tester,
        SettingsRow(
          title: 'Body photo',
          action: 'Replace',
          onAction: () => taps++,
          busy: true,
        ),
      );
      expect(
        find.descendant(of: find.byType(TextLink), matching: rule()),
        findsOneWidget,
      );
      await tester.tap(find.byType(TextLink));
      expect(taps, 0);
    });

    testWidgets('a busy command runs a Rouge rule under its title', (
      tester,
    ) async {
      var taps = 0;
      await pumpInVogue(
        tester,
        Builder(
          builder: (context) =>
              SettingsRow.logOut(context, () => taps++, busy: true),
        ),
      );
      expect(rule(color: InVogueColors.signal), findsOneWidget);
      await tester.tap(find.text('Log out'));
      expect(taps, 0);
    });
  });

  group('Notice', () {
    testWidgets('busy, a rule runs along its bottom edge', (tester) async {
      await pumpInVogue(
        tester,
        const Notice(icon: InVogueIcons.image, message: 'Soon', busy: true),
      );
      expect(rule(color: InVogueColors.ink), findsOneWidget);
      expect(
        tester.getBottomLeft(find.byType(RunningRule)),
        tester.getBottomLeft(find.byType(Notice)),
      );
    });
  });

  group('PhotoStage', () {
    testWidgets('waiting, the rule runs along the bottom of the message', (
      tester,
    ) async {
      await pumpInVogue(
        tester,
        PhotoStage(
          state: PhotoStageState.waiting,
          height: 400,
          photo: testImage,
          progress: 'Piece 1 of 3',
        ),
      );
      final message = find.ancestor(
        of: find.text('Getting your outfit ready…'),
        matching: find.byType(DecoratedBox),
      );
      expect(
        find.descendant(of: message.first, matching: rule()),
        findsOneWidget,
      );
    });

    testWidgets('looking, a rule runs along the bottom of the faded photo, '
        'with no words', (tester) async {
      await pumpInVogue(
        tester,
        PhotoStage(
          state: PhotoStageState.looking,
          height: 400,
          photo: testImage,
        ),
      );
      expect(find.text('Getting your outfit ready…'), findsNothing);
      expect(rule(color: InVogueColors.ink), findsOneWidget);
      final stage = tester.getRect(find.byType(PhotoStage));
      expect(tester.getRect(find.byType(RunningRule)).bottom, stage.bottom);
      expect(tester.getSize(find.byType(RunningRule)).width, stage.width);
    });

    testWidgets('idle, nothing runs', (tester) async {
      await pumpInVogue(
        tester,
        PhotoStage(state: PhotoStageState.idle, height: 400, photo: testImage),
      );
      expect(rule(), findsNothing);
    });
  });

  group('MakeupStep', () {
    testWidgets('the step being made runs a rule under its square', (
      tester,
    ) async {
      await pumpInVogue(
        tester,
        const MakeupStep(number: 2, title: 'Brows', working: true),
      );
      expect(rule(color: InVogueColors.ink), findsOneWidget);
      expect(
        tester.getSize(find.byType(RunningRule)).width,
        MakeupStep.pictureSize,
      );
    });

    testWidgets('a step waiting its turn stays still', (tester) async {
      await pumpInVogue(tester, const MakeupStep(number: 3, title: 'Mascara'));
      expect(rule(), findsNothing);
    });
  });

  group('PhotoSlot', () {
    testWidgets('a photo still loading runs a rule along the bottom', (
      tester,
    ) async {
      await pumpInVogue(
        tester,
        const SizedBox(
          width: 160,
          child: PhotoSlot(image: _PendingImage(), showLoading: true),
        ),
      );
      await tester.pump();
      expect(rule(color: InVogueColors.ink), findsOneWidget);
    });

    testWidgets('a slot without a photo stays still', (tester) async {
      await pumpInVogue(tester, const SizedBox(width: 160, child: PhotoSlot()));
      expect(rule(), findsNothing);
    });
  });
}
