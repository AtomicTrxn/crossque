# Research Topic #13 — Screen Inventory & Navigation Routes

Status: Resolved
Implementation Status: ✅ Implemented — Sprint 1; superseded by ARCHITECTURE.md (canonical reference going forward)
Owner: Claude

## Research Question

What screens exist in Crosscue, what are their go_router routes and parameters, and how is the navigation graph structured?

## Decision To Unblock

What is the complete route table and shell layout needed to scaffold go_router and build the initial app shell?

## Recommendation

Use a go_router `ShellRoute` for the four bottom-navigation tabs (Home, Archive, Stats, Settings) so tab state is preserved across switches. The Solve screen lives outside the shell — it is pushed modally or as a full-page route so the bottom nav disappears while solving. The Import screen is also outside the shell, triggered from Home or Settings.

---

## Complete Screen Inventory

### Tab Shell Screens (bottom nav always visible)

| # | Screen | Tab label | Tab icon | Route path |
|---|--------|-----------|----------|------------|
| 1 | `HomeScreen` | Today | `Icons.grid_4x4` | `/` |
| 2 | `ArchiveScreen` | Archive | `Icons.calendar_month` | `/archive` |
| 3 | `StatsScreen` | Stats | `Icons.bar_chart` | `/stats` |
| 4 | `SettingsScreen` | Settings | `Icons.settings` | `/settings` |

### Full-Page Screens (no bottom nav)

| # | Screen | Route path | Parameters | How reached |
|---|--------|------------|------------|-------------|
| 5 | `SolveScreen` | `/solve/:puzzleId` | `puzzleId` (String) | Tap today's card or any puzzle in Archive |
| 6 | `ImportScreen` | `/import` | none | FAB on HomeScreen (Phase 1 primary CTA); also Settings → Import puzzle |
| 7 | `OnboardingScreen` | `/onboarding` | none | First launch only — redirected by `AppRouter` when `hasSeenOnboarding == false` |

### Dialog / Bottom Sheet (not full routes)

| # | Widget | Trigger |
|---|--------|---------|
| A | Completion stats sheet | Auto-shown when `PuzzleStatus` transitions to `solved` / `solvedWithHelp` / `revealed` |
| B | Reveal puzzle confirmation dialog | Tap "Reveal puzzle" in overflow menu |
| C | Import error bottom sheet | File parse fails during import |
| D | Data export/import sheet | Settings → Manage data |

Dialogs and sheets are not go_router routes — they are shown imperatively from within their parent screen using `showModalBottomSheet` / `showDialog`.

---

## Navigation Graph

```
App launch
  │
  ├── hasSeenOnboarding == false ──► /onboarding ──► /  (replace)
  │
  └── hasSeenOnboarding == true ───► ShellRoute (bottom nav)
                                          │
                          ┌───────────────┼───────────────┐
                          ▼               ▼               ▼               ▼
                        /             /archive         /stats         /settings
                    HomeScreen      ArchiveScreen    StatsScreen    SettingsScreen
                          │               │
                          │               │
                          ▼               ▼
                  /solve/:puzzleId   /solve/:puzzleId
                    SolveScreen        SolveScreen
                          │
                          └── (back) returns to originating tab

                  /import  ◄──── HomeScreen (Phase 1 primary CTA)
                            ◄──── SettingsScreen → "Import puzzle"
                  ImportScreen
                          │
                          └── success: navigate to /solve/:newPuzzleId
                          └── cancel: go_router.pop()
```

---

## go_router Setup

```dart
// lib/core/routing/routes.dart
abstract class Routes {
  static const home       = '/';
  static const archive    = '/archive';
  static const stats      = '/stats';
  static const settings   = '/settings';
  static const solve      = '/solve/:puzzleId';
  static const import_    = '/import';          // 'import' is a Dart keyword — use trailing underscore
  static const onboarding = '/onboarding';

  static String solveWith(String puzzleId) => '/solve/$puzzleId';
}
```

```dart
// lib/core/routing/app_router.dart
final appRouterProvider = Provider<GoRouter>((ref) {
  final hasSeenOnboarding = ref.watch(hasSeenOnboardingProvider);

  return GoRouter(
    initialLocation: Routes.home,
    redirect: (context, state) {
      if (!hasSeenOnboarding && state.matchedLocation != Routes.onboarding) {
        return Routes.onboarding;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.import_,
        builder: (context, state) => const ImportScreen(),
      ),
      GoRoute(
        path: Routes.solve,
        builder: (context, state) {
          final puzzleId = state.pathParameters['puzzleId']!;
          return SolveScreen(puzzleId: puzzleId);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: Routes.archive,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ArchiveScreen()),
          ),
          GoRoute(
            path: Routes.stats,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StatsScreen()),
          ),
          GoRoute(
            path: Routes.settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});
```

`NoTransitionPage` is used for tab switches — tab navigation should feel instant, not slide. `SolveScreen` uses the default slide-up transition.

---

## AppShell (bottom nav host)

```dart
// lib/core/routing/app_shell.dart
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFromLocation(location),
        onDestinationSelected: (index) =>
            context.go(_locationFromIndex(index)),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_4x4), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Archive'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  int _indexFromLocation(String location) => switch (location) {
    String l when l.startsWith('/archive') => 1,
    String l when l.startsWith('/stats')   => 2,
    String l when l.startsWith('/settings')=> 3,
    _                                       => 0,
  };

  String _locationFromIndex(int index) => switch (index) {
    1 => Routes.archive,
    2 => Routes.stats,
    3 => Routes.settings,
    _ => Routes.home,
  };
}
```

---

## Screen Parameter Contracts

### `SolveScreen`
| Parameter | Type | Source | Notes |
|-----------|------|--------|-------|
| `puzzleId` | `String` | Path param | Matches `puzzles.id` in Drift. `PuzzleNotifier` loads the session by this ID. |

### `OnboardingScreen`
No parameters. Reads `hasSeenOnboardingProvider` internally; writes `true` on completion/skip, which triggers the router redirect to drop out of onboarding.

### `ImportScreen`
No parameters. On successful import, calls `context.go(Routes.solveWith(newPuzzleId))` to navigate directly into the imported puzzle.

---

## Deep Link Behaviour

Phase 1 has no external deep links (no network sources, no share URLs). The only deep-link-like behaviour is:

- **Import success → Solve:** `ImportScreen` pushes `/solve/:id` on completion.
- **Onboarding complete → Home:** router redirect replaces onboarding with `/`.

Phase 2 additions (not needed now, but route structure supports them):
- `crosscue://solve/:puzzleId` — open a specific puzzle from a notification tap.
- `crosscue://archive` — open archive from a home screen widget tap.

---

## Back Stack Behaviour

| From | Action | Result |
|------|--------|--------|
| `SolveScreen` | System back / back button | Returns to originating tab (Home or Archive) |
| `ImportScreen` | System back | Returns to caller (Home or Settings) |
| `OnboardingScreen` | System back | Disabled — onboarding must be completed or skipped |
| Tab switch | Any tab tap | Instant; no back stack entry — `context.go()`, not `context.push()` |

---

## Implementation Checklist

1. Add `go_router` dependency to `pubspec.yaml`.
2. Create `lib/core/routing/routes.dart` with path constants.
3. Create `lib/core/routing/app_router.dart` with the `GoRouter` provider.
4. Create placeholder screen classes for all 7 screens (empty `Scaffold` with title).
5. Create `AppShell` with `NavigationBar` and tab-switching logic.
6. Add `hasSeenOnboardingProvider` backed by `app_settings` Drift table. Declare it as a `FutureProvider<bool>` that reads the `has_seen_onboarding` key via `SettingsDao`; the router re-evaluates on every watch call, so writing `true` on completion/skip triggers the redirect automatically:
   ```dart
   final hasSeenOnboardingProvider = FutureProvider<bool>((ref) async {
     final dao = ref.read(settingsDaoProvider);
     return dao.getBool('has_seen_onboarding') ?? false;
   });
   ```
7. Wire `MaterialApp.router` in `app.dart` to `appRouterProvider`.
8. Smoke-test all routes navigate without crashing before building screen content.

## Sources

- [go_router documentation](https://pub.dev/documentation/go_router/latest/)
- [go_router ShellRoute](https://pub.dev/documentation/go_router/latest/go_router/ShellRoute-class.html)
- [Flutter NavigationBar (Material 3)](https://api.flutter.dev/flutter/material/NavigationBar-class.html)
- Internal: [topic-12-flutter-project-structure.md](topic-12-flutter-project-structure.md)
- Internal: [topic-10-design-ux-research.md](topic-10-design-ux-research.md)
