import 'package:crosscue/core/theme/crossword_theme.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:flutter/material.dart';

part 'how_to_play_widgets.dart';

// ---------------------------------------------------------------------------
// "How to play" — the interactive crossword tutorial. Lives in Settings → Help
// (v3.6). Previously this was the first-run onboarding; first-run is now the
// sync-setup flow in features/onboarding. This screen is pushed over the shell
// and finishes by popping back to Settings — it never touches hasSeenOnboarding.
// ---------------------------------------------------------------------------

// Mock 5×5 grid data (hardcoded, never stored in Drift).
// null = black cell; string = solution letter for the typing demo in step 1.
const _grid = <List<String?>>[
  ['A', 'C', 'E', null, null],
  ['L', 'O', null, 'T', 'E'],
  [null, 'N', 'D', null, null],
  ['G', 'E', null, 'P', 'S'],
  [null, 'R', 'Y', 'E', null],
];

const _focusStart = (0, 0);
const _step1MinLettersToAdvance = 2;

class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  int _step = 0; // 0,1,2,3 = tutorial steps (step 3 is the "add puzzles" copy)
  int? _focusRow = _focusStart.$1;
  int? _focusCol = _focusStart.$2;
  bool _focusIsAcross = true;
  final Map<(int, int), String> _typed = {};
  bool _step2Done = false;
  bool _step3Done = false;

  bool get _step1Done => _typed.length >= _step1MinLettersToAdvance;

  void _markStep3Done() {
    if (_step3Done) return;
    setState(() => _step3Done = true);
  }

  void _finish() => Navigator.of(context).pop();

  void _onCellTap(int row, int col) {
    if (_grid[row][col] == null) return;
    setState(() {
      if (_step == 1 && _focusRow == row && _focusCol == col) {
        _focusIsAcross = !_focusIsAcross;
        _step2Done = true;
      } else {
        _focusRow = row;
        _focusCol = col;
      }
    });
  }

  void _onLetterTap(String letter) {
    if (_step != 0) return;
    final r = _focusRow;
    final c = _focusCol;
    if (r == null || c == null) return;
    if (_grid[r][c] == null) return;

    setState(() {
      _typed[(r, c)] = letter.toUpperCase();
      final next = _nextEmptyInWord(r, c);
      if (next != null) {
        _focusRow = next.$1;
        _focusCol = next.$2;
      }
    });
  }

  /// Walks forward through the active word from (r,c) looking for an empty
  /// cell. Returns null if the word is fully typed.
  (int, int)? _nextEmptyInWord(int r, int c) {
    if (_focusIsAcross) {
      for (var nc = c + 1; nc < 5 && _grid[r][nc] != null; nc++) {
        if (!_typed.containsKey((r, nc))) return (r, nc);
      }
    } else {
      for (var nr = r + 1; nr < 5 && _grid[nr][c] != null; nr++) {
        if (!_typed.containsKey((nr, c))) return (nr, c);
      }
    }
    return null;
  }

  void _nextStep() {
    if (_step >= 3) {
      _finish();
      return;
    }
    setState(() {
      _step++;
      // Reset focus when entering step 2 (direction toggle) so the target
      // cell is unambiguous.
      if (_step == 1) {
        _focusRow = _focusStart.$1;
        _focusCol = _focusStart.$2;
        _focusIsAcross = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fixed onboardingBackground navy, theme-independent so the tutorial
      // reads consistently regardless of system light/dark.
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: CrosscueColors.onboardingBackground,
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _GridWatermark()),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TopBar(
                    showDots: _step < 4,
                    step: _step,
                    onSkip: _finish,
                  ),
                  // Mini "AppBar" mirroring the real solve screen — title,
                  // timer, and ⋮ menu. The menu is interactive in every step;
                  // tapping it in step 3 marks the step complete. Hidden on
                  // step 4 (which is about the Today screen, not solving).
                  if (_step < 3)
                    _MockTopBar(onMenuOpened: _markStep3Done)
                  else
                    const SizedBox(height: 48),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        CrosscueSpacing.screenH,
                        12,
                        CrosscueSpacing.screenH,
                        12,
                      ),
                      child: _step < 3
                          ? _MockGrid(
                              focusRow: _focusRow,
                              focusCol: _focusCol,
                              focusIsAcross: _focusIsAcross,
                              typed: _typed,
                              onCellTap: _onCellTap,
                            )
                          : const _AddPuzzleIllustration(),
                    ),
                  ),
                  _InstructionCard(
                    step: _step,
                    step1Done: _step1Done,
                    step2Done: _step2Done,
                    step3Done: _step3Done,
                    onNext: _nextStep,
                    onLetter: _onLetterTap,
                    onDone: _finish,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
