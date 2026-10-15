import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/preferences/domain/usecases/set_language.dart';

sealed class PreferencesEvent {
  const PreferencesEvent();
}

final class LanguageChanged extends PreferencesEvent {
  const LanguageChanged(this.language);
  final SupportedLanguages language;
}

class PreferencesState extends Equatable {
  const PreferencesState({
    this.language = SupportedLanguages.english,
    this.isSaving = false,
    this.failure,
  });
  final SupportedLanguages language;
  final bool isSaving;
  final Failure? failure;

  @override
  List<Object?> get props => [language, isSaving, failure];
}

class PreferencesBloc extends Bloc<PreferencesEvent, PreferencesState> {
  PreferencesBloc({
    required SetLanguage setLanguage,
    required SupportedLanguages initialLanguage,
  }) : super(PreferencesState(language: initialLanguage)) {
    on<LanguageChanged>((event, emit) async {
      if (event.language == state.language) return;
      final previous = state.language;
      emit(PreferencesState(language: previous, isSaving: true));
      final result = await setLanguage(event.language);
      result.fold(
        (failure) =>
            emit(PreferencesState(language: previous, failure: failure)),
        (language) => emit(PreferencesState(language: language)),
      );
    }, transformer: sequential());
  }
}
