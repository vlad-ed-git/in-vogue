import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// In Vogue has one theme, Paper, whatever the phone's appearance. These
/// checks keep the native shells from following the system into dark mode.
void main() {
  test('iOS opts out of dark mode and launches on white', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      plist,
      matches(
        RegExp(r'<key>UIUserInterfaceStyle</key>\s*<string>Light</string>'),
      ),
    );
    expect(
      plist,
      matches(
        RegExp(
          r'<key>UIStatusBarStyle</key>\s*'
          r'<string>UIStatusBarStyleDarkContent</string>',
        ),
      ),
    );
    final launch = File(
      'ios/Runner/Base.lproj/LaunchScreen.storyboard',
    ).readAsStringSync();
    expect(
      launch,
      contains(
        '<color key="backgroundColor" red="1" green="1" blue="1" alpha="1" '
        'colorSpace="custom" customColorSpace="sRGB"/>',
      ),
    );
    expect(launch, isNot(contains('systemBackgroundColor')));
  });

  test('Android has no night resources and launches on paper', () {
    const res = 'android/app/src/main/res';
    final night = Directory(res).listSync().whereType<Directory>().where(
      (dir) => dir.path.split('/').last.contains('night'),
    );
    expect(night, isEmpty);
    expect(
      File('$res/values/colors.xml').readAsStringSync(),
      contains('<color name="paper">#FFFFFF</color>'),
    );
    for (final drawable in [
      '$res/drawable/launch_background.xml',
      '$res/drawable-v21/launch_background.xml',
    ]) {
      expect(
        File(drawable).readAsStringSync(),
        contains('<item android:drawable="@color/paper" />'),
        reason: drawable,
      );
    }
    for (final styles in [
      '$res/values/styles.xml',
      '$res/values-v31/styles.xml',
    ]) {
      final xml = File(styles).readAsStringSync();
      expect(xml, isNot(contains('DayNight')), reason: styles);
      expect(xml, isNot(contains('Theme.Black')), reason: styles);
      expect(
        xml,
        contains('<item name="android:windowBackground">@color/paper</item>'),
        reason: styles,
      );
    }
    expect(
      File('$res/values-v31/styles.xml').readAsStringSync(),
      contains(
        '<item name="android:windowSplashScreenBackground">@color/paper</item>',
      ),
    );
  });

  test('no Flutter code declares a dark theme', () {
    final dart = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in dart) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('darkTheme:')), reason: file.path);
      expect(source, isNot(contains('ThemeMode.dark')), reason: file.path);
      expect(source, isNot(contains('ThemeMode.system')), reason: file.path);
    }
  });
}
