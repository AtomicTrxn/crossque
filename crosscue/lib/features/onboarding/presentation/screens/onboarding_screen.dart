import 'dart:async';

import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/crossword_theme.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'onboarding_widgets.dart';

// ---------------------------------------------------------------------------
// Mock 5×5 grid data (hardcoded, never stored in Drift)
// Spec grid (design/README.md §07):
//   Row 0: A  C  E  .  .    (. = black)
//   Row 1: L  O  .  T  E
//   Row 2: .  N  D  .  .
//   Row 3: G  E  .  P  S
//   Row 4: .  R  Y  E  .
// ---------------------------------------------------------------------------

/// Each cell: null = black, String = solution letter.
const _grid = [
  ['A', 'C', 'E', null, null],
  ['L', 'O', null, 'T', 'E'],
  [null, 'N', 'D', null, null],
  ['G', 'E', null, 'P', 'S'],
  [null, 'R', 'Y', 'E', null],
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0; // 0,1,2 = tutorial steps; 3 = done card
  // Start with cell (1,1) pre-focused (active cell = "O")
  int? _focusRow = 1;
  int? _focusCol = 1;
  bool _focusIsAcross = true;
  bool _step1Done = false;
  bool _step2Done = false;
  Timer? _step3Timer;

  @override
  void dispose() {
    _step3Timer?.cancel();
    super.dispose();
  }

  Future<void> _complete() async {
    await ref.read(appSettingsProvider).setHasSeenOnboarding(true);
    ref.invalidate(hasSeenOnboardingProvider);
  }

  void _onCellTap(int row, int col) {
    if (_grid[row][col] == null) return;

    setState(() {
      if (_step == 0) {
        _focusRow = row;
        _focusCol = col;
        _focusIsAcross = true;
        // Step 1 completes when user taps a cell — but we wait for a letter
      } else if (_step == 1) {
        if (_focusRow == row && _focusCol == col) {
          _focusIsAcross = !_focusIsAcross;
          if (!_step2Done) {
            _step2Done = true;
          }
        } else {
          _focusRow = row;
          _focusCol = col;
        }
      }
    });
  }

  void _onLetterTap(String letter) {
    if (_step == 0 && _focusRow != null && !_step1Done) {
      setState(() => _step1Done = true);
    }
  }

  void _nextStep() {
    if (_step == 2) {
      // Start 3-second auto-advance or user tapped Next
      setState(() => _step = 3);
      return;
    }
    if (_step == 3) return;
    setState(() {
      _step++;
      if (_step == 2) {
        // Auto-advance step 3 after 3 s
        _step3Timer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _step = 3);
        });
      }
    });
  }

  void _skip() async {
    final nav = GoRouter.of(context);
    await _complete();
    if (mounted) nav.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrosscueColors.deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CrosscueSpacing.screenH,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60),
                  if (_step < 3) _StepDots(current: _step, total: 3),
                  // White translucent text on navy background
                  TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.65),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  CrosscueSpacing.screenH,
                  24,
                  CrosscueSpacing.screenH,
                  16,
                ),
                child: _MockGrid(
                  focusRow: _focusRow,
                  focusCol: _focusCol,
                  focusIsAcross: _focusIsAcross,
                  onCellTap: _onCellTap,
                ),
              ),
            ),
            _InstructionCard(
              step: _step,
              step1Done: _step1Done,
              step2Done: _step2Done,
              onNext: _nextStep,
              onLetter: _onLetterTap,
              onImport: () async {
                final nav = GoRouter.of(context);
                await _complete();
                if (mounted) nav.go(Routes.import_);
              },
              onLater: () async {
                final nav = GoRouter.of(context);
                await _complete();
                if (mounted) nav.go(Routes.home);
              },
            ),
          ],
        ),
      ),
    );
  }
}
