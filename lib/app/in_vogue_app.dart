import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/design_system/design_system.dart';
import 'package:in_vogue/core/ui/screens/foundation_screen.dart';
import 'package:in_vogue/core/utils/localization_ext.dart';
import 'package:in_vogue/features/preferences/presentation/bloc/preferences_bloc.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';

class InVogueApp extends StatelessWidget {
  const InVogueApp({required this.createPreferencesBloc, super.key});
  final PreferencesBloc Function() createPreferencesBloc;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => createPreferencesBloc(),
    child: BlocBuilder<PreferencesBloc, PreferencesState>(
      buildWhen: (previous, current) => previous.language != current.language,
      builder: (context, state) => MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        locale: state.language.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: InVogueTheme.paper,
        themeMode: ThemeMode.light,
        builder: InVogueTheme.builder,
        home: const FoundationScreen(),
      ),
    ),
  );
}
