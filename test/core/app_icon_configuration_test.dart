import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Width, height and whether a PNG has an alpha channel, from its header.
({int width, int height, bool alpha}) _png(String path) {
  final bytes = File(path).readAsBytesSync();
  final header = ByteData.sublistView(bytes, 16, 26);
  final colourType = header.getUint8(9);
  return (
    width: header.getUint32(0),
    height: header.getUint32(4),
    alpha: colourType == 4 || colourType == 6,
  );
}

void main() {
  const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  const res = 'android/app/src/main/res';

  test('every iOS icon exists at its pixel size, opaque', () {
    final contents =
        jsonDecode(File('$ios/Contents.json').readAsStringSync())
            as Map<String, dynamic>;
    final images = (contents['images'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(images, hasLength(20));
    for (final image in images) {
      final points = double.parse((image['size'] as String).split('x').first);
      final scale = image['scale'] == null
          ? 1
          : int.parse((image['scale'] as String).replaceAll('x', ''));
      final png = _png('$ios/${image['filename']}');
      expect(png.width, (points * scale).round(), reason: '$image');
      expect(png.height, png.width);
      expect(png.alpha, isFalse, reason: 'App Store icons are opaque');
    }
  });

  test('the Dark appearance uses the same artwork', () {
    final contents =
        jsonDecode(File('$ios/Contents.json').readAsStringSync())
            as Map<String, dynamic>;
    final dark = (contents['images'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((image) => image.containsKey('appearances'))
        .single;
    expect(dark['filename'], 'Icon-App-1024x1024@1x.png');
    expect(dark['appearances'], [
      {'appearance': 'luminosity', 'value': 'dark'},
    ]);
  });

  test('Android has legacy and adaptive icons at every density', () {
    const densities = {
      'mdpi': 1.0,
      'hdpi': 1.5,
      'xhdpi': 2.0,
      'xxhdpi': 3.0,
      'xxxhdpi': 4.0,
    };
    densities.forEach((density, factor) {
      final dir = '$res/mipmap-$density';
      final legacy = _png('$dir/ic_launcher.png');
      expect(legacy.width, (48 * factor).round(), reason: density);
      expect(legacy.alpha, isFalse, reason: density);
      for (final layer in [
        'ic_launcher_foreground',
        'ic_launcher_monochrome',
      ]) {
        final png = _png('$dir/$layer.png');
        expect(png.width, (108 * factor).round(), reason: '$density $layer');
        expect(png.alpha, isTrue, reason: '$density $layer');
      }
    });
    final adaptive = File(
      '$res/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsStringSync();
    expect(adaptive, contains('@color/ic_launcher_background'));
    expect(adaptive, contains('@mipmap/ic_launcher_foreground'));
    expect(adaptive, contains('@mipmap/ic_launcher_monochrome'));
    expect(
      File('$res/values/colors.xml').readAsStringSync(),
      contains('<color name="ic_launcher_background">#FFFFFF</color>'),
    );
    expect(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
      contains('android:icon="@mipmap/ic_launcher"'),
    );
  });

  test('full-size icons are the logo files, byte for byte', () {
    const logo = '../design-spec/assets/logo';
    if (!Directory(logo).existsSync()) return markTestSkipped('spec absent');
    for (final (copy, source) in [
      ('$ios/Icon-App-1024x1024@1x.png', '$logo/app-icon.png'),
      (
        '$res/mipmap-xxxhdpi/ic_launcher_foreground.png',
        '$logo/app-icon-android-foreground.png',
      ),
      (
        '$res/mipmap-xxxhdpi/ic_launcher_monochrome.png',
        '$logo/app-icon-android-monochrome.png',
      ),
    ]) {
      expect(
        File(copy).readAsBytesSync(),
        File(source).readAsBytesSync(),
        reason: copy,
      );
    }
  });
}
