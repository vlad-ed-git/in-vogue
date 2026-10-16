import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/preferences/presentation/bloc/preferences_bloc.dart';
import 'package:in_vogue/features/preferences/presentation/widgets/language_sheet.dart';

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
          onAction: state.isSaving ? null : () => chooseLanguage(context),
        ),
      );
}
