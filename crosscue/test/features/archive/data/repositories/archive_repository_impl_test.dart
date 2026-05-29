// Tests for ArchiveRepositoryImpl — the batch-query rewrite (#121).
//
// Verifies that the Archive list is assembled from the denormalized
// `puzzles.fillable_cell_count` plus per-session filled-cell counts, without
// loading or JSON-decoding the puzzle grid. Uses a real in-memory Drift DB
// seeded through the production import path so `fillable_cell_count` is
// populated exactly as it is in the app.

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/features/archive/data/repositories/archive_repository_impl.dart';
import 'package:crosscue/features/import/data/repositories/import_repository_impl.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/puz_fixture_builder.dart';

void main() {
  late AppDatabase db;
  late ArchiveRepositoryImpl repo;
  late ImportRepositoryImpl importRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ArchiveRepositoryImpl(
      puzzleDao: db.puzzleDao,
      sessionDao: db.solveSessionDao,
    );
    importRepo = ImportRepositoryImpl(dao: db.puzzleDao);
  });
  tearDown(() => db.close());

  /// Seeds the standard 3×3 all-white fixture (9 fillable cells) and returns
  /// its puzzle id.
  Future<String> seedPuzzle() async {
    final result = await importRepo.importBytes(PuzFixtureBuilder.minimal3x3());
    return (result as JobSuccess).puzzle.id;
  }

  Future<int> insertSession({
    required String puzzleId,
    required String status,
    required DateTime at,
  }) {
    return db.into(db.solveSessionsTable).insert(
          SolveSessionsTableCompanion.insert(
            puzzleId: puzzleId,
            deviceId: 'local',
            status: Value(status),
            startedAt: at,
            lastPlayedAt: at,
            createdAt: at,
            updatedAt: at,
          ),
        );
  }

  test('not-started puzzle → fraction 0, status not_started', () async {
    final id = await seedPuzzle();

    final entries = await repo.getArchiveEntries();

    expect(entries, hasLength(1));
    final entry = entries.single;
    expect(entry.puzzleId, id);
    expect(entry.isNotStarted, isTrue);
    expect(entry.completionFraction, 0);
  });

  test('in-progress fraction = filled / fillable (from denormalized count)',
      () async {
    final id = await seedPuzzle(); // 3×3 → 9 fillable cells
    final sessionId = await db.solveSessionDao.createSession(id);

    // Fill the top row (3 of 9 cells). saveCellProgress stores a non-null
    // guess only for non-empty letters — exactly what the new fraction query
    // counts.
    final progress = Grid<CellProgress>.generate(3, 3, (r, c) {
      if (r == 0) {
        return const CellProgress(letter: 'A', state: CellState.filled);
      }
      return CellProgress.blank;
    });
    await db.solveSessionDao.saveCellProgress(sessionId, progress, 3, 3);

    final entry = (await repo.getArchiveEntries()).single;
    expect(entry.sessionId, sessionId);
    expect(entry.isInProgress, isTrue);
    expect(entry.completionFraction, closeTo(3 / 9, 1e-9));
  });

  test('completed session → fraction 1 regardless of filled cells', () async {
    final id = await seedPuzzle();
    final sessionId = await insertSession(
      puzzleId: id,
      status: 'completed',
      at: DateTime.utc(2026, 1, 1),
    );

    final entry = (await repo.getArchiveEntries()).single;
    expect(entry.sessionId, sessionId);
    expect(entry.isCompleted, isTrue);
    expect(entry.completionFraction, 1);
  });

  test('revealed session → fraction 1', () async {
    final id = await seedPuzzle();
    await insertSession(
      puzzleId: id,
      status: 'revealed',
      at: DateTime.utc(2026, 1, 1),
    );

    final entry = (await repo.getArchiveEntries()).single;
    expect(entry.isRevealed, isTrue);
    expect(entry.completionFraction, 1);
  });

  test('latest session (by lastPlayedAt) wins when a puzzle has several',
      () async {
    final id = await seedPuzzle();
    // Older in-progress session, then a newer completed one.
    await insertSession(
      puzzleId: id,
      status: 'in_progress',
      at: DateTime.utc(2026, 1, 1),
    );
    final newer = await insertSession(
      puzzleId: id,
      status: 'completed',
      at: DateTime.utc(2026, 2, 1),
    );

    final entry = (await repo.getArchiveEntries()).single;
    expect(entry.sessionId, newer);
    expect(entry.isCompleted, isTrue);
    expect(entry.completionFraction, 1);
  });

  test('empty library returns no entries', () async {
    expect(await repo.getArchiveEntries(), isEmpty);
  });

  test('multiple puzzles each resolve independently', () async {
    final a = await seedPuzzle(); // 'Test Puzzle'
    // A second, distinct puzzle — a different solution grid yields a
    // different checksum so the import isn't deduped against the first.
    final result = await importRepo.importBytes(
      PuzFixtureBuilder.build(
        width: 3,
        height: 3,
        grid: const ['XYZ', 'PQR', 'STU'],
        title: 'Second',
        clueTexts: const [
          '1-Across',
          '1-Down',
          '2-Down',
          '3-Down',
          '4-Across',
          '5-Across',
        ],
      ),
    );
    final b = (result as JobSuccess).puzzle.id;

    // Only puzzle B gets a completed session.
    await insertSession(
      puzzleId: b,
      status: 'completed',
      at: DateTime.utc(2026, 1, 1),
    );

    final entries = await repo.getArchiveEntries();
    final byId = {for (final e in entries) e.puzzleId: e};
    expect(byId.keys, containsAll(<String>[a, b]));
    expect(byId[a]!.isNotStarted, isTrue);
    expect(byId[a]!.completionFraction, 0);
    expect(byId[b]!.isCompleted, isTrue);
    expect(byId[b]!.completionFraction, 1);
  });
}
