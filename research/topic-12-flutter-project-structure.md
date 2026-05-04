# Research Topic #12 — Flutter Project Structure & Folder Conventions

Status: Resolved
Implementation Status: ✅ Implemented — Sprint 1; superseded by ARCHITECTURE.md (canonical reference going forward)
Owner: Claude

## Research Question

How should the Crosscue Flutter project's `lib/` directory be organised so that Clean Architecture layers are clear, features are isolated, shared infrastructure is easy to find, and new developers can orient themselves without a guide?

## Decision To Unblock

What is the canonical folder layout and file naming convention the team will use from `flutter create` onwards?

## Recommendation

Use a **feature-first layout with a shared `core/` layer**. Each feature owns its own `data/`, `domain/`, and `presentation/` sublayers. Truly shared infrastructure (Drift database, theme, routing, cross-feature domain models) lives in `core/`. This keeps features self-contained while avoiding duplication of shared plumbing.

---

## Full Directory Layout

```
crosscue/
├── android/
├── ios/
├── test/
│   ├── features/
│   │   ├── solve/
│   │   ├── import/
│   │   └── ...
│   └── core/
├── integration_test/
└── lib/
    ├── main.dart                  # Entry point: ProviderScope + runApp
    ├── app.dart                   # MaterialApp.router, theme, go_router ref
    │
    ├── core/
    │   ├── database/
    │   │   ├── app_database.dart          # Drift database class (@DriftDatabase)
    │   │   ├── app_database.g.dart        # Generated — do not edit
    │   │   └── tables/
    │   │       ├── sources_table.dart
    │   │       ├── puzzles_table.dart
    │   │       ├── clues_table.dart
    │   │       ├── solve_sessions_table.dart
    │   │       └── cell_progress_table.dart
    │   ├── routing/
    │   │   ├── app_router.dart            # GoRouter instance (Riverpod provider)
    │   │   ├── app_shell.dart             # Bottom-nav ShellRoute host widget
    │   │   └── routes.dart                # Route path constants
    │   ├── theme/
    │   │   ├── app_theme.dart             # ThemeData light + dark
    │   │   └── crossword_theme.dart       # CrosswordTheme extension on ThemeData
    │   ├── providers/
    │   │   └── core_providers.dart        # Database, SyncAdapter, DeviceId providers
    │   ├── sync/
    │   │   ├── sync_adapter.dart          # Abstract SyncAdapter interface
    │   │   └── no_op_sync_adapter.dart    # Phase 1 no-op implementation
    │   ├── telemetry/
    │   │   ├── crash_reporter.dart        # Abstract CrashReporter interface (see topic-05)
    │   │   ├── analytics_service.dart     # Abstract AnalyticsService interface (noop Phase 1)
    │   │   ├── feedback_reporter.dart     # Abstract FeedbackReporter interface
    │   │   └── noop_analytics_service.dart
    │   ├── entitlement/
    │   │   ├── entitlement_service.dart   # Abstract EntitlementService interface (see topic-04)
    │   │   └── free_entitlement_service.dart  # Phase 1 free-tier implementation
    │   └── utils/
    │       ├── date_utils.dart
    │       └── result.dart                # Result<T, E> type for error handling
    │
    ├── features/
    │   │
    │   ├── solve/                         # Puzzle solving — the core feature
    │   │   ├── data/
    │   │   │   ├── daos/
    │   │   │   │   ├── solve_session_dao.dart
    │   │   │   │   └── cell_progress_dao.dart
    │   │   │   └── repositories/
    │   │   │       └── solve_repository_impl.dart
    │   │   ├── domain/
    │   │   │   ├── models/
    │   │   │   │   ├── puzzle.dart              # Freezed — immutable loaded puzzle
    │   │   │   │   ├── puzzle_metadata.dart
    │   │   │   │   ├── solution_cell.dart        # Freezed — immutable grid cell
    │   │   │   │   ├── clue.dart
    │   │   │   │   ├── cell_progress.dart        # Freezed — mutable progress cell
    │   │   │   │   ├── puzzle_state.dart         # Freezed — full solve session state
    │   │   │   │   ├── focus_position.dart
    │   │   │   │   └── enums.dart                # Direction, CellState, PuzzleStatus, EntryMode, PuzzleFormat, SourceType
    │   │   │   ├── engine/
    │   │   │   │   ├── puzzle_engine.dart         # Pure logic: no Flutter deps
    │   │   │   │   ├── game_rules.dart            # PuzzleInteractionPolicy interface
    │   │   │   │   ├── default_game_rules.dart    # Standard crossword rules
    │   │   │   │   └── movement_strategy.dart     # MovementStrategy interface + defaults
    │   │   │   └── repositories/
    │   │   │       └── i_solve_repository.dart    # Interface (domain owns this)
    │   │   └── presentation/
    │   │       ├── screens/
    │   │       │   └── solve_screen.dart
    │   │       ├── notifiers/
    │   │       │   ├── puzzle_notifier.dart       # AsyncNotifier<PuzzleState>
    │   │       │   └── timer_notifier.dart
    │   │       ├── providers/
    │   │       │   └── solve_providers.dart       # Riverpod providers for this feature
    │   │       ├── widgets/
    │   │       │   ├── crossword_grid.dart        # Stateful widget wrapping painter
    │   │       │   ├── clue_bar.dart
    │   │       │   ├── clue_panel.dart
    │   │       │   └── custom_keyboard.dart
    │   │       └── painters/
    │   │           ├── crossword_grid_painter.dart
    │   │           └── grid_metrics.dart          # Shared geometry for paint + semantics
    │   │
    │   ├── import/                        # File import — .puz / .ipuz / .jpz
    │   │   ├── data/
    │   │   │   ├── parsers/
    │   │   │   │   ├── puzzle_parser.dart         # Abstract interface
    │   │   │   │   ├── puz_parser.dart            # .puz binary parser
    │   │   │   │   ├── ipuz_parser.dart           # .ipuz JSON parser
    │   │   │   │   └── jpz_parser.dart            # Phase 2 stub — file exists, not implemented (see topic-14)
    │   │   │   ├── daos/
    │   │   │   │   └── puzzle_dao.dart
    │   │   │   └── repositories/
    │   │   │       └── import_repository_impl.dart
    │   │   ├── domain/
    │   │   │   └── repositories/
    │   │   │       └── i_import_repository.dart
    │   │   └── presentation/
    │   │       ├── screens/
    │   │       │   └── import_screen.dart
    │   │       ├── notifiers/
    │   │       │   └── import_notifier.dart
    │   │       └── providers/
    │   │           └── import_providers.dart
    │   │
    │   ├── home/                          # Today tab — streak + today's puzzle card
    │   │   ├── data/
    │   │   │   └── repositories/
    │   │   │       └── home_repository_impl.dart
    │   │   ├── domain/
    │   │   │   ├── models/
    │   │   │   │   └── home_state.dart
    │   │   │   └── repositories/
    │   │   │       └── i_home_repository.dart
    │   │   └── presentation/
    │   │       ├── screens/
    │   │       │   └── home_screen.dart
    │   │       ├── notifiers/
    │   │       │   └── home_notifier.dart
    │   │       ├── providers/
    │   │       │   └── home_providers.dart
    │   │       └── widgets/
    │   │           ├── today_puzzle_card.dart
    │   │           └── streak_banner.dart
    │   │
    │   ├── archive/                       # Archive tab — past puzzles browser
    │   │   ├── data/
    │   │   ├── domain/
    │   │   └── presentation/
    │   │       ├── screens/
    │   │       │   └── archive_screen.dart
    │   │       ├── notifiers/
    │   │       └── providers/
    │   │
    │   ├── stats/                         # Stats tab — streaks, solve times, history
    │   │   ├── data/
    │   │   │   └── repositories/
    │   │   │       └── stats_repository_impl.dart
    │   │   ├── domain/
    │   │   │   ├── models/
    │   │   │   │   └── solve_stats.dart
    │   │   │   └── repositories/
    │   │   │       └── i_stats_repository.dart
    │   │   └── presentation/
    │   │       ├── screens/
    │   │       │   └── stats_screen.dart
    │   │       ├── notifiers/
    │   │       │   └── stats_notifier.dart
    │   │       └── providers/
    │   │           └── stats_providers.dart
    │   │
    │   └── settings/                      # Settings tab
    │       ├── domain/
    │       │   └── models/
    │       │       └── app_settings.dart
    │       └── presentation/
    │           ├── screens/
    │           │   └── settings_screen.dart
    │           ├── notifiers/
    │           │   └── settings_notifier.dart
    │           └── providers/
    │               └── settings_providers.dart
    │
    └── sources/                           # Puzzle source registry (Phase 2+)
        ├── source_registry.dart           # SourceRegistry + LicenseStatus guard
        └── local_import_source.dart       # Phase 1 local-import pseudo-source
```

---

## Layer Responsibilities

### `core/`

Shared infrastructure that multiple features depend on. Nothing in `core/` imports from `features/`.

| Subfolder | Contains |
|-----------|----------|
| `core/database/` | Single Drift `AppDatabase` class and all table definitions |
| `core/routing/` | `GoRouter` instance as a Riverpod provider; route path constants |
| `core/theme/` | `ThemeData` (light/dark) and `CrosswordTheme` extension |
| `core/providers/` | Database provider, `SyncAdapter` provider, device ID provider |
| `core/sync/` | `SyncAdapter` interface and `NoOpSyncAdapter` (Phase 1) |
| `core/telemetry/` | `CrashReporter`, `AnalyticsService`, `FeedbackReporter` interfaces + no-op implementations (see topic-05) |
| `core/entitlement/` | `EntitlementService` interface and `FreeEntitlementService` (Phase 1 free tier, see topic-04) |
| `core/utils/` | Pure utility functions; no Flutter widget deps |

### `features/<name>/data/`

Drift DAOs, repository implementations, file parsers, and any external data sources. Depends on `core/database/`. Implements interfaces defined in `domain/`.

### `features/<name>/domain/`

Pure Dart: models (Freezed), engine logic, repository interfaces. **No Flutter imports. No Drift imports.** This layer is independently testable.

### `features/<name>/presentation/`

Flutter widgets, Riverpod notifiers, screen files, and painters. Depends on `domain/` models and calls repository interfaces. Never imports from another feature's `presentation/` — use domain models or shared widgets instead.

### `sources/`

`SourceRegistry` and concrete `PuzzleSource` implementations. Kept at the top level because sources are cross-cutting (home, archive, and import all interact with them). Phase 1 only contains `LocalImportSource`.

---

## File Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Screens | `<feature>_screen.dart` | `solve_screen.dart` |
| Notifiers | `<feature>_notifier.dart` | `puzzle_notifier.dart` |
| Riverpod providers file | `<feature>_providers.dart` | `solve_providers.dart` |
| Freezed models | `<model_name>.dart` | `puzzle_state.dart` |
| Drift tables | `<table>_table.dart` | `solve_sessions_table.dart` |
| DAOs | `<entity>_dao.dart` | `solve_session_dao.dart` |
| Repository interfaces | `i_<name>_repository.dart` | `i_solve_repository.dart` |
| Repository implementations | `<name>_repository_impl.dart` | `solve_repository_impl.dart` |
| Painters | `<name>_painter.dart` | `crossword_grid_painter.dart` |
| Parsers | `<format>_parser.dart` | `puz_parser.dart` |
| Generated files | `*.g.dart`, `*.freezed.dart` | Auto — do not edit |

All file names: `snake_case`. All classes: `PascalCase`. All Riverpod providers: `camelCase` with `Provider` suffix (e.g. `puzzleNotifierProvider`).

---

## Riverpod Provider Conventions

- Each feature has one `<feature>_providers.dart` file that declares all providers for that feature.
- `core/providers/core_providers.dart` declares the database, sync adapter, and device ID providers that other features depend on.
- Notifiers use `AsyncNotifier<T>` for state that requires async initialisation (loading a puzzle from DB), `Notifier<T>` for synchronous state.
- Never expose Drift-generated types (`SolveSessionData`, etc.) from a provider — map to domain models in the repository before returning.

```dart
// core/providers/core_providers.dart
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// features/solve/presentation/providers/solve_providers.dart
final puzzleNotifierProvider =
    AsyncNotifierProvider<PuzzleNotifier, PuzzleState>(PuzzleNotifier.new);
```

---

## Test Folder Mirroring

`test/` mirrors `lib/` exactly:

```
test/
  core/
    database/
      app_database_test.dart
  features/
    solve/
      domain/
        engine/
          puzzle_engine_test.dart
          movement_strategy_test.dart
      data/
        parsers/           # Covered in import feature tests
    import/
      data/
        parsers/
          puz_parser_test.dart
          ipuz_parser_test.dart
    stats/
      domain/
        streak_algorithm_test.dart
```

`integration_test/` covers end-to-end flows: import a file → solve a puzzle → verify state restored after relaunch.

---

## What Goes Where — Quick Reference

| Question | Answer |
|----------|--------|
| Where does the Drift database class live? | `lib/core/database/app_database.dart` |
| Where do Drift table definitions live? | `lib/core/database/tables/` |
| Where does a DAO live? | `lib/features/<feature>/data/daos/` |
| Where do Freezed models live? | `lib/features/<feature>/domain/models/` |
| Where does the puzzle engine live? | `lib/features/solve/domain/engine/` |
| Where does the canvas painter live? | `lib/features/solve/presentation/painters/` |
| Where do file parsers live? | `lib/features/import/data/parsers/` |
| Where does the router live? | `lib/core/routing/app_router.dart` |
| Where does `AppShell` live? | `lib/core/routing/app_shell.dart` |
| Where does the theme live? | `lib/core/theme/` |
| Where does `SourceRegistry` live? | `lib/sources/source_registry.dart` |
| Where do shared utility functions live? | `lib/core/utils/` |

---

## Cross-Feature Import Rules

- `features/A/` **must not** import from `features/B/presentation/`. Use domain models.
- `features/A/domain/` **must not** import from `core/database/`. Use repository interfaces.
- `core/` **must not** import from `features/`.
- `sources/` may import from `features/import/domain/` (for `Puzzle` model) and `core/database/`.
- Generated files (`*.g.dart`, `*.freezed.dart`) are never imported directly — only their parent class files.

---

## Implementation Checklist

1. Run `flutter create --org com.raptortech crosscue` to scaffold the project (the project name is derived from the directory argument; `--project-name` is not a valid flag for `flutter create`).
2. Create the full `lib/` tree above as empty placeholder files before writing any logic.
3. Add `# Generated — do not edit` comment headers to `*.g.dart` files in `.gitattributes` as linguist-generated.
4. Add `build_runner` watch task to `Makefile` or project README so generated files stay up to date.
5. Add a `lib/core/utils/result.dart` with a `Result<T, E>` type before writing any repository.
6. Commit the empty scaffold as the first PR so the team agrees on structure before code is added.
