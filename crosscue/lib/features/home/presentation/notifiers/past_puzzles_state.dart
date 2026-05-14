import 'package:crosscue/features/home/domain/models/past_puzzle_item.dart';

/// State held by [PastPuzzlesNotifier].
///
/// Plain Dart (not Freezed) because we need a mutable-feeling `copyWith` over
/// a list + several flags and the AsyncValue wrapper supplies loading/error
/// variants for the initial load. Mid-stream errors (failed `loadMore` /
/// failed per-row download) ride along in [loadMoreError] / [downloadErrors]
/// so the list itself stays visible.
class PastPuzzlesState {
  const PastPuzzlesState({
    required this.items,
    required this.oldestMonthFetched,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.downloadingIds = const <String>{},
    this.downloadErrors = const <String, String>{},
  });

  /// Items in display order (most recent date first). Excludes today and any
  /// future-dated scheduled puzzles.
  final List<PastPuzzleItem> items;

  /// Encoded as `year * 12 + (month - 1)`. -1 means "nothing fetched yet".
  /// Used as a cursor when walking backward via [loadMore].
  final int oldestMonthFetched;

  /// `false` once we've walked past the Crosshare archive start (April 2020)
  /// or otherwise confirmed no earlier months are available.
  final bool hasMore;

  /// True while a [loadMore] call is in flight.
  final bool isLoadingMore;

  /// Set when the most recent [loadMore] call failed. Cleared on the next
  /// successful fetch or retry.
  final String? loadMoreError;

  /// Crosshare IDs currently being downloaded (one row → one entry).
  final Set<String> downloadingIds;

  /// Crosshare ID → error message for downloads that have failed since the
  /// last successful attempt for that row.
  final Map<String, String> downloadErrors;

  PastPuzzlesState copyWith({
    List<PastPuzzleItem>? items,
    int? oldestMonthFetched,
    bool? hasMore,
    bool? isLoadingMore,
    Object? loadMoreError = _sentinel,
    Set<String>? downloadingIds,
    Map<String, String>? downloadErrors,
  }) {
    return PastPuzzlesState(
      items: items ?? this.items,
      oldestMonthFetched: oldestMonthFetched ?? this.oldestMonthFetched,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: identical(loadMoreError, _sentinel)
          ? this.loadMoreError
          : loadMoreError as String?,
      downloadingIds: downloadingIds ?? this.downloadingIds,
      downloadErrors: downloadErrors ?? this.downloadErrors,
    );
  }

  static const _sentinel = Object();
}
