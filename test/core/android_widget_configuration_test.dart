import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/components/weather/weather_glyph.dart';
import 'package:in_vogue/core/presentation/components/weather/weather_glyph_paths.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/home_widget_data_source.dart';

const _main = 'android/app/src/main';
const _res = '$_main/res';
const _provider = '$_main/kotlin/com/invogue/app/InVogueWidgetProvider.kt';

/// The Android widget's native files, read in place of a build.
void main() {
  final manifest = File('$_main/AndroidManifest.xml').readAsStringSync();
  final provider = File(_provider).readAsStringSync();

  test('the manifest registers the provider the app names, and the receiver '
      'that keeps its scheduled redraws after a restart', () {
    expect(
      HomeWidgetDataSourceImpl.provider,
      'com.invogue.app.InVogueWidgetProvider',
    );
    expect(provider, contains('class InVogueWidgetProvider'));
    expect(manifest, contains('android:name=".InVogueWidgetProvider"'));
    expect(manifest, contains('android:resource="@xml/in_vogue_widget_info"'));
    expect(
      manifest,
      contains('es.antonborri.home_widget.HomeWidgetScheduledUpdateReceiver'),
    );
    expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
  });

  test('the provider reads what the app keeps and picks the day as Home '
      'does', () {
    expect(provider, contains('"${HomeWidgetDataSourceImpl.contentKey}"'));
    expect(provider, contains('hour in 6..8'));
    expect(provider, contains('"today"'));
  });

  test('the widget opens large, resizes down to small, and redraws only '
      'when asked', () {
    final info = File('$_res/xml/in_vogue_widget_info.xml').readAsStringSync();
    expect(info, contains('android:resizeMode="horizontal|vertical"'));
    expect(info, contains('android:updatePeriodMillis="0"'));
    expect(info, contains('android:targetCellWidth="4"'));
    expect(info, contains('android:minResizeWidth="110dp"'));
    for (final layout in ['small', 'medium', 'large', 'empty']) {
      expect(
        File('$_res/layout/in_vogue_widget_$layout.xml').existsSync(),
        isTrue,
        reason: layout,
      );
    }
  });

  test('every weather glyph has its drawable, drawn from the spec', () {
    for (final glyph in WeatherGlyphType.values) {
      final name = 'widget_glyph_${glyph.specName.replaceAll('-', '_')}';
      expect(
        File('$_res/drawable/$name.xml').readAsStringSync(),
        contains(weatherStillPaths[glyph.specName]),
        reason: glyph.specName,
      );
      expect(provider, contains('"${glyph.specName}" -> R.drawable.$name'));
    }
  });

  test('the numeral is a picture in its own font, which shrinks to the room '
      'the widget gives it, so "20°" never shows as "2"', () {
    // The launcher draws a widget's text in the phone's font, wider than ours.
    expect(provider, contains('R.font.sofia_sans_extra_condensed'));
    expect(provider, contains('setImageViewBitmap(R.id.widget_numeral'));
    expect(provider, isNot(contains('setTextViewTextSize')));
    expect(provider, contains('OPTION_APPWIDGET_MIN_WIDTH'));
    for (final size in ['small', 'medium', 'large']) {
      final layout = File(
        '$_res/layout/in_vogue_widget_$size.xml',
      ).readAsStringSync();
      final numeral = RegExp(
        r'<ImageView\s+android:id="@\+id/widget_numeral"[^>]*>',
      ).firstMatch(layout)?.group(0);
      expect(numeral, isNotNull, reason: size);
      expect(numeral, contains('android:layout_width="wrap_content"'));
      expect(numeral, contains('android:layout_height="wrap_content"'));
      expect(numeral, contains('android:adjustViewBounds="true"'));
      // A parent clips what a negative margin pushes outside it.
      expect(numeral, isNot(contains('android:layout_marginStart="-')));
    }
  });

  test("the widget sets its type in the app's fonts", () {
    for (final font in ['sofia_sans', 'sofia_sans_extra_condensed']) {
      expect(File('$_res/font/$font.ttf').existsSync(), isTrue, reason: font);
    }
  });
}
