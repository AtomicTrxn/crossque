import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';

/// Result of importing and persisting a puzzle file.
sealed class ImportJobResult {
  const ImportJobResult();

  const factory ImportJobResult.success(Puzzle puzzle) = JobSuccess;
  const factory ImportJobResult.duplicate() = JobDuplicate;
  const factory ImportJobResult.failure(ParseError error) = JobFailure;
}

final class JobSuccess extends ImportJobResult {
  const JobSuccess(this.puzzle);

  final Puzzle puzzle;
}

final class JobDuplicate extends ImportJobResult {
  const JobDuplicate();
}

final class JobFailure extends ImportJobResult {
  const JobFailure(this.error);

  final ParseError error;
}
