import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';

/// Turns on App Check, so that once the console enforces it, Firestore and
/// Storage answer only the real app: Play Integrity on Android, App Attest on
/// iPhone (every iOS 15 device has it), and in debug builds a debug token
/// added in the console. Not enforced, it changes nothing; failing to start
/// never stops the app.
Future<void> activateAppCheck({
  FirebaseAppCheck? appCheck,
  bool debug = kDebugMode,
  LogMessages? log,
}) async {
  try {
    await (appCheck ?? FirebaseAppCheck.instance).activate(
      providerAndroid: debug
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: debug
          ? const AppleDebugProvider()
          : const AppleAppAttestProvider(),
    );
  } on Exception catch (error, stack) {
    (log ?? LogMessagesImpl()).logError(
      callerClass: 'AppCheck',
      callerMethod: 'activate',
      error: error,
      stackTrace: stack,
    );
  }
}
