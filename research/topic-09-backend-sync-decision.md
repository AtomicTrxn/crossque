# Research Topic #9 — Backend Sync Decision

Status: Resolved
Owner: Claude
Researched: 2026-04-30

## Research Question

Should Phase 1 have no backend, anonymous backup, account-based sync, or only future-compatible sync hooks? What data would need to sync, how does conflict resolution work, and what does this decision cost later if we change it?

## Decision To Unblock

Should the Phase 1 architecture include any backend infrastructure, and if not, how should local state be structured so sync can be added in Phase 2 without a breaking schema migration?

## Recommendation

**Phase 1: No backend. Local-only with Android Auto Backup enabled and a Drift export/import hook.**

Do not build a backend for Phase 1. The app is offline-first by design, has no user accounts, and the daily-puzzle use case does not require cross-device sync to be valuable. Adding a backend too early introduces operational complexity (servers, auth, data retention policies, privacy disclosures, breach risk) that is out of proportion to Phase 1's needs.

Instead:
1. Enable **Android Auto Backup** so Google automatically backs up the Drift database to the user's Google account — zero backend cost, survives reinstall and device change.
2. Add a **manual export/import** flow (Settings → Export data / Import data) so power users can move data between devices.
3. Structure the Drift schema with **`createdAt` / `updatedAt` timestamps and a `deviceId` column** on solve sessions from day one, so sync conflict resolution has what it needs if sync is added later.
4. Define a thin **`SyncAdapter` interface** in the domain layer but leave it unimplemented in Phase 1. This gives Phase 2 a clear seam without any live code path.

---

## What Data Would Need to Sync

| Data type | Sync priority | Conflict risk |
|-----------|--------------|---------------|
| Solve session progress (cell entries) | High — this is the core user investment | Medium — user may solve same puzzle on two devices |
| Solve completion / solve time | High — drives streak | Low — immutable once completed |
| Streak counter | High — main motivator | Low — server wins if ever synced |
| Settings (theme, keyboard, notifications) | Low — annoying to redo but not critical | Low — last-write-wins |
| Puzzle library / archive downloads | Medium — large data, expensive to re-download | Low — additive, no conflict |
| Source registry configs | Low — defaults are fine | Very low |

Conflict scenario that matters most: user starts a puzzle on phone, picks up tablet mid-solve. Without sync, they start over. This is the main user pain sync would solve.

---

## Option Analysis

### Option A: No backend, Auto Backup only (Recommended for Phase 1)

**What it provides:**
- Android Auto Backup automatically includes the Drift SQLite database file (stored in `/data/data/<package>/databases/`) unless explicitly excluded
- Backs up to user's Google account on Android 6.0+
- Restores automatically on reinstall or new device sign-in
- Covers: solve progress, stats, settings, downloaded puzzle library
- Zero cost, zero servers, zero privacy policy scope increase

**What it doesn't provide:**
- Real-time cross-device sync (tablet + phone simultaneously)
- Sync when both devices are in active use
- Web access to data

**Android Auto Backup configuration (AndroidManifest.xml):**
```xml
<application
  android:allowBackup="true"
  android:dataExtractionRules="@xml/backup_rules"
  android:fullBackupContent="@xml/backup_rules_legacy">
```

`res/xml/backup_rules.xml` (API 31+):
```xml
<data-extraction-rules>
  <cloud-backup>
    <include domain="database" path="crossword.db"/>
    <exclude domain="database" path="crossword.db-wal"/>
    <exclude domain="database" path="crossword.db-shm"/>
  </cloud-backup>
</data-extraction-rules>
```

Note: Exclude WAL files — only back up the main database file. The WAL is transient; restoring it in an inconsistent state can corrupt the database.

**Confidence:** High. Well-documented Android platform feature, works with any SQLite/Drift database.

---

### Option B: Local-only, no backup at all

All data lives on device only. Lost on uninstall or device change.

**Verdict:** Acceptable for pure MVP prototyping but not for a shipped app. Users who lose a 30-day streak due to a phone upgrade will churn. Auto Backup is free — there is no reason to skip it.

---

### Option C: Anonymous cloud backup (no accounts)

Store solve data anonymously in a cloud service, identified by a device-generated UUID. Supabase, Firestore, or a minimal backend could store row-level data keyed by anonymous ID.

**Pros:** Cross-device sync without login friction.
**Cons:**
- Anonymous IDs are not portable (device reset = new ID = lost data unless user copies the UUID manually)
- Still requires a backend, privacy policy, data retention decisions, GDPR/CCPA scope
- Orphaned anonymous records accumulate forever unless pruned
- Adds operational cost before the app has proven retention

**Verdict:** Not worth it in Phase 1. The benefits over Auto Backup are marginal; the cost is significant.

---

### Option D: Account-based sync (Google Sign-In, Apple Sign-In)

Users log in; data syncs across all their devices.

**Pros:** True cross-device sync, portable data, identity for future features (leaderboards, contests, sharing).
**Cons:**
- Requires auth flow, token management, backend, database, privacy policy, data deletion API (required by Play/App Store policies)
- Google/Apple sign-in requires policy compliance and store review scrutiny
- Phase 1 has no features that justify account creation friction
- Adding accounts post-launch requires a migration path for existing anonymous local data

**Verdict:** Phase 2 or Phase 3. Design the local schema to be account-ready, but don't build it now.

---

## Future-Compatible Schema Design

Add these columns to the `solve_sessions` table in the Drift schema from day one:

```dart
// In SolveSessionsTable
TextColumn get deviceId => text()(); // UUID generated once per install
DateTimeColumn get createdAt => dateTime()();
DateTimeColumn get updatedAt => dateTime()();
BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
IntColumn get syncVersion => integer().withDefault(const Constant(0))();
```

And to `cell_progress`:
```dart
DateTimeColumn get updatedAt => dateTime()();
```

**Why this matters:** When sync is added later, last-write-wins conflict resolution needs `updatedAt` on each record. Without it, every solve record would need a migration and a "who wins?" policy invented retroactively under time pressure.

---

## SyncAdapter Interface (Phase 1: unimplemented stub)

Define the interface in the domain layer so Phase 2 can plug in an implementation without changing calling code:

```dart
// lib/core/sync/sync_adapter.dart
abstract class SyncAdapter {
  /// Push local changes since [since] to the remote.
  Future<void> push({required DateTime since});

  /// Pull remote changes since [since] and merge into local.
  Future<void> pull({required DateTime since});

  /// True if the adapter has valid credentials / connectivity.
  Future<bool> get isAvailable;
}

// Phase 1 no-op implementation
class NoOpSyncAdapter implements SyncAdapter {
  @override Future<void> push({required DateTime since}) async {}
  @override Future<void> pull({required DateTime since}) async {}
  @override Future<bool> get isAvailable async => false;
}
```

Register `NoOpSyncAdapter` via Riverpod in Phase 1. Phase 2 swaps in a real implementation without touching any other layer.

---

## Manual Export / Import

Provide in Settings → Data:
- **Export:** copy the Drift database file to the user's chosen location (Downloads, cloud storage via Android share sheet)
- **Import:** user selects a `.db` file; app copies it to the app database path after a warning that current data will be overwritten

Use Drift's documented database import/export API:
```dart
// Export
final dbFile = File(await getDatabasePath());
// Share dbFile via share_plus

// Import
await database.close();
await importedFile.copy(await getDatabasePath());
// Reopen database
```

This gives technical users a migration path between devices without any backend.

---

## Conflict Resolution Strategy (for Phase 2 planning)

When sync is eventually built, use **last-write-wins on `updatedAt`** for all solve data. This is appropriate because:
- Crossword solving is not collaborative — only one person is working on a given puzzle
- The user intent is always "my most recent state is correct"
- No merging logic needed (unlike document editors)

Streak data is the only tricky case — if the user solves on two devices on the same day, two completion records exist. Deduplicate by `(puzzle_id, solved_date)` rather than by solve session ID.

---

## iOS Consideration (Phase 2)

iOS does not have Android Auto Backup. The equivalent is **iCloud backup**, which automatically backs up app data (including SQLite databases in the Documents directory) when the device is connected to power, locked, and on Wi-Fi.

Flutter apps store data in the app's support directory, which is included in iCloud backup by default. No additional configuration needed for basic backup.

For cross-device sync on iOS, **iCloud Drive / CloudKit** would be the native option — but this is a Phase 2 decision.

---

## Implementation Checklist

1. Add `deviceId`, `createdAt`, `updatedAt`, `isSynced`, `syncVersion` to `solve_sessions` and `updatedAt` to `cell_progress` in the Drift schema (do this in the initial migration, not as a retrofit).
2. Configure Android Auto Backup in `AndroidManifest.xml` and `res/xml/backup_rules.xml` to include `crossword.db`, exclude WAL files.
3. Generate and store a per-install `deviceId` UUID in the Drift `app_settings` table on first launch.
4. Define `SyncAdapter` interface and register `NoOpSyncAdapter` via Riverpod.
5. Add Settings → Data screen with Export and Import options using `share_plus` and `file_picker`.
6. Test Auto Backup by enabling "Back up now" in Android developer options and verifying restore after reinstall.
7. Do not add backend, auth, or network sync code in Phase 1.

---

## Open Questions for Team Review

1. **Is cross-device sync a Phase 2 or Phase 3 priority?** The daily-puzzle + streak use case strongly motivates sync (user changes phones, loses streak = churn). If this is considered a critical retention risk, sync should move to Phase 2 rather than Phase 3.

2. **Which backend would we use for sync when the time comes?** Options: Supabase (Postgres + auth + realtime, generous free tier), Firebase Firestore (document model, easy Flutter integration), custom REST API. Each has different cost and complexity profiles. The `SyncAdapter` interface keeps this decision open.

3. **Export format: resolved.** Phase 1 exports and imports the raw Drift `.db` file — simplest implementation, already specified in the export/import flow above and in topic-17 §12. A JSON export (one record per solved puzzle, version-tolerant) is the Phase 2 target when cross-device sync requires a portable format. Do not build JSON export in Phase 1.

4. **Does Auto Backup include enough for streak continuity?** Yes — if the database is backed up, streak data (stored in `solve_sessions`) restores with it. But there is a backup frequency limitation: Android backs up at most once every 24 hours. A user who solves a puzzle and immediately resets their phone may lose that day's progress. **Mitigation:** add a brief note on the Settings → Export Data screen: "Export regularly — Auto Backup runs at most once per day." This surfaces the risk without requiring technical changes.

---

## Sources

Accessed April 30, 2026.

- [Android Auto Backup developer docs](https://developer.android.com/identity/data/autobackup)
- [Drift database import/export examples](https://drift.simonbinder.eu/examples/existing_databases/)
- [Flutter offline-first sync with Drift (Medium, Nov 2025)](https://777genius.medium.com/building-offline-first-flutter-apps-a-complete-sync-solution-with-drift-d287da021ab0)
- [Flutter offline-first architecture Part 1](https://dev.to/anurag_dev/implementing-offline-first-architecture-in-flutter-part-1-local-storage-with-conflict-resolution-4mdl)
- [SyncLayer Flutter package](https://pub.dev/packages/synclayer)
- [Flutter + PowerSync local-first (May 2025)](https://codewithandrea.com/newsletter/may-2025/)
