import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/presentation/components/weather/weather_glyph.dart';
import 'package:in_vogue/core/presentation/components/weather/weather_glyph_paths.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/home_widget_data_source.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/widget_refresh_scheduler.dart';

const _extension = 'ios/In Vogue Widget';

/// The iPhone widget's native files, read in place of a build.
void main() {
  final swift = Directory(_extension)
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.swift'))
      .map((file) => file.readAsStringSync())
      .join('\n');
  final group = HomeWidgetDataSourceImpl.appGroupOf(
    AppEnvironment.development,
  )!;

  test('the widget reads what the app keeps, in the App Group both targets '
      'share', () {
    expect(swift, contains('"${HomeWidgetDataSourceImpl.iOSKind}"'));
    expect(swift, contains('"${HomeWidgetDataSourceImpl.contentKey}"'));
    expect(swift, contains('"$group"'));
    for (final entitlements in [
      'ios/Runner/Runner.entitlements',
      'ios/In Vogue WidgetExtension.entitlements',
    ]) {
      expect(
        File(entitlements).readAsStringSync(),
        contains('<string>$group</string>'),
        reason: entitlements,
      );
    }
  });

  test('the widget picks the day as Home does, and changes at the same '
      'hours', () {
    expect(swift, contains('(6..<9).contains(hour)'));
    expect(swift, contains('"today"'));
    expect(swift, contains('[0, 6, 9]'));
  });

  test('it comes Small, Medium and Large, from iOS 17', () {
    for (final family in ['.systemSmall', '.systemMedium', '.systemLarge']) {
      expect(swift, contains(family));
    }
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    expect(
      'IPHONEOS_DEPLOYMENT_TARGET = 17.0;'.allMatches(project),
      hasLength(6),
    );
  });

  test('every weather glyph has its image, drawn from the spec', () {
    for (final glyph in WeatherGlyphType.values) {
      final name = 'widget_glyph_${glyph.specName.replaceAll('-', '_')}';
      expect(
        File(
          '$_extension/Assets.xcassets/$name.imageset/$name.svg',
        ).readAsStringSync(),
        contains(weatherStillPaths[glyph.specName]),
        reason: glyph.specName,
      );
    }
    expect(swift, contains('"widget_glyph_"'));
  });

  test('the morning refresh may run in the background: its task is '
      'permitted, and registered at launch with the app\'s plugins', () {
    const task = WorkmanagerWidgetRefreshScheduler.task;
    final info = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      info,
      matches(
        RegExp(
          r'<key>BGTaskSchedulerPermittedIdentifiers</key>\s*<array>\s*'
          '<string>$task</string>',
        ),
      ),
    );
    expect(
      info,
      matches(
        RegExp(r'<key>UIBackgroundModes</key>\s*<array>\s*<string>fetch'),
      ),
    );
    final delegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(delegate, contains('withIdentifier: "$task"'));
    expect(
      delegate,
      contains('GeneratedPluginRegistrant.register(with: registry)'),
    );
  });

  test('the numeral stays on one line and shrinks to fit any width', () {
    final numeral = RegExp(
      r'struct Numeral: View \{[\s\S]*?\n\}',
    ).firstMatch(swift)!.group(0)!;
    expect(numeral, contains('.lineLimit(1)'));
    expect(numeral, contains('.minimumScaleFactor(0.25)'));
  });

  test("the widget sets its type in the app's fonts", () {
    final info = File('$_extension/Info.plist').readAsStringSync();
    for (final (file, postScriptName) in [
      ('SofiaSans-Variable.ttf', 'SofiaSans-Regular'),
      (
        'SofiaSansExtraCondensed-Variable.ttf',
        'SofiaSansExtraCondensed-Regular',
      ),
    ]) {
      expect(info, contains('<string>$file</string>'));
      expect(
        File('$_extension/$file').readAsBytesSync(),
        File('assets/fonts/$file').readAsBytesSync(),
        reason: file,
      );
      expect(swift, contains('"$postScriptName"'));
    }
  });
}
