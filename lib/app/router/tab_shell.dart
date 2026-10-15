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
    body: shell,
    bottomNavigationBar: InVogueTabBar(
      current: InVogueTab.values[shell.currentIndex],
      onSelected: (tab) => shell.goBranch(
        tab.index,
        initialLocation: tab.index == shell.currentIndex,
      ),
    ),
  );
}
