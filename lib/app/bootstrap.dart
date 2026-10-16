import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/app/in_vogue_app.dart';
import 'package:in_vogue/app/router/in_vogue_screens.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/core/ui/screens/startup_failure_screen.dart';
import 'package:in_vogue/features/account/domain/usecases/ensure_account.dart';
import 'package:in_vogue/features/preferences/presentation/bloc/preferences_bloc.dart';
import 'package:in_vogue/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:in_vogue/main_init.dart';

/// Without a [youCamApiKey] the app makes no outfits or makeup.
Future<void> bootstrap({
  required AppEnvironment environment,
  required FirebaseOptions firebaseOptions,
  String? youCamApiKey,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final startup = await MainInit.init(
      environment: environment,
      firebaseOptions: firebaseOptions,
      youCamApiKey: youCamApiKey,
    );
    runApp(
      InVogueApp(
        createPreferencesBloc: () =>
            GetIt.I<PreferencesBloc>(param1: startup.language),
        createSetupBloc: () => GetIt.I<SetupBloc>(param1: startup.setupStep),
        screens: inVogueScreens(GetIt.I),
      ),
    );
    // A session signed in before accounts were saved gets its account now.
    unawaited(GetIt.I<EnsureAccount>()(const NoParams()));
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
          youCamApiKey: youCamApiKey,
        ),
      ),
    );
  }
}
