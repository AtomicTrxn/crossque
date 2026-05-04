# Research Topic #2 — Drift Database Schema

Status: Resolved
Implementation Status: ✅ Implemented — Sprint 1 (tables, indexes, TypeConverters); Sprint 4 will implement solve_sessions + cell_progress autosave
Owner: Codex

## Research Question

What Drift/SQLite schema should support saved puzzles, puzzle metadata, source registry entries, in-progress state, timers, solve history, checks/reveals, and cache expiration?

## Decision To Unblock

What local persistence model should the app implement first so puzzle imports, source downloads, resume-after-relaunch, check/reveal state, and archive browsing all have a stable foundation?

## Recommendation

Use a normalized SQLite/Drift schema for queryable metadata and mutable solve state, while storing immutable puzzle bodies as canonical `.ipuz`-style JSON. Start with `sources`, `puzzles`, `clues`, `solve_sessions`, and `cell_progress` as the MVP tables. Add `solve_events`, `source_cache_entries`, and `app_settings` when those features arrive.

This gives the app fast archive/source queries without over-normalizing crossword grid content too early. It also keeps per-cell writes small and reliable for autosave.

## Working Assumptions

- Store the canonical puzzle body as normalized `.ipuz`-style JSON, even when imported from `.puz` or `.jpz`.
- Keep immutable puzzle content separate from mutable solve progress.
- Persist the latest playable state after every cell entry, but keep undo/redo history in memory only unless explicit resume-after-crash history becomes a requirement.
- Make local storage work without accounts or backend sync in Phase 1.
- Use Drift migrations from day one; schema changes are likely as source support and puzzle formats mature.

## Proposed Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `sources` | Registered puzzle providers and local import pseudo-sources | `id`, `display_name`, `type`, `homepage_url`, `terms_url`, `attribution`, `enabled`, `license_status`, `license_url`, `permission_contact`, `attribution_required`, `cache_policy`, `raw_payload_retention`, `commercial_use_allowed`, `last_legal_review_at`, `last_checked_at`, `last_success_at`, `etag`, `created_at`, `updated_at` |
| `puzzles` | Immutable puzzle metadata plus canonical puzzle payload | `id`, `source_id`, `source_puzzle_id`, `format`, `title`, `author`, `copyright`, `publish_date`, `difficulty`, `width`, `height`, `checksum`, `canonical_json`, `raw_payload`, `fetched_at`, `expires_at`, `created_at`, `updated_at` |
| `clues` | Queryable clue metadata for lists, search, and accessibility labels | `id`, `puzzle_id`, `direction`, `number`, `sort_order`, `start_row`, `start_col`, `text`, `answer_length` |
| `solve_sessions` | One row per user's active or completed attempt for a puzzle | `id`, `puzzle_id`, `device_id`, `status`, `completion_type`, `started_at`, `last_played_at`, `completed_at`, `solved_date_local`, `solved_timezone`, `elapsed_ms`, `is_paused`, `paused_at`, `total_paused_ms`, `mistake_count`, `check_count`, `reveal_count`, `used_check`, `used_reveal`, `clean_solve_eligible`, `focus_row`, `focus_col`, `direction`, `is_synced`, `sync_version`, `created_at`, `updated_at` |
| `cell_progress` | Mutable per-cell player state for the latest persisted session | `session_id`, `row`, `col`, `guess`, `state`, `was_checked`, `was_revealed`, `last_wrong_guess_hash`, `updated_at` |
| `solve_events` | Optional audit/event stream for stats and debugging | `id`, `session_id`, `event_type`, `row`, `col`, `direction`, `payload_json`, `created_at` |
| `source_cache_entries` | Lightweight cache bookkeeping for source index/list responses | `source_id`, `cache_key`, `url`, `etag`, `last_modified`, `payload_hash`, `fetched_at`, `expires_at` |
| `app_settings` | Small local settings store | `key`, `value_json`, `updated_at` |

## Indexes And Constraints

- `sources.id` primary key; use stable IDs like `universal`, `latimes`, `guardian`, `local_import`.
- Source rows must default to disabled unless `license_status` is `user_import`, `explicit_permission`, or `open_license`.
- `puzzles.id` primary key, generated as `source_id:source_puzzle_id` when the source has stable IDs; local imports can use a checksum-based ID.
- Unique index on `puzzles(source_id, source_puzzle_id)` to prevent duplicate downloads.
- Index `puzzles(publish_date, source_id)` for Today and Archive screens.
- Index `puzzles(checksum)` for duplicate imported files.
- Unique index on `clues(puzzle_id, direction, number)`.
- Unique index on `cell_progress(session_id, row, col)`.
- Index `solve_sessions(puzzle_id, status)` for resume and review flows.
- Index `solve_sessions(last_played_at)` for recent puzzles.
- Index `solve_sessions(solved_date_local)` and `solve_sessions(completion_type)` for streak/stat aggregation.
- Foreign keys should cascade from `puzzles` to `clues`, `solve_sessions`, and from `solve_sessions` to `cell_progress` and `solve_events`.

## Drift Implementation Notes

- Use `TextColumn` + `TypeConverter.json2` or an explicit converter for structured fields such as `canonical_json`, `payload_json`, and `value_json`.
- Keep frequently filtered fields, like `publish_date`, `source_id`, `status`, `width`, and `height`, as real columns instead of burying them in JSON.
- Store `DateTime` consistently in UTC. Display local dates only at the UI/source boundary.
- Wrap puzzle insert/update flows in transactions: insert puzzle, clues, cache metadata, and initial session atomically.
- Prefer repository mapping between Drift rows and domain models so the domain layer does not depend on generated Drift classes.
- Align source legal fields with topic #7 before any network source is enabled.
- Align `device_id`, sync flags, and timestamps with topic #9 so Phase 1 remains backend-free but sync-ready.
- `solve_sessions.status` valid string values: `not_started` | `in_progress` | `completed` | `revealed`. These map to the domain `PuzzleStatus` enum: `unsolved` → `not_started`; `inProgress` → `in_progress`; `solved` / `solvedWithHelp` → `completed`; `revealed` → `revealed`. A Drift `TypeConverter` handles the mapping. The final `completion_type` column distinguishes `clean` / `checked` / `hinted` / `revealed` within completed sessions (see topic-15).
- Align gameplay counters and completion labels with topic #11 so check/reveal/hint behavior can drive stats consistently.
- Align `solved_date_local`, `solved_timezone`, and completion type rules with topic #15 so streak calculations are stable across timezone changes.
- Align pause fields with topic #17: `elapsed_ms` stores active solving time only, `is_paused` restores the overlay state after relaunch, `paused_at` records when the current pause began, and `total_paused_ms` is available for diagnostics or wall-clock reconciliation without counting toward solve time.

## Open Decisions

| Decision | Current Lean | Notes |
|----------|--------------|-------|
| Store full grid as rows or JSON? | JSON for immutable puzzle, rows for mutable progress | Querying every immutable cell is not needed often; per-cell progress does need targeted writes. |
| Persist undo/redo history? | No for MVP | Save latest state after every edit. Undo history can remain memory-only unless crash recovery of undo stack is required. |
| Store solution answers separately? | In canonical puzzle JSON only | Avoid duplicating solution data unless validation performance becomes an issue. |
| Multiple attempts per puzzle? | Schema allows it; Archive shows only the latest | UI shows one active attempt and the most recent completed attempt per puzzle. "Restart puzzle" (topic-17 §11) creates a new `solve_session` and preserves the old one. DAOs and Archive queries must filter to `ORDER BY last_played_at DESC LIMIT 1` per puzzle to avoid orphan sessions polluting the archive list. |
| Raw downloaded payload retention? | Keep only when allowed | Source ToS should decide whether `raw_payload` is stored, omitted, or deleted after parsing. |

## First Implementation Slice

1. Create Drift tables for `sources`, `puzzles`, `clues`, `solve_sessions`, and `cell_progress`, including timer pause fields before the first migration ships.
2. Add DAOs/repositories for source upsert, puzzle import, session resume, and cell update.
3. Add one fixture import path that converts a rights-cleared `.ipuz` or `.puz` into `puzzles` + `clues`.
4. Add tests for duplicate puzzle upsert, resume after relaunch, and per-cell progress persistence.
5. Add tests that network sources cannot be enabled unless their `license_status` allows it.

## Sources

Accessed April 30, 2026.

- [Drift docs](https://pub.dev/documentation/drift/latest/)
- [Drift `TypeConverter` docs](https://pub.dev/documentation/drift/latest/drift/TypeConverter-class.html)
