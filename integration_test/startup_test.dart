import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/app/in_vogue_app.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/persistence/key_value_store.dart';
import 'package:in_vogue/core/persistence/sqlite_cache.dart';
import 'package:in_vogue/features/preferences/domain/usecases/set_language.dart';
import 'package:in_vogue/features/preferences/presentation/bloc/preferences_bloc.dart';
import 'package:in_vogue/firebase_options_development.dart' as development;
import 'package:in_vogue/firebase_options_production.dart' as production;
import 'package:in_vogue/main_init.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native Firebase and storage initialize, and language survives restart',
    (tester) async {
      final environment = AppEnvironment.values.byName(appFlavor!);
      final options = environment == AppEnvironment.development
          ? development.DefaultFirebaseOptions.currentPlatform
          : production.DefaultFirebaseOptions.currentPlatform;
      final testErrorHandler = FlutterError.onError;
      Future<SupportedLanguages> initialize() async {
        try {
          return await MainInit.init(
            environment: environment,
            firebaseOptions: options,
          );
        } finally {
          // The test binding must retain ownership of framework error reporting.
          FlutterError.onError = testErrorHandler;
        }
      }

      await initialize();
      expect(Firebase.app().options.projectId, environment.firebaseProjectId);
      await GetIt.I<SetLanguage>()(SupportedLanguages.spanish);
      final expiresAt = DateTime.now().add(const Duration(hours: 1));
      await GetIt.I<SqliteCache>().write(
        'smoke',
        'persisted',
        expiresAt: expiresAt,
      );
      await GetIt.I.reset();

      final restored = await initialize();
      expect(restored, SupportedLanguages.spanish);
      expect(
        await GetIt.I<SqliteCache>().read('smoke', now: DateTime.now()),
        'persisted',
      );
      await tester.pumpWidget(
        InVogueApp(
          createPreferencesBloc: () =>
              GetIt.I<PreferencesBloc>(param1: restored),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Viste con estilo para el tiempo de mañana.'),
        findsOneWidget,
      );
      await tester.tap(find.byType(DropdownButton<SupportedLanguages>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('中文').last);
      await tester.pumpAndSettle();
      expect(find.text('以时尚穿搭，迎接明天的天气。'), findsOneWidget);
      expect(GetIt.I<KeyValueStore>().readString('language'), 'zh');

      // Leave a useful default on this dedicated simulator/test installation.
      await GetIt.I<SetLanguage>()(SupportedLanguages.english);
      await GetIt.I<SqliteCache>().clear();
      await tester.pumpWidget(const SizedBox.shrink());
      await GetIt.I.reset();
    },
  );
}
