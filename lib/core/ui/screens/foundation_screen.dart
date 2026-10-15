import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/preferences/presentation/bloc/preferences_bloc.dart';

/// Starter surface for the foundation; onboarding is the next product slice.
class FoundationScreen extends StatelessWidget {
  const FoundationScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<PreferencesBloc, PreferencesState>(
        listenWhen: (previous, current) =>
            current.failure != null && previous != current,
        listener: (context, state) => context.showSnack(
          message: state.failure!.uiFriendlyMessage(context),
          isError: true,
        ),
        builder: (context, state) => Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.translated.appName,
                        style: context.txtTheme.displaySmall,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.translated.tagline,
                        style: context.txtTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.translated.welcomeDescription,
                        style: context.txtTheme.bodyLarge?.copyWith(
                          color: context.color.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 48),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: context.translated.language,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<SupportedLanguages>(
                            value: state.language,
                            isExpanded: true,
                            items: [
                              for (final language in SupportedLanguages.values)
                                DropdownMenuItem(
                                  value: language,
                                  child: Text(language.nativeName),
                                ),
                            ],
                            onChanged: state.isSaving
                                ? null
                                : (language) {
                                    if (language != null) {
                                      context.read<PreferencesBloc>().add(
                                        LanguageChanged(language),
                                      );
                                    }
                                  },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
