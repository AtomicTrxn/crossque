import 'package:crosscue/features/archive/domain/models/archive_entry.dart';

/// Abstract contract for the archive data layer.
abstract class ArchiveRepository {
  /// Returns all puzzles merged with their latest session status,
  /// ordered by import date descending.
  Future<List<ArchiveEntry>> getArchiveEntries();

  /// Watches all archive rows and emits whenever puzzles, sessions, or cell
  /// progress change.
  Stream<List<ArchiveEntry>> watchArchiveEntries();

  /// Permanently deletes [puzzleId] and all dependent rows
  /// (clues, sessions, cell_progress) via the DB cascade rule.
  Future<void> deletePuzzle(String puzzleId);
}
