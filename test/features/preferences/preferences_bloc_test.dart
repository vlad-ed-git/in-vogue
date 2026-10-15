import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/preferences/domain/usecases/set_language.dart';
import 'package:in_vogue/features/preferences/presentation/bloc/preferences_bloc.dart';
import 'package:mockito/mockito.dart';

import 'preferences_repository_test.mocks.dart';

void main() {
  late MockPreferencesRepository repository;
  PreferencesBloc buildBloc() => PreferencesBloc(
    setLanguage: SetLanguage(repository),
    initialLanguage: SupportedLanguages.english,
  );
  setUp(() {
    repository = MockPreferencesRepository();
  });

  blocTest<PreferencesBloc, PreferencesState>(
    'changes language only after a successful save',
    build: () {
      when(
        repository.setLanguage(SupportedLanguages.spanish),
      ).thenAnswer((_) async => const Right(SupportedLanguages.spanish));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LanguageChanged(SupportedLanguages.spanish)),
    expect: () => [
      const PreferencesState(isSaving: true),
      const PreferencesState(language: SupportedLanguages.spanish),
    ],
  );

  blocTest<PreferencesBloc, PreferencesState>(
    'retains the current language and exposes a save failure',
    build: () {
      when(
        repository.setLanguage(any),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LanguageChanged(SupportedLanguages.chinese)),
    expect: () => [
      const PreferencesState(isSaving: true),
      const PreferencesState(failure: CacheFailure()),
    ],
  );

  blocTest<PreferencesBloc, PreferencesState>(
    'does not write the already selected language',
    build: buildBloc,
    act: (bloc) => bloc.add(const LanguageChanged(SupportedLanguages.english)),
    expect: () => <PreferencesState>[],
    verify: (_) => verifyNever(repository.setLanguage(any)),
  );

  test(
    'serializes quick changes so the last choice remains on disk and screen',
    () async {
      final firstSave = Completer<Either<Failure, SupportedLanguages>>();
      when(
        repository.setLanguage(SupportedLanguages.spanish),
      ).thenAnswer((_) => firstSave.future);
      when(
        repository.setLanguage(SupportedLanguages.chinese),
      ).thenAnswer((_) async => const Right(SupportedLanguages.chinese));
      final bloc = buildBloc();
      addTearDown(bloc.close);
      bloc.add(const LanguageChanged(SupportedLanguages.spanish));
      bloc.add(const LanguageChanged(SupportedLanguages.chinese));
      await Future<void>.delayed(Duration.zero);
      verifyNever(repository.setLanguage(SupportedLanguages.chinese));
      final finished = bloc.stream.firstWhere(
        (state) => state.language == SupportedLanguages.chinese,
      );
      firstSave.complete(const Right(SupportedLanguages.spanish));
      await finished.timeout(const Duration(seconds: 2));
      expect(bloc.state.language, SupportedLanguages.chinese);
      verifyInOrder([
        repository.setLanguage(SupportedLanguages.spanish),
        repository.setLanguage(SupportedLanguages.chinese),
      ]);
    },
  );
}
