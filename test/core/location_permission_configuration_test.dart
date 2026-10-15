import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// In Vogue needs only a coarse location, while it is open, for the weather.
void main() {
  test('Android asks only for coarse location', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(
      manifest,
      contains(
        '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>',
      ),
    );
    expect(manifest, isNot(contains('ACCESS_FINE_LOCATION')));
    expect(manifest, isNot(contains('ACCESS_BACKGROUND_LOCATION')));
  });

  test('iOS explains the weather use and defaults to approximate location', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      plist,
      matches(
        RegExp(
          r'<key>NSLocationWhenInUseUsageDescription</key>\s*'
          r'<string>In Vogue uses your location to find your weather\.</string>',
        ),
      ),
    );
    expect(
      plist,
      matches(RegExp(r'<key>NSLocationDefaultAccuracyReduced</key>\s*<true/>')),
    );
    expect(plist, isNot(contains('NSLocationAlways')));
  });
}
