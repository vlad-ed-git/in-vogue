import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/config/development_keys.dart';

/// Assets by path; any other is missing, as in an app bundle.
class _Bundle extends CachingAssetBundle {
  _Bundle(this.files);
  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final text = files[key];
    if (text == null) throw FlutterError('Unable to load asset: "$key".');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
  }
}

void main() {
  test('reads the YouCam key bundled with a development build', () async {
    expect(
      await DevelopmentKeys.youCam(
        _Bundle({DevelopmentKeys.youCamPath: ' key-1\n'}),
      ),
      'key-1',
    );
  });

  test('has no key when none is bundled, or it is blank', () async {
    expect(await DevelopmentKeys.youCam(_Bundle({})), isNull);
    expect(
      await DevelopmentKeys.youCam(
        _Bundle({DevelopmentKeys.youCamPath: ' \n'}),
      ),
      isNull,
    );
  });

  test('only development builds bundle the key, and git never takes it', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains(
        '    - path: assets/development/\n'
        '      flavors:\n'
        '        - development\n',
      ),
    );
    expect(DevelopmentKeys.youCamPath, startsWith('assets/development/'));
    final ignored = File('.gitignore').readAsLinesSync();
    expect(ignored, contains('assets/development/*'));
    expect(ignored, contains('!assets/development/.gitkeep'));
    expect(File('assets/development/.gitkeep').existsSync(), isTrue);
  });

  test('no launch needs a flag for the key', () {
    expect(
      File('.vscode/launch.json').readAsStringSync(),
      isNot(contains('dart-define')),
    );
  });
}
