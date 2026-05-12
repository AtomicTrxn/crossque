import 'package:crosscue/core/routing/nav_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Persistent 4-tab shell. Shown for Home, Archive, Stats, and Settings tabs.
/// Full-page routes (Solve, Import, Onboarding) push over this shell.
///
/// Back-button behaviour: each non-Today branch root screen wraps its body
/// with [BackToTodayScope], which intercepts back at the branch navigator
/// level and switches to Today. This is done per-screen (not in the shell)
/// because go_router's `StatefulShellRoute` bypasses Flutter's
/// [BackButtonDispatcher], so neither [BackButtonListener] nor a [PopScope]
/// at the shell level is invoked when the branch navigator has nothing to
/// pop. The branch-root navigator route does receive the pop, so a
/// [PopScope] there fires reliably.
///
/// Crosshare auto-download is triggered by [appLifecycleObserverProvider]
/// (registered in [CrosscueApp.initState]), not from here. Keeping lifecycle
/// observation out of the shell prevents spurious downloads when the app is
/// resumed while a solve is in progress.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: CrosscueNavIcon.home(selected: false),
            selectedIcon: CrosscueNavIcon.home(selected: true),
            label: 'Today',
          ),
          NavigationDestination(
            icon: CrosscueNavIcon.archive(selected: false),
            selectedIcon: CrosscueNavIcon.archive(selected: true),
            label: 'Archive',
          ),
          NavigationDestination(
            icon: CrosscueNavIcon.stats(selected: false),
            selectedIcon: CrosscueNavIcon.stats(selected: true),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: CrosscueNavIcon.settings(selected: false),
            selectedIcon: CrosscueNavIcon.settings(selected: true),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Re-tap on the current tab scrolls to top / pops to root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
