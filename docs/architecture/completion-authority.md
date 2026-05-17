# Completion data authority

> Closes [#59 (Sprint E5)](https://github.com/AtomicTrxn/crosscue/issues/59).
> Companion doc to `ARCHITECTURE.md`. Updated when the rules below change.

## TL;DR

The codebase already has a workable hybrid model — it's just not documented, and a few persistence rough edges create divergence risk. This doc names the layers, fixes the gaps.

**Rules:**

1. **In-memory `SolveState`** owns the **live, in-progress** solve. Only the `SolveNotifier` writes to it.
2. **`puzzle_completions`** (immutable, append-only) is the authority for **completion history** — stats, streaks, personal bests.
3. **`solve_sessions`** is the **resumable session cache** — one mutable row per puzzle, used by Archive and on session resume. It mirrors the latest in-memory state but is not the historical source of truth.
4. **`PuzzleStatus` ↔ `CompletionType`** mapping is owned by `SolveRepositoryImpl._statusFromDb` (load) and `SolveNotifier._deriveCompletionType` (save). These two functions must stay inverses of each other.

---

## Where completion data lives today

| Store | Mutability | Owner | Read by |
|---|---|---|---|
| `SolveState.status` / `usedCheck` / `usedReveal` / `checkCount` / `revealCount` | mutable (in-memory) | `SolveNotifier` | `SolveScreen`, `CompletionSheet` |
| `solve_sessions` row (one per puzzle) | mutable (DB) | `SolveRepositoryImpl.saveProgress` / `markComplete` | `ArchiveRepositoryImpl`, `createOrResumeSession` |
| `puzzle_completions` row (one per completion) | append-only (DB) | `SolveRepositoryImpl.markComplete` → `PuzzleCompletionDao.recordCompletion` | `StatsRepositoryImpl.getStats`, `StatsDao.getStreakDates` |
| Derived flags inside `StatsData` | computed | `StatsRepositoryImpl.getStats` | `StatsScreen` widgets |

### The three completion enums

- **`PuzzleStatus`** (`core/domain/models/enums.dart`) — domain layer. Six values: `unsolved`, `inProgress`, `solved`, `solvedWithHelp`, `solvedWithReveal`, `revealed`.
- **`CompletionType`** (`core/domain/models/enums.dart`) — domain layer. Four values: `clean`, `checked`, `hinted`, `revealed`. Maps to `puzzle_completions.completion_type` and `solve_sessions.completion_type`.
- **DB `status` string** — `'not_started'` | `'in_progress'` | `'completed'` | `'revealed'`. Lossy: both `solvedWithHelp` and `solvedWithReveal` collapse to `'completed'`, recovered via `completion_type`.

### Round-trip mapping

```
PuzzleStatus.solved            ─┐
PuzzleStatus.solvedWithHelp     ├─ DB status='completed', completion_type='clean'/'checked'/'hinted'
PuzzleStatus.solvedWithReveal  ─┘
PuzzleStatus.revealed           ── DB status='revealed',  completion_type='revealed'
PuzzleStatus.inProgress         ── DB status='in_progress', completion_type=null
```

The encoding is consistent but the naming is confusing: `usedReveal=true` in memory produces `CompletionType.hinted` in the DB (not `revealed`), because "hinted" means "they used a reveal action" while "revealed" means "they revealed the whole puzzle." `_statusFromDb` knows this and round-trips correctly.

---

## Divergence risk

Today, in-memory and DB state can disagree in these windows:

1. **Completion → DB write window.** `_checkCompletion` sets `state = AsyncData(completed)` immediately, then calls `_persistCompletion` which fires `markComplete` **unawaited** (`solve_notifier.dart:565`). If the process dies in this window, the in-memory completion is lost — the next resume sees the previous in-progress state.

2. **Autosave debounce window (500 ms).** Letter input mutates `SolveState` immediately, schedules a debounced save. A kill before the debounce fires loses up to 500 ms of input.

3. **Reset-while-saving race.** `resetPuzzle` overwrites the `solve_sessions` row with `in_progress` and clears completion fields. If a previous `markComplete` is still in flight, the reset might land first or second — the historical `puzzle_completions` row is safe (it's a separate insert) but the `solve_sessions` snapshot could land in an unexpected intermediate state.

4. **`solve_sessions.completion_type` redundancy.** This column duplicates the `puzzle_completions.completion_type` for the latest completion. They can diverge if `markComplete` partially fails (one insert succeeds, the other doesn't). Not observed today but the schema allows it.

5. **`usedCheck` / `usedReveal` post-completion staleness.** These flags are on `solve_sessions` and persist after completion. They're never read by UI (verified by grep), but `_deriveCompletionType` re-derives the type from them on every persist. If a future feature reads these flags directly and the row was last written before the completion type was fixed up, they could mismatch.

---

## Options

### Option A — Notifier (in-memory) is authority

The active `SolveNotifier` owns completion truth. DB is a derived cache written on completion + autosave.

- ✅ Simple model while a puzzle is active.
- ❌ Doesn't help any of the consumers that need completion data for **past** puzzles (Archive, Stats, Streak). They have no notifier to read from — they must read DB.
- ❌ Doesn't actually fix the divergence windows; just renames the problem.

**Verdict: rejected.** The notifier is per-puzzle and ephemeral. Stats/Archive read across all puzzles and need a persistent authority.

### Option B — Database is authority

All consumers read from DB. The notifier subscribes to DB streams and renders.

- ✅ Single source of truth across all features.
- ❌ Requires routing every in-memory write through a DB round-trip before UI updates — visible latency on every keystroke unless we keep an in-memory cache, which puts us back in the hybrid state.
- ❌ Major refactor of `SolveNotifier` for marginal correctness gain; the existing in-memory model is appropriate for a live solve.

**Verdict: rejected.** Trading UX latency for an abstraction that the codebase doesn't need.

### Option C — Hybrid, with named authorities (recommended)

Each layer owns a specific slice of the truth. The rules from the TL;DR above are the rules.

- ✅ Matches the existing implementation; the work is mostly documentation + targeted tightenings.
- ✅ Each consumer reads from the right authority: live UI from the notifier, historical UI from the right DB table.
- ✅ Divergence windows shrink to a small, named set of behaviors that we choose deliberately (e.g., "autosave is debounced — last 500ms of input is lost on kill, by design").
- ⚠️ Requires discipline: future code that adds a fourth completion-related field needs to pick its authority deliberately and document it.

**Verdict: adopt.**

---

## Required tightenings (after this doc lands)

These are the concrete code changes needed to make Option C robust:

1. **Await or document `markComplete`.** `_persistCompletion` fires it unawaited. Either await it (so the notifier's `_checkCompletion` returns only after persistence completes) or add a code comment justifying fire-and-forget and document the kill-window risk. Recommended: keep unawaited but invoke `flushPendingSave` on screen dispose if `status.isTerminal`.

2. **Tests for the round-trip.** Add a test that completes a puzzle in `SolveNotifier`, kills the notifier, recreates it for the same `puzzleId`, and asserts `SolveState.status` survives. Covers the inverse-mapping guarantee in rule 4.

3. **Tests for the reset race.** Trigger `resetPuzzle` while `markComplete` is still in flight (use a controllable test repository); assert `puzzle_completions` retains the original completion row and `solve_sessions` ends in the expected `in_progress` state.

4. **Document the `usedCheck` / `usedReveal` columns as session-state-only.** They're inputs to `CompletionType` derivation at save time. Anything else reading them is a bug. Add a comment to `solve_sessions_table.dart`.

5. **Decide on `solve_sessions.completion_type`.** It's redundant with `puzzle_completions.completion_type` for the latest completion. Either: (a) keep it for Archive's quick-read convenience and accept the duplication; (b) drop the column and have Archive join against `puzzle_completions` for the latest completion. Recommended: **(a)** — Archive's per-row reads are hot and the duplication is bounded (one row per puzzle, written together in `markComplete`).

6. **Add a one-paragraph entry to `ARCHITECTURE.md`'s "Recent Architectural Decisions" log** linking to this doc.

---

## Non-goals

- Schema redesign (no column adds/drops in this work).
- Replacing the autosave debounce with synchronous writes (would regress UX).
- Migrating to a single-table completion model — `solve_sessions` and `puzzle_completions` serve different access patterns (latest-per-puzzle vs. all-time history) and the split is well-justified.

---

## Implementation order

If this recommendation is approved:

1. Land this doc + the ARCHITECTURE.md link in a research-only PR (this branch).
2. Open a follow-up PR for the tightenings: 1, 2, 3 above. Items 4–5 are doc-only tweaks that can ride along.
3. Re-evaluate after the tightenings — if divergence-related bugs still show up, reopen the authority question.
