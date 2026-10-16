import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/features/preferences/presentation/bloc/preferences_bloc.dart';

/// Opens a sheet of the languages and saves the one chosen.
Future<void> chooseLanguage(BuildContext context) async {
  final bloc = context.read<PreferencesBloc>();
  final current = bloc.state.language;
  final language = await showInVogueSheet<SupportedLanguages>(
    context: context,
    builder: (context) => InVogueSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InVogueSheetHeader(title: context.translated.language),
          for (final language in SupportedLanguages.values)
            InVogueSheetOption(
              label: language.nativeName,
              selected: language == current,
              onTap: () => Navigator.of(context).pop(language),
            ),
        ],
      ),
    ),
  );
  if (language != null) bloc.add(LanguageChanged(language));
}
