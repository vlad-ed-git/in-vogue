import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/design_system/design_system.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  Widget preview({
    HomeWidgetSize size = HomeWidgetSize.large,
    ImageProvider? portrait,
    List<ImageProvider> flatLays = const [],
    ImageProvider? waitingPhoto,
    double? width,
    VoidCallback? onTap,
    String condition = 'Showers after 3 pm',
  }) => Align(
    alignment: Alignment.topLeft,
    child: HomeWidgetPreview(
      size: size,
      kicker: 'Tomorrow',
      dateLine: 'Thu 16 Oct · Workday',
      temperature: 54,
      condition: condition,
      feelsLike: 49,
      glyph: WeatherGlyphType.cloudRain,
      portrait: portrait,
      flatLays: flatLays,
      waitingPhoto: waitingPhoto,
      width: width,
      onTap: onTap,
      semanticLabel: 'Tomorrow, 54 degrees, showers after 3 pm.',
    ),
  );

  Rect slab(WidgetTester tester) => tester.getRect(
    find
        .ancestor(of: find.text('TOMORROW'), matching: find.byType(Positioned))
        .first,
  );

  testWidgets('large: a 154-point slab beside a 184-point portrait', (
    tester,
  ) async {
    await pumpInVogue(tester, preview(portrait: testImage));
    expect(
      tester.getSize(find.byType(HomeWidgetPreview)),
      const Size(338, 354),
    );
    expect(slab(tester).width, 154);
    final image = tester.getRect(find.byType(Image));
    expect(image.width, 184);
    expect(image.height, 354);
    expect(find.text('Thu 16 Oct · Workday'), findsOneWidget);
    expect(find.text('Feels like 49°'), findsOneWidget);
    final numeral = tester.widget<TemperatureText>(
      find.byType(TemperatureText),
    );
    expect(numeral.style.fontSize, 150);
    expect(numeral.style.color, InVogueColors.rose);
    expect(
      tester.widget<WeatherGlyph>(find.byType(WeatherGlyph)).still,
      isTrue,
      reason: 'widgets never animate',
    );
  });

  testWidgets('medium and small use their slab and numeral sizes', (
    tester,
  ) async {
    await pumpInVogue(
      tester,
      preview(size: HomeWidgetSize.medium, portrait: testImage),
    );
    expect(
      tester.getSize(find.byType(HomeWidgetPreview)),
      const Size(338, 158),
    );
    expect(slab(tester).width, 206);
    expect(
      tester
          .widget<TemperatureText>(find.byType(TemperatureText))
          .style
          .fontSize,
      118,
    );
    expect(find.text('Feels like 49°'), findsNothing);

    await pumpInVogue(
      tester,
      preview(size: HomeWidgetSize.small, portrait: testImage),
    );
    expect(
      tester.getSize(find.byType(HomeWidgetPreview)),
      const Size(158, 158),
    );
    expect(find.byType(Image), findsNothing, reason: 'weather only');
    expect(find.text('Thu 16 Oct · Workday'), findsNothing);
    expect(
      tester
          .widget<TemperatureText>(find.byType(TemperatureText))
          .style
          .fontSize,
      104,
    );
  });

  testWidgets('privacy mode stacks up to three flat-lays with 2-point seams', (
    tester,
  ) async {
    await pumpInVogue(
      tester,
      preview(flatLays: [testImage, otherTestImage, testImage, otherTestImage]),
    );
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, hasLength(3));
    final first = tester.getRect(find.byType(Image).first);
    final second = tester.getRect(find.byType(Image).at(1));
    expect(second.top - first.bottom, 2);

    await pumpInVogue(
      tester,
      preview(
        size: HomeWidgetSize.medium,
        flatLays: [testImage, otherTestImage],
      ),
    );
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('waiting: the own photo faded behind Getting ready', (
    tester,
  ) async {
    await pumpInVogue(tester, preview(waitingPhoto: testImage));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.28);
    expect(find.text('Getting ready'), findsOneWidget);
  });

  testWidgets('scales uniformly to a width and ignores the text size', (
    tester,
  ) async {
    await pumpInVogue(
      tester,
      preview(portrait: testImage, width: 390),
      textScale: 2,
      scroll: false,
    );
    final size = tester.getSize(find.byType(HomeWidgetPreview));
    expect(size.width, 390);
    expect(size.height, closeTo(354 * 390 / 338, 1e-9));
    final text = tester.widget<Text>(find.text('Feels like 49°'));
    expect(
      MediaQuery.textScalerOf(tester.element(find.byWidget(text))),
      TextScaler.noScaling,
    );
  });

  testWidgets('reads as one label and can be one tap target', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpInVogue(
      tester,
      preview(portrait: testImage, onTap: () => taps++),
    );
    expect(
      find.bySemanticsLabel('Tomorrow, 54 degrees, showers after 3 pm.'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('54 degrees'), findsNothing);
    await tester.tap(find.byType(HomeWidgetPreview));
    expect(taps, 1);
    handle.dispose();
  });
}
