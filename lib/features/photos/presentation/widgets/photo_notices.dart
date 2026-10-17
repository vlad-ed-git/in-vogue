import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';

/// What is said under a photo of the person: that its format was changed
/// so it works, and why a photo could not be used.
class PhotoNotices extends StatelessWidget {
  const PhotoNotices(this.state, {super.key});

  final PhotoState state;

  @override
  Widget build(BuildContext context) {
    final failure = state.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.converted && state.path != null)
          Padding(
            padding: const EdgeInsets.only(top: InVogueSpace.s4),
            child: Notice(
              icon: InVogueIcons.image,
              message: context.translated.photoConverted,
            ),
          ),
        if (failure != null)
          Padding(
            padding: const EdgeInsets.only(top: InVogueSpace.s4),
            child: Notice(
              icon: InVogueIcons.warning,
              alert: true,
              message: failure.uiFriendlyMessage(context),
            ),
          ),
      ],
    );
  }
}
