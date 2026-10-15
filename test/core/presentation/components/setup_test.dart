import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  group('PhotoPicker', () {
    testWidgets('before choosing: example, checklist, Choose from Gallery', (
      tester,
    ) async {
      var chose = 0;
      await pumpInVogue(
        tester,
        PhotoPicker(
          kind: PhotoKind.body,
          example: testImage,
          onChoose: () => chose++,
        ),
      );
      expect(find.text('EXAMPLE'), findsOneWidget);
      for (final item in [
        'Head to toe',
        'Standing, facing forward',
        'Good light',
        'Just you',
      ]) {
        expect(find.text(item), findsOneWidget);
      }
      expect(findIcon(InVogueIcons.check), findsNWidgets(4));
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(findIcon(InVogueIcons.image), findsOneWidget);
      expect(
        find.text(
          'Your photo is only used to dress you in outfits. '
          'You can replace it any time.',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('^Example: a woman')),
        findsOneWidget,
      );
      await tester.tap(find.text('Choose from Gallery'));
      expect(chose, 1);
    });

    testWidgets('says Photos on iOS', (tester) async {
      await pumpInVogue(
        tester,
        PhotoPicker(kind: PhotoKind.body, example: testImage, onChoose: () {}),
        platform: TargetPlatform.iOS,
      );
      expect(find.text('Choose from Photos'), findsOneWidget);
    });

    testWidgets('lays out the photo and checklist in two halves', (
      tester,
    ) async {
      await pumpInVogue(
        tester,
        PhotoPicker(kind: PhotoKind.body, example: testImage, onChoose: () {}),
      );
      final photo = tester.getRect(find.byType(PhotoSlot));
      expect(photo.width, (350 - 12) / 2);
      final row = tester.getRect(
        find
            .ancestor(
              of: find.text('Just you'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(row.left - photo.right, 12);
      expect(row.height, 44);
      expect(
        tester
            .getRect(
              find
                  .ancestor(
                    of: find.text('Head to toe'),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .top,
        photo.top,
      );
      final button = tester.getRect(find.byType(InVogueButton));
      final caption = tester.getRect(find.text('EXAMPLE'));
      expect(button.top - caption.bottom, 24);
    });

    testWidgets('a passing photo: check badge, Continue and choose again', (
      tester,
    ) async {
      var next = 0;
      var chose = 0;
      await pumpInVogue(
        tester,
        PhotoPicker(
          kind: PhotoKind.body,
          example: testImage,
          chosen: testImage,
          onChoose: () => chose++,
          onContinue: () => next++,
        ),
      );
      expect(find.text('YOUR PHOTO'), findsOneWidget);
      expect(find.byType(CheckBadge), findsOneWidget);
      expect(find.textContaining('only used to dress'), findsNothing);
      await tester.tap(find.text('Continue'));
      await tester.tap(findLink('Choose a different photo'));
      expect((next, chose), (1, 1));
    });

    testWidgets('a rejected photo explains why and offers another', (
      tester,
    ) async {
      var chose = 0;
      await pumpInVogue(
        tester,
        PhotoPicker(
          kind: PhotoKind.body,
          example: testImage,
          chosen: testImage,
          check: PhotoCheck.notFullLength,
          onChoose: () => chose++,
        ),
      );
      expect(find.byType(Notice), findsOneWidget);
      expect(find.text('Head to toe'), findsNothing);
      expect(find.byType(CheckBadge), findsNothing);
      await tester.tap(find.text('Choose another photo'));
      expect(chose, 1);
    });

    testWidgets('a face photo has its own checklist and no privacy line', (
      tester,
    ) async {
      await pumpInVogue(
        tester,
        PhotoPicker(kind: PhotoKind.face, example: testImage, onChoose: () {}),
      );
      for (final item in [
        'Close up',
        'Facing forward',
        'Daylight',
        'Hair off your face',
      ]) {
        expect(find.text(item), findsOneWidget);
      }
      expect(find.textContaining('only used to dress'), findsNothing);
    });

    testWidgets('fits a small phone at 200% text in Spanish', (tester) async {
      await pumpInVogue(
        tester,
        PhotoPicker(kind: PhotoKind.body, example: testImage, onChoose: () {}),
        size: const Size(320, 568),
        textScale: 2,
        locale: const Locale('es'),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Elegir de la Galería'), findsOneWidget);
    });
  });

  group('InVogueTextField', () {
    late TextEditingController controller;

    setUp(() => controller = TextEditingController(text: 'Maya'));
    tearDown(() => controller.dispose());

    BoxBorder edge(WidgetTester tester) =>
        (tester
                    .widget<DecoratedBox>(
                      find.descendant(
                        of: find.byType(InVogueTextField),
                        matching: find.byWidgetPredicate(
                          (w) =>
                              w is DecoratedBox &&
                              w.position == DecorationPosition.foreground,
                        ),
                      ),
                    )
                    .decoration
                as BoxDecoration)
            .border!;

    testWidgets('a capital label over a 52-point square field', (tester) async {
      await pumpInVogue(
        tester,
        InVogueTextField(label: 'Your name', controller: controller),
      );
      expect(find.text('YOUR NAME'), findsOneWidget);
      expect(edge(tester), Border.all(color: InVogueColors.line));
      final label = tester.getRect(find.text('YOUR NAME'));
      final box = tester.getRect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox && w.position == DecorationPosition.foreground,
        ),
      );
      expect(box.top - label.bottom, 8);
      expect(box.height, 52);
      expect(tester.getTopLeft(find.byType(TextField)).dx - box.left, 16);
      expect(
        tester.widget<TextField>(find.byType(TextField)).style,
        InVogueType.bodyStrong,
      );
    });

    testWidgets('focus draws a 2-point ink edge', (tester) async {
      await pumpInVogue(
        tester,
        InVogueTextField(label: 'Your name', controller: controller),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(edge(tester), Border.all(color: InVogueColors.ink, width: 2));
    });

    testWidgets('an error sits below with a warning icon, in ink', (
      tester,
    ) async {
      await pumpInVogue(
        tester,
        InVogueTextField(
          label: 'Your name',
          controller: controller,
          error: 'Add the name you’d like us to use.',
        ),
      );
      final error = tester.widget<Text>(
        find.text('Add the name you’d like us to use.'),
      );
      expect(error.style!.color, InVogueColors.ink);
      expect(
        tester.widget<InVogueIcon>(findIcon(InVogueIcons.warning)).size,
        20,
      );
    });

    testWidgets('the label names the field for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInVogue(
        tester,
        InVogueTextField(label: 'Your name', controller: controller),
      );
      final node = tester.getSemantics(find.byType(TextField));
      expect(node.label, contains('Your name'));
      expect(node.flagsCollection.isTextField, isTrue);
      handle.dispose();
    });

    testWidgets('submitting calls back with the text', (tester) async {
      String? submitted;
      await pumpInVogue(
        tester,
        InVogueTextField(
          label: 'Your name',
          controller: controller,
          onSubmitted: (v) => submitted = v,
        ),
      );
      await tester.enterText(find.byType(TextField), 'Ana');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submitted, 'Ana');
    });
  });

  group('SignInButtons', () {
    const apple = ColoredBox(color: Color(0xFF000000), child: Text('Apple'));
    const google = ColoredBox(color: Color(0xFFFFFFFF), child: Text('Google'));

    testWidgets('Apple first on iOS, 52 tall, 12 apart', (tester) async {
      await pumpInVogue(
        tester,
        const SignInButtons(apple: apple, google: google),
        platform: TargetPlatform.iOS,
      );
      final a = tester.getRect(find.text('Apple'));
      final g = tester.getRect(find.text('Google'));
      expect(a.top, lessThan(g.top));
      final boxes = tester
          .widgetList<SizedBox>(
            find.descendant(
              of: find.byType(SignInButtons),
              matching: find.byType(SizedBox),
            ),
          )
          .where((b) => b.height == 52);
      expect(boxes, hasLength(2));
      expect(
        tester.getTopLeft(find.byWidget(google)).dy -
            tester.getBottomLeft(find.byWidget(apple)).dy,
        12,
      );
    });

    testWidgets('Google first on Android', (tester) async {
      await pumpInVogue(
        tester,
        const SignInButtons(apple: apple, google: google),
        platform: TargetPlatform.android,
      );
      expect(
        tester.getRect(find.text('Google')).top,
        lessThan(tester.getRect(find.text('Apple')).top),
      );
    });
  });

  group('WidgetSteps', () {
    testWidgets('three numbered hairline rows with their pictograms', (
      tester,
    ) async {
      await pumpInVogue(tester, const WidgetSteps());
      for (final (number, text, icon) in [
        ('1', 'Press and hold your home screen', InVogueIcons.handTap),
        ('2', 'Tap +', InVogueIcons.plus),
        ('3', 'Choose In Vogue', InVogueIcons.squaresFour),
      ]) {
        expect(find.text(number), findsOneWidget);
        expect(find.text(text), findsOneWidget);
        expect(findIcon(icon), findsOneWidget);
      }
      expect(
        tester.widget<Text>(find.text('1')).style,
        InVogueType.numeralSmall,
      );
      final number = tester.getRect(find.text('1'));
      final text = tester.getRect(find.text('Press and hold your home screen'));
      expect(text.left - number.left, 40 + 12);
    });
  });
}
