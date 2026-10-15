import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/core/persistence/key_value_store.dart';
import 'package:in_vogue/features/preferences/data/data_sources/preferences_local_data_source.dart';
import 'package:in_vogue/features/preferences/data/repositories/preferences_repository_impl.dart';
import 'package:in_vogue/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'preferences_repository_test.mocks.dart';

@GenerateMocks([
  PreferencesLocalDataSource,
  PreferencesRepository,
  KeyValueStore,
  LogMessages,
])
void main() {
  late MockPreferencesLocalDataSource local;
  late MockLogMessages logger;
  late PreferencesRepositoryImpl repository;

  setUp(() {
    local = MockPreferencesLocalDataSource();
    logger = MockLogMessages();
    repository = PreferencesRepositoryImpl(
      localDataSource: local,
      logMessages: logger,
    );
  });

  test('returns the language read from disk', () async {
    when(local.getLanguage()).thenReturn(SupportedLanguages.chinese);
    expect(
      await repository.getLanguage(),
      const Right<Failure, SupportedLanguages>(SupportedLanguages.chinese),
    );
  });

  test('does not report success until the language is saved', () async {
    final saved = Completer<void>();
    when(
      local.setLanguage(SupportedLanguages.spanish),
    ).thenAnswer((_) => saved.future);
    var completed = false;
    final result = repository.setLanguage(SupportedLanguages.spanish).then((
      value,
    ) {
      completed = true;
      return value;
    });
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    saved.complete();
    expect(
      await result,
      const Right<Failure, SupportedLanguages>(SupportedLanguages.spanish),
    );
  });

  test('maps a failed read to a typed failure and logs the cause', () async {
    final error = CacheException(
      Exception('disk unavailable'),
      StackTrace.current,
    );
    when(local.getLanguage()).thenThrow(error);
    expect(
      await repository.getLanguage(),
      const Left<Failure, SupportedLanguages>(CacheFailure()),
    );
    verify(
      logger.logError(
        callerClass: 'PreferencesRepositoryImpl',
        callerMethod: 'getLanguage',
        error: error.cause,
        stackTrace: error.stackTrace,
      ),
    ).called(1);
  });

  test(
    'maps a failed write without pretending the language was saved',
    () async {
      when(
        local.setLanguage(any),
      ).thenThrow(CacheException(Exception('disk full'), StackTrace.current));
      expect(
        await repository.setLanguage(SupportedLanguages.spanish),
        const Left<Failure, SupportedLanguages>(CacheFailure()),
      );
    },
  );

  test(
    'local source defaults to English and stores stable language codes',
    () async {
      final store = MockKeyValueStore();
      when(store.readString(any)).thenReturn(null);
      when(store.writeString(any, any)).thenAnswer((_) async {});
      final source = PreferencesLocalDataSourceImpl(store);
      expect(source.getLanguage(), SupportedLanguages.english);
      await source.setLanguage(SupportedLanguages.chinese);
      verify(store.writeString('language', 'zh')).called(1);
    },
  );
}
