# Crosscue — Code Review Status

**Original review date:** 2026-05-11.

The cleanup pass from the original code review is complete. Most findings were
implemented directly in the codebase, and the remaining durable follow-ups now
live in `ROADMAP.md`.

## Closed In This Pass

- Removed duplicate parser annotations and hot-path `RegExp` allocations.
- Centralized archive/home status presentation and shared puzzle list rows.
- Moved solve-side effects out of `build`.
- Switched home/archive refresh paths to reactive Drift streams.
- Split solve, stats, and onboarding UI into smaller files where practical.
- Moved solve grid mutation logic into domain services.
- Finished the reviewed theme-token migration.
- Replaced production `print` calls with app logging and crash reporting.
- Added route usage coverage so raw route strings stay out of navigation code.
- Fixed the open bug reports for Crosshare auto-download, completed puzzle
  resume, settings tab navigation, solve-cell locking, partially solved
  intersections, today progress refresh, and colorblind correctness indicators.

## Remaining Follow-Up

See `ROADMAP.md` for the active backlog. At the time of this update, the only
remaining local cleanup items are opportunistic UI file splits and keeping parser
tests aligned with the mirrored `test/features/...` layout as new coverage is
added.
