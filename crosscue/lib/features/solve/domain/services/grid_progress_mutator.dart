import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/domain/models/check_result.dart';
import 'package:crosscue/features/solve/domain/services/clue_progress_calculator.dart';

class CheckMutation {
  const CheckMutation({
    required this.progress,
    required this.result,
  });

  final Grid<CellProgress> progress;
  final CheckResult result;
}

class GridProgressMutator {
  const GridProgressMutator._();

  static CheckMutation checkCells({
    required Puzzle puzzle,
    required Grid<CellProgress> progress,
    required Iterable<(int, int)> cells,
  }) {
    var updated = progress;
    var checkedAny = false;
    var hasIncorrect = false;

    for (final (row, col) in cells) {
      if (puzzle.grid.cell(row, col).isBlack) continue;
      final cell = updated.cell(row, col);
      if (cell.letter.isEmpty) continue;

      final correct = cell.letter.toUpperCase() ==
          puzzle.grid.cell(row, col).solution.toUpperCase();
      checkedAny = true;
      hasIncorrect = hasIncorrect || !correct;
      updated = updated.withCell(
        row,
        col,
        cell.copyWith(
          state:
              correct ? CellState.checkedCorrect : CellState.checkedIncorrect,
        ),
      );
    }

    if (!checkedAny) {
      return CheckMutation(progress: progress, result: CheckResult.noop);
    }
    return CheckMutation(
      progress: updated,
      result: hasIncorrect ? CheckResult.hasIncorrect : CheckResult.allCorrect,
    );
  }

  static Grid<CellProgress> revealCells({
    required Puzzle puzzle,
    required Grid<CellProgress> progress,
    required Iterable<(int, int)> cells,
  }) {
    var updated = progress;
    for (final (row, col) in cells) {
      if (puzzle.grid.cell(row, col).isBlack) continue;
      updated = updated.withCell(
        row,
        col,
        updated.cell(row, col).copyWith(
              letter: puzzle.grid.cell(row, col).solution,
              state: CellState.revealed,
            ),
      );
    }
    return updated;
  }

  static Iterable<(int, int)> clueCells(Clue clue) =>
      ClueProgressCalculator.cellsFor(clue);

  static Iterable<(int, int)> puzzleCells(Puzzle puzzle) sync* {
    for (var row = 0; row < puzzle.height; row++) {
      for (var col = 0; col < puzzle.width; col++) {
        yield (row, col);
      }
    }
  }
}
