import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/app/in_vogue_app.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/ui/screens/startup_failure_screen.dart';
import 'package:in_vogue/features/preferences/presentation/bloc/preferences_bloc.dart';
import 'package:in_vogue/main_init.dart';

Future<void> bootstrap({
  required AppEnvironment environment,
  required FirebaseOptions firebaseOptions,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final language = await MainInit.init(
      environment: environment,
      firebaseOptions: firebaseOptions,
    );
    runApp(
      InVogueApp(
        createPreferencesBloc: () => GetIt.I<PreferencesBloc>(param1: language),
      ),
    );
  } catch (error, stack) {
    LogMessagesImpl().logError(
      callerClass: 'Bootstrap',
      callerMethod: 'initialize',
      error: error,
      stackTrace: stack,
    );
    runApp(
      StartupFailureApp(
        onRetry: () => bootstrap(
          environment: environment,
          firebaseOptions: firebaseOptions,
        ),
      ),
    );
  }
}
