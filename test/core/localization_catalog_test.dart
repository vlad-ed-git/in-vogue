import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Spanish and Chinese provide every English message without empty values',
    () {
      Map<String, dynamic> catalog(String locale) =>
          jsonDecode(File('lib/l10n/arb/app_$locale.arb').readAsStringSync())
              as Map<String, dynamic>;
      final english = catalog('en');
      final keys = english.keys.where((key) => !key.startsWith('@')).toSet();
      for (final locale in ['es', 'zh']) {
        final translated = catalog(locale);
        expect(
          translated.keys.where((key) => !key.startsWith('@')).toSet(),
          keys,
        );
        for (final key in keys) {
          expect(
            translated[key],
            isA<String>().having((value) => value.trim(), 'text', isNotEmpty),
          );
        }
      }
    },
  );
}
