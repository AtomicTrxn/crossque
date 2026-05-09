import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:crosscue/features/import/data/downloaders/crosshare_downloader.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';

part 'crosshare_notifier.g.dart';

// ---------------------------------------------------------------------------
// UI state
// ---------------------------------------------------------------------------

sealed class CrosshareState {
  const CrosshareState();
}

class CrosshareIdle extends CrosshareState {
  const CrosshareIdle();
}

class CrosshareDownloading extends CrosshareState {
  const CrosshareDownloading();
}

class CrosshareSuccess extends CrosshareState {
  const CrosshareSuccess(this.puzzleId, this.title);
  final String puzzleId;
  final String title;
}

class CrosshareDuplicate extends CrosshareState {
  const CrosshareDuplicate();
}

class CrosshareFailure extends CrosshareState {
  const CrosshareFailure(this.message);
  final String message;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

@riverpod
class CrosshareNotifier extends _$CrosshareNotifier {
  @override
  CrosshareState build() => const CrosshareIdle();

  Future<void> download() async {
    state = const CrosshareDownloading();

    // Step 1: fetch .puz bytes from Crosshare
    final downloader = ref.read(crosshareDownloaderProvider);
    final dlResult = await downloader.downloadToday();

    if (dlResult.isErr) {
      state = CrosshareFailure(_downloadErrorMessage(dlResult.error));
      return;
    }

    // Step 2: parse + persist via ImportRepository
    final repo = ref.read(importRepositoryProvider);
    final importResult = await repo.importBytes(dlResult.value);

    switch (importResult) {
      case JobSuccess(:final puzzle):
        state = CrosshareSuccess(puzzle.id, puzzle.metadata.title);
      case JobDuplicate():
        state = const CrosshareDuplicate();
      case JobFailure(:final error):
        state = CrosshareFailure(_parseErrorMessage(error));
    }
  }

  void reset() => state = const CrosshareIdle();

  String _downloadErrorMessage(CrosshareDownloadError error) {
    return switch (error) {
      CrosshareDownloadError.notFound =>
        "Today's puzzle isn't available yet. Try again later.",
      CrosshareDownloadError.networkError =>
        'Could not reach Crosshare. Check your connection and try again.',
    };
  }

  String _parseErrorMessage(ParseError error) {
    return switch (error) {
      ParseError.unsupportedFormat =>
        'The downloaded puzzle format is not supported.',
      ParseError.invalidFormat => 'The downloaded file appears to be invalid.',
      ParseError.missingData =>
        'The downloaded puzzle is incomplete or corrupted.',
      _ => 'Failed to import the downloaded puzzle.',
    };
  }
}
