import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

/// The current tab above the tab bar.
class TabShell extends StatelessWidget {
  const TabShell({required this.shell, super.key});

  /// Branches in [InVogueTab] order.
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: CurrentTab(tab: InVogueTab.values[shell.currentIndex], child: shell),
    bottomNavigationBar: InVogueTabBar(
      current: InVogueTab.values[shell.currentIndex],
      onSelected: (tab) => shell.goBranch(
        tab.index,
        initialLocation: tab.index == shell.currentIndex,
      ),
    ),
  );
}

/// The tab on screen, for the tabs beneath it.
class CurrentTab extends InheritedWidget {
  const CurrentTab({required this.tab, required super.child, super.key});

  final InVogueTab tab;

  /// The tab on screen; null outside the tabs.
  static InVogueTab? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CurrentTab>()?.tab;

  @override
  bool updateShouldNotify(CurrentTab oldWidget) => oldWidget.tab != tab;
}
