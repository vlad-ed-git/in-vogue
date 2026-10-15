import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/firebase_options_development.dart' as development;
import 'package:in_vogue/firebase_options_production.dart' as production;

void main() {
  test('generated mobile Firebase options stay isolated by environment', () {
    expect(
      development.DefaultFirebaseOptions.android.projectId,
      'in-vogue-dev',
    );
    expect(development.DefaultFirebaseOptions.ios.projectId, 'in-vogue-dev');
    expect(
      development.DefaultFirebaseOptions.ios.iosBundleId,
      'com.invogue.app.dev',
    );
    expect(production.DefaultFirebaseOptions.android.projectId, 'in-vogue');
    expect(production.DefaultFirebaseOptions.ios.projectId, 'in-vogue');
    expect(
      production.DefaultFirebaseOptions.ios.iosBundleId,
      'com.invogue.app',
    );
    expect(
      development.DefaultFirebaseOptions.android.appId,
      isNot(production.DefaultFirebaseOptions.android.appId),
    );
    expect(
      development.DefaultFirebaseOptions.ios.appId,
      isNot(production.DefaultFirebaseOptions.ios.appId),
    );
  });
}
