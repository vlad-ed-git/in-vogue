import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/config/app_check.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'app_check_test.mocks.dart';

@GenerateMocks([FirebaseAppCheck, LogMessages])
void main() {
  late MockFirebaseAppCheck appCheck;
  late MockLogMessages log;

  Future<void> activate() => appCheck.activate(
    providerAndroid: anyNamed('providerAndroid'),
    providerApple: anyNamed('providerApple'),
  );

  setUp(() {
    appCheck = MockFirebaseAppCheck();
    log = MockLogMessages();
    when(activate()).thenAnswer((_) async {});
  });

  test('a debug build proves itself with a debug token', () async {
    await activateAppCheck(appCheck: appCheck, debug: true, log: log);
    verify(
      appCheck.activate(
        providerAndroid: argThat(
          isA<AndroidDebugProvider>(),
          named: 'providerAndroid',
        ),
        providerApple: argThat(
          isA<AppleDebugProvider>(),
          named: 'providerApple',
        ),
      ),
    );
  });

  test(
    'a real build proves itself with Play Integrity and App Attest',
    () async {
      await activateAppCheck(appCheck: appCheck, debug: false, log: log);
      verify(
        appCheck.activate(
          providerAndroid: argThat(
            isA<AndroidPlayIntegrityProvider>(),
            named: 'providerAndroid',
          ),
          providerApple: argThat(
            isA<AppleAppAttestProvider>(),
            named: 'providerApple',
          ),
        ),
      );
    },
  );

  test('failing to start is logged and never stops the app', () async {
    when(
      activate(),
    ).thenAnswer((_) async => throw PlatformException(code: 'unavailable'));
    await activateAppCheck(appCheck: appCheck, debug: false, log: log);
    verify(
      log.logError(
        callerClass: 'AppCheck',
        callerMethod: 'activate',
        error: argThat(isA<PlatformException>(), named: 'error'),
        stackTrace: anyNamed('stackTrace'),
      ),
    );
  });
}
