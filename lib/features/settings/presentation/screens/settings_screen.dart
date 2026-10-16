import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/auth/presentation/bloc/log_out_bloc.dart';
import 'package:in_vogue/features/preferences/presentation/widgets/language_row.dart';

/// The Settings tab: hairline rows of what the person can change.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.onLoggedOut, super.key});

  /// Called once the person is logged out.
  final VoidCallback onLoggedOut;

  @override
  Widget build(BuildContext context) => BlocListener<LogOutBloc, LogOutState>(
    listenWhen: (previous, current) => previous != current,
    listener: (context, state) {
      if (state.status == LogOutStatus.loggedOut) onLoggedOut();
      if (state.failure != null) {
        context.showSnack(
          message: state.failure!.uiFriendlyMessage(context),
          isError: true,
        );
      }
    },
    child: SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: PageMargin(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: InVogueSpace.s4),
              ScreenTitle(context.translated.tabSettings),
              const SizedBox(height: InVogueSpace.s6),
              SettingsRows(
                children: [
                  const LanguageRow(),
                  BlocBuilder<LogOutBloc, LogOutState>(
                    builder: (context, state) => SettingsRow.logOut(
                      context,
                      state.status == LogOutStatus.idle
                          ? () => context.read<LogOutBloc>().add(
                              const LogOutRequested(),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: InVogueSpace.s10),
            ],
          ),
        ),
      ),
    ),
  );
}
