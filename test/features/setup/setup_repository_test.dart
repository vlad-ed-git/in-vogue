import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/core/persistence/key_value_store.dart';
import 'package:in_vogue/features/setup/data/data_sources/setup_local_data_source.dart';
import 'package:in_vogue/features/setup/data/repositories/setup_repository_impl.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/domain/repositories/setup_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'setup_repository_test.mocks.dart';

@GenerateMocks([
  SetupLocalDataSource,
  SetupRepository,
  KeyValueStore,
  LogMessages,
])
void main() {
  group('SetupLocalDataSourceImpl', () {
    late MockKeyValueStore store;
    late SetupLocalDataSourceImpl source;

    setUp(() {
      store = MockKeyValueStore();
      source = SetupLocalDataSourceImpl(store);
    });

    test('starts at welcome when nothing is saved', () {
      when(store.readString('setup_step')).thenReturn(null);
      expect(source.getStep(), SetupStep.welcome);
    });

    test('reads the saved step', () {
      when(store.readString('setup_step')).thenReturn('picks');
      expect(source.getStep(), SetupStep.picks);
    });

    test('starts at welcome when the saved value is unknown', () {
      when(store.readString('setup_step')).thenReturn('closet');
      expect(source.getStep(), SetupStep.welcome);
    });

    test('saves the step by its stable name', () async {
      when(store.writeString(any, any)).thenAnswer((_) async {});
      await source.saveStep(SetupStep.firstOutfit);
      verify(store.writeString('setup_step', 'firstOutfit')).called(1);
    });
  });

  group('SetupRepositoryImpl', () {
    late MockSetupLocalDataSource local;
    late MockLogMessages logger;
    late SetupRepositoryImpl repository;

    setUp(() {
      local = MockSetupLocalDataSource();
      logger = MockLogMessages();
      repository = SetupRepositoryImpl(
        localDataSource: local,
        logMessages: logger,
      );
    });

    test('returns the saved step', () async {
      when(local.getStep()).thenReturn(SetupStep.photo);
      expect(
        await repository.getStep(),
        const Right<Failure, SetupStep>(SetupStep.photo),
      );
    });

    test('maps a failed read to a typed failure and logs the cause', () async {
      final error = CacheException(
        Exception('disk unavailable'),
        StackTrace.current,
      );
      when(local.getStep()).thenThrow(error);
      expect(
        await repository.getStep(),
        const Left<Failure, SetupStep>(CacheFailure()),
      );
      verify(
        logger.logError(
          callerClass: 'SetupRepositoryImpl',
          callerMethod: 'getStep',
          error: error.cause,
          stackTrace: error.stackTrace,
        ),
      ).called(1);
    });

    test('does not report success until the step is saved', () async {
      final saved = Completer<void>();
      when(local.saveStep(SetupStep.picks)).thenAnswer((_) => saved.future);
      var completed = false;
      final result = repository.saveStep(SetupStep.picks).then((value) {
        completed = true;
        return value;
      });
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      saved.complete();
      expect(await result, const Right<Failure, SetupStep>(SetupStep.picks));
    });

    test('maps a failed save to a typed failure and logs the cause', () async {
      final error = CacheException(Exception('disk full'), StackTrace.current);
      when(local.saveStep(any)).thenThrow(error);
      expect(
        await repository.saveStep(SetupStep.done),
        const Left<Failure, SetupStep>(CacheFailure()),
      );
      verify(
        logger.logError(
          callerClass: 'SetupRepositoryImpl',
          callerMethod: 'saveStep',
          error: error.cause,
          stackTrace: error.stackTrace,
        ),
      ).called(1);
    });
  });
}
