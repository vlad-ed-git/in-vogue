import 'package:flutter/material.dart';
import 'package:in_vogue/core/ui/theme/app_theme.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';

class StartupFailureApp extends StatefulWidget {
  const StartupFailureApp({required this.onRetry, super.key});
  final Future<void> Function() onRetry;

  @override
  State<StartupFailureApp> createState() => _StartupFailureAppState();
}

class _StartupFailureAppState extends State<StartupFailureApp> {
  bool _retrying = false;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    home: Builder(
      builder: (context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.translated.startupFailure,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _retrying
                        ? null
                        : () async {
                            setState(() => _retrying = true);
                            try {
                              await widget.onRetry();
                            } finally {
                              if (mounted) setState(() => _retrying = false);
                            }
                          },
                    child: Text(context.translated.retry),
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
