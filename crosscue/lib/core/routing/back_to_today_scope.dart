import 'package:crosscue/core/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wraps a non-Today branch-root screen so the system back button (or the
/// predictive back-swipe gesture) navigates to the Today tab instead of
/// exiting the app.
///
/// Why this lives on the branch-root screen and not on [AppShell]:
/// go_router's `StatefulShellRoute` handles back via its own mechanism that
/// bypasses Flutter's [BackButtonDispatcher], so a [BackButtonListener] at
/// the shell level is never invoked. A [PopScope] inside the branch root
/// registers with the branch navigator's [ModalRoute] — the navigator
/// go_router actually pops — so it cannot be bypassed.
///
/// When a sub-page is pushed within the same branch (e.g. Settings →
/// Sources), the sub-page is on top of the branch navigator stack; this
/// [PopScope] does not fire, and the sub-page pops normally.
class BackToTodayScope extends StatelessWidget {
  const BackToTodayScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(Routes.home);
      },
      child: child,
    );
  }
}
