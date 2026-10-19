import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  Widget preview({
    ImageProvider? waitingPhoto,
    double? width,
    String condition = 'Showers after 3 pm',
  }) => Align(
    alignment: Alignment.topLeft,
    child: HomeWidgetPreview(
      kicker: 'Tomorrow',
      dateLine: 'Thu 16 Oct · Workday',
      temperature: 54,
      condition: condition,
      feelsLike: 49,
      glyph: WeatherGlyphType.cloudRain,
      waitingPhoto: waitingPhoto,
      width: width,
      semanticLabel: 'Tomorrow, 54 degrees, showers after 3 pm.',
    ),
  );

  Rect slab(WidgetTester tester) => tester.getRect(
    find
        .ancestor(of: find.text('TOMORROW'), matching: find.byType(Positioned))
        .first,
  );

  testWidgets('a 154-point slab beside a 184-point picture', (tester) async {
    await pumpInVogue(tester, preview(waitingPhoto: testImage));
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
    await pumpInVogue(tester, preview(width: 390), textScale: 2, scroll: false);
    final size = tester.getSize(find.byType(HomeWidgetPreview));
    expect(size.width, 390);
    expect(size.height, closeTo(354 * 390 / 338, 1e-9));
    final text = tester.widget<Text>(find.text('Feels like 49°'));
    expect(
      MediaQuery.textScalerOf(tester.element(find.byWidget(text))),
      TextScaler.noScaling,
    );
  });

  testWidgets('reads as one label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpInVogue(tester, preview());
    expect(
      find.bySemanticsLabel('Tomorrow, 54 degrees, showers after 3 pm.'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('54 degrees'), findsNothing);
    handle.dispose();
  });
}
