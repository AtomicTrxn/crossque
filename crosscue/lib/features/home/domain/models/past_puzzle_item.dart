import 'package:crosscue/features/import/domain/models/crosshare_entry.dart';

/// A single row in the "Past puzzles" section on the Today screen.
///
/// Pairs a Crosshare archive [entry] with its local-DB import status so the
/// UI can render either a `Solve`/`Review` action (already imported) or a
/// `Download` action (not yet imported).
class PastPuzzleItem {
  const PastPuzzleItem({required this.entry, this.localPuzzleId});

  final CrosshareEntry entry;

  /// Local DB puzzle ID if this Crosshare entry has already been imported.
  /// Non-null implies "already in archive, tap to solve/review".
  final String? localPuzzleId;

  bool get isImported => localPuzzleId != null;

  PastPuzzleItem copyWith({String? localPuzzleId}) {
    return PastPuzzleItem(
      entry: entry,
      localPuzzleId: localPuzzleId ?? this.localPuzzleId,
    );
  }
}
