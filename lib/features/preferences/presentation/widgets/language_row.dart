import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/preferences/presentation/bloc/preferences_bloc.dart';

/// The Language settings row; Change opens a sheet of the languages.
class LanguageRow extends StatelessWidget {
  const LanguageRow({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<PreferencesBloc, PreferencesState>(
        listenWhen: (previous, current) =>
            current.failure != null && previous != current,
        listener: (context, state) => context.showSnack(
          message: state.failure!.uiFriendlyMessage(context),
          isError: true,
        ),
        builder: (context, state) => SettingsRow(
          title: context.translated.language,
          value: state.language.nativeName,
          action: context.translated.change,
          onAction: state.isSaving
              ? null
              : () => _chooseLanguage(context, state.language),
        ),
      );

  Future<void> _chooseLanguage(
    BuildContext context,
    SupportedLanguages current,
  ) async {
    final bloc = context.read<PreferencesBloc>();
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
}
