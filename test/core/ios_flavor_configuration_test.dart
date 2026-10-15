import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/firebase_options_development.dart' as development;
import 'package:in_vogue/firebase_options_production.dart' as production;

typedef _Configuration = ({
  String? baseConfiguration,
  Map<String, String> settings,
});

/// Checks the iOS flavor wiring that otherwise only a slow Xcode build reveals.
void main() {
  final project = File(
    'ios/Runner.xcodeproj/project.pbxproj',
  ).readAsStringSync();
  final runner = _runnerConfigurations(project);
  const modes = ['Debug', 'Profile', 'Release'];

  test('Runner has exactly one configuration per build mode and flavor', () {
    expect(
      runner.keys,
      unorderedEquals([
        for (final environment in AppEnvironment.values)
          for (final mode in modes) '$mode-${environment.name}',
      ]),
    );
  });

  for (final environment in AppEnvironment.values) {
    final flavor = environment.name;
    final (bundleId, displayName) = switch (environment) {
      AppEnvironment.development => (
        development.DefaultFirebaseOptions.ios.iosBundleId,
        'In Vogue Dev',
      ),
      AppEnvironment.production => (
        production.DefaultFirebaseOptions.ios.iosBundleId,
        'In Vogue',
      ),
    };
    for (final mode in modes) {
      final name = '$mode-$flavor';
      test('$name builds the $flavor app from its own xcconfig', () {
        final configuration = runner[name]!;
        expect(configuration.settings['PRODUCT_BUNDLE_IDENTIFIER'], bundleId);
        expect(configuration.settings['FLUTTER_APP_FLAVOR'], flavor);
        expect(configuration.settings['APP_DISPLAY_NAME'], displayName);
        // A target set here would override `-t`, including integration tests.
        expect(configuration.settings, isNot(contains('FLUTTER_TARGET')));
        expect(
          _fileReferencePath(project, configuration.baseConfiguration),
          'Flutter/$name.xcconfig',
        );
      });

      test('$name.xcconfig defaults to main_$flavor.dart and CocoaPods', () {
        final lines = File('ios/Flutter/$name.xcconfig').readAsLinesSync();
        final pods = 'Pods-Runner.${mode.toLowerCase()}-$flavor.xcconfig';
        expect(
          lines,
          contains('#include? "Pods/Target Support Files/Pods-Runner/$pods"'),
        );
        // Generated.xcconfig comes later, so an explicit `-t` still wins.
        expect(
          lines.indexOf('FLUTTER_TARGET=lib/main_$flavor.dart'),
          allOf(
            isNonNegative,
            lessThan(lines.indexOf('#include "Generated.xcconfig"')),
          ),
        );
      });
    }
  }
}

/// App target configurations (those building Runner/Info.plist) by name.
Map<String, _Configuration> _runnerConfigurations(String project) => {
  for (final match in RegExp(
    r'/\* ([\w-]+) \*/ = \{\s*isa = XCBuildConfiguration;(.*?)\n\t\t\};',
    dotAll: true,
  ).allMatches(project))
    if (match[2]!.contains('INFOPLIST_FILE = Runner/Info.plist;'))
      match[1]!: (
        baseConfiguration: RegExp(
          r'baseConfigurationReference = (\w+)',
        ).firstMatch(match[2]!)?[1],
        settings: {
          for (final setting in RegExp(
            r'^\t{4}(\w+) = "?([^";\n]*)"?;$',
            multiLine: true,
          ).allMatches(match[2]!))
            setting[1]!: setting[2]!,
        },
      ),
};

String? _fileReferencePath(String project, String? id) => id == null
    ? null
    : RegExp(
        '$id /\\* [^*]+ \\*/ = \\{isa = PBXFileReference;[^}]*? '
        r'path = "?([^";]+)"?;',
      ).firstMatch(project)?[1];
