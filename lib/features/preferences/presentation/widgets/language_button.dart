import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/preferences/presentation/bloc/preferences_bloc.dart';
import 'package:in_vogue/features/preferences/presentation/widgets/language_sheet.dart';

/// A graphite language icon in a square tap target; opens the language
/// sheet and says when a choice cannot be saved.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  static const double iconSize = 24;

  @override
  Widget build(BuildContext context) {
    final saving = context.select<PreferencesBloc, bool>(
      (bloc) => bloc.state.isSaving,
    );
    return BlocListener<PreferencesBloc, PreferencesState>(
      listenWhen: (previous, current) =>
          current.failure != null && previous != current,
      listener: (context, state) => context.showSnack(
        message: state.failure!.uiFriendlyMessage(context),
        isError: true,
      ),
      child: Pressable(
        onTap: saving ? null : () => chooseLanguage(context),
        semanticLabel: context.translated.language,
        excludeSemantics: true,
        expandTapTarget: false,
        builder: (context, state) => SizedBox.square(
          dimension: context.minTapTarget,
          child: const Center(
            child: Icon(
              InVogueIcons.language,
              size: iconSize,
              color: InVogueColors.graphite,
            ),
          ),
        ),
      ),
    );
  }
}
