import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:in_vogue/app/router/app_routes.dart';
import 'package:in_vogue/app/router/app_screens.dart';
import 'package:in_vogue/app/router/tab_shell.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/presentation/bloc/setup_bloc.dart';

/// The app's routes: setup until it is done, then the three tabs.
///
/// Opens on the saved setup step and saves every setup screen the person
/// reaches, forward or back. Finishing setup moves to Home.
class AppRouter {
  AppRouter({required SetupBloc setup, required AppScreens screens})
    : _setup = setup,
      _refresh = _StreamListenable(setup.stream) {
    config = GoRouter(
      initialLocation: AppRoutes.forStep(setup.state.step),
      refreshListenable: _refresh,
      redirect: _redirect,
      onException: (context, state, router) =>
          router.go(AppRoutes.forStep(_setup.state.step)),
      routes: [
        _setupRoute(AppRoutes.setupSteps.toList(), screens, root: true),
        StatefulShellRoute.indexedStack(
          pageBuilder: (context, state, shell) =>
              _page(state, screens.tabs(TabShell(shell: shell))),
          branches: [
            for (final tab in InVogueTab.values)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.forTab(tab),
                    pageBuilder: (context, state) =>
                        _page(state, screens.tab(tab)),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    config.routerDelegate.addListener(_saveStep);
  }

  final SetupBloc _setup;
  final _StreamListenable _refresh;
  late final GoRouter config;

  /// The first of [steps], with the rest nested in it.
  static GoRoute _setupRoute(
    List<SetupStep> steps,
    AppScreens screens, {
    bool root = false,
  }) {
    final step = steps.first;
    final segment = AppRoutes.segment(step);
    return GoRoute(
      path: root ? '/$segment' : segment,
      pageBuilder: (context, state) => _page(state, screens.setup(step)),
      routes: [if (steps.length > 1) _setupRoute(steps.sublist(1), screens)],
    );
  }

  /// Pages from Flutter's material library, which the app's theme styles.
  static Page<void> _page(GoRouterState state, Widget child) =>
      MaterialPage<void>(key: state.pageKey, name: state.name, child: child);

  String? _redirect(BuildContext context, GoRouterState state) {
    final inSetup = AppRoutes.isSetup(state.matchedLocation);
    final finished = _setup.state.isFinished;
    if (finished && inSetup) return AppRoutes.home;
    if (!finished && !inSetup) return AppRoutes.forStep(_setup.state.step);
    return null;
  }

  void _saveStep() {
    final path = config.routerDelegate.currentConfiguration.uri.path;
    final step = AppRoutes.stepAt(path);
    if (step != null) _setup.add(SetupStepReached(step));
  }

  void dispose() {
    config.routerDelegate.removeListener(_saveStep);
    config.dispose();
    _refresh.dispose();
  }
}

/// Notifies its listeners of every event on a stream.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
