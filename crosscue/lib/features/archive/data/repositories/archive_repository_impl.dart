import 'dart:async';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/features/archive/domain/models/archive_entry.dart';
import 'package:crosscue/features/archive/domain/repositories/archive_repository.dart';
import 'package:crosscue/features/import/data/daos/puzzle_dao.dart';
import 'package:crosscue/features/solve/data/daos/solve_session_dao.dart';

/// Provides the Archive screen's data by combining [PuzzleDao] metadata with
/// the latest [SolveSessionRow] for each puzzle.
///
/// Reads the whole list in three bounded queries regardless of library size
/// (metadata, latest-session-per-puzzle, filled-cell-counts-per-session) and
/// computes the completion fraction from the denormalized
/// `puzzles.fillable_cell_count` — no per-puzzle grid JSON decode. See
/// issue #121.
class ArchiveRepositoryImpl implements ArchiveRepository {
  const ArchiveRepositoryImpl({
    required this.puzzleDao,
    required this.sessionDao,
  });

  final PuzzleDao puzzleDao;
  final SolveSessionDao sessionDao;

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns all puzzles merged with their latest session status, ordered by
  /// import date descending (most recent first).
  ///
  /// Three queries total — `getAllMetadata`, `latestSessionByPuzzle`, and
  /// `filledCellCountsBySession` — then assembled in memory. No N+1, no grid
  /// decode.
  @override
  Future<List<ArchiveEntry>> getArchiveEntries() async {
    final allPuzzles = await puzzleDao.getAllMetadata();
    if (allPuzzles.isEmpty) return const [];

    final latestByPuzzle = await sessionDao.latestSessionByPuzzle();
    final filledBySession = await sessionDao.filledCellCountsBySession();

    return [
      for (final puzzle in allPuzzles)
        _buildEntry(
          puzzle,
          latestByPuzzle[puzzle.id],
          _completionFraction(
            puzzle: puzzle,
            session: latestByPuzzle[puzzle.id],
            filledBySession: filledBySession,
          ),
        ),
    ];
  }

  @override
  Stream<List<ArchiveEntry>> watchArchiveEntries() {
    late final StreamController<List<ArchiveEntry>> controller;
    final subscriptions = <StreamSubscription<Object?>>[];
    var emitQueued = false;
    var disposed = false;

    Future<void> emit() async {
      if (disposed || controller.isClosed) return;
      try {
        controller.add(await getArchiveEntries());
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      }
    }

    void queueEmit() {
      if (emitQueued || disposed) return;
      emitQueued = true;
      scheduleMicrotask(() {
        emitQueued = false;
        unawaited(emit());
      });
    }

    controller = StreamController<List<ArchiveEntry>>(
      onListen: () {
        // A cell-progress write during an active solve (every ~500ms while
        // typing) fans into a single coalesced re-emit. Pre-#121 that re-emit
        // ran an N+1 with a full grid JSON decode per puzzle; it is now three
        // bounded aggregate queries (metadata + latest-session-per-puzzle +
        // filled-counts-per-session) regardless of library size, so the
        // simple "recompute the whole list" fan-in is cheap enough to keep.
        subscriptions
          ..add(puzzleDao.watchAllMetadata().listen((_) => queueEmit()))
          ..add(sessionDao.watchAllSessions().listen((_) => queueEmit()))
          ..add(sessionDao.watchAllCellProgress().listen((_) => queueEmit()));
        queueEmit();
      },
      onCancel: () async {
        disposed = true;
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );

    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Deletes [puzzleId] and all dependent rows (clues, sessions, cell_progress)
  /// via the cascade rule defined in the DB schema.
  @override
  Future<void> deletePuzzle(String puzzleId) =>
      puzzleDao.deletePuzzle(puzzleId);

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  ArchiveEntry _buildEntry(
    PuzzleMetadata puzzle,
    SolveSessionRow? session,
    double completionFraction,
  ) {
    if (session == null) {
      return ArchiveEntry(
        puzzleId: puzzle.id,
        title: puzzle.title,
        author: puzzle.author,
        width: puzzle.width,
        height: puzzle.height,
        importedAt: puzzle.importedAt,
        publishDate: puzzle.publishDate,
        sessionStatus: 'not_started',
        completionFraction: completionFraction,
      );
    }
    return ArchiveEntry(
      puzzleId: puzzle.id,
      title: puzzle.title,
      author: puzzle.author,
      width: puzzle.width,
      height: puzzle.height,
      importedAt: puzzle.importedAt,
      publishDate: puzzle.publishDate,
      sessionId: session.id,
      sessionStatus: session.status,
      completionType: session.completionType,
      elapsedMs: session.elapsedMs,
      completedAt: session.completedAt,
      lastPlayedAt: session.lastPlayedAt,
      completionFraction: completionFraction,
    );
  }

  /// Completion fraction for the latest session of [puzzle].
  ///
  ///   – No session            → 0
  ///   – completed / revealed  → 1
  ///   – in-progress           → filled cells / fillable cells
  ///
  /// `fillable` comes from the denormalized `puzzles.fillable_cell_count`
  /// (in [PuzzleMetadata]); `filled` comes from the per-session non-null
  /// `guess` count. Neither requires decoding the puzzle's grid JSON.
  ///
  /// A `fillableCellCount` of 0 — only possible for a row whose
  /// `canonical_json` failed to parse during the v5 → v6 backfill — yields a
  /// 0 fraction rather than a divide-by-zero, matching the old behaviour for
  /// an unreadable puzzle.
  double _completionFraction({
    required PuzzleMetadata puzzle,
    required SolveSessionRow? session,
    required Map<int, int> filledBySession,
  }) {
    if (session == null) return 0;
    if (session.status == 'completed' || session.status == 'revealed') {
      return 1;
    }
    final fillable = puzzle.fillableCellCount;
    if (fillable <= 0) return 0;
    final filled = filledBySession[session.id] ?? 0;
    return (filled / fillable).clamp(0.0, 1.0);
  }
}
