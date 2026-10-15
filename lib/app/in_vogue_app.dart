import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/app/router/app_router.dart';
import 'package:in_vogue/app/router/app_screens.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/localization_ext.dart';
import 'package:in_vogue/features/preferences/presentation/bloc/preferences_bloc.dart';
import 'package:in_vogue/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';

class InVogueApp extends StatefulWidget {
  const InVogueApp({
    required this.createPreferencesBloc,
    required this.createSetupBloc,
    required this.screens,
    super.key,
  });

  final PreferencesBloc Function() createPreferencesBloc;
  final SetupBloc Function() createSetupBloc;
  final AppScreens screens;

  @override
  State<InVogueApp> createState() => _InVogueAppState();
}

class _InVogueAppState extends State<InVogueApp> {
  late final SetupBloc _setup;
  late final AppRouter _router;

  @override
  void initState() {
    super.initState();
    _setup = widget.createSetupBloc();
    _router = AppRouter(setup: _setup, screens: widget.screens);
  }

  @override
  void dispose() {
    _router.dispose();
    unawaited(_setup.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => widget.createPreferencesBloc()),
      BlocProvider.value(value: _setup),
    ],
    child: BlocBuilder<PreferencesBloc, PreferencesState>(
      buildWhen: (previous, current) => previous.language != current.language,
      builder: (context, state) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        locale: state.language.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: InVogueTheme.paper,
        themeMode: ThemeMode.light,
        builder: InVogueTheme.builder,
        routerConfig: _router.config,
      ),
    ),
  );
}
