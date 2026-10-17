import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keys bundled with development builds only: pubspec.yaml bundles
/// assets/development/ for the development flavor alone.
abstract final class DevelopmentKeys {
  /// Written by scripts/write_development_key.py and never committed.
  static const youCamPath = 'assets/development/youcam_api_key.txt';

  /// The YouCam key in [bundle]; null when none is bundled.
  static Future<String?> youCam(AssetBundle bundle) async {
    try {
      final key = (await bundle.loadString(youCamPath, cache: false)).trim();
      return key.isEmpty ? null : key;
    } on FlutterError {
      return null;
    }
  }
}
