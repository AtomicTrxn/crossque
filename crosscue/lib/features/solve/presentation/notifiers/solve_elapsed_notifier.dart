import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'solve_elapsed_notifier.g.dart';

/// Live, per-second elapsed clock for the solve screen, scoped to one
/// puzzle.
///
/// **Why this exists.** Before this provider, `SolveNotifier`'s state
/// included `elapsedSeconds` and incremented it once per second via
/// `state = AsyncData(s.copyWith(elapsedSeconds: s.elapsedSeconds + 1))`.
/// `SolveScreen.build` watches `solveProvider(...)`, so every tick
/// invalidated the entire screen: `CrosswordGrid`, `CluePanel`,
/// `CrosswordKeyboard`, the confetti widget, and the outer `LayoutBuilder`
/// all rebuilt every second on idle. `CustomPainter.shouldRepaint`
/// suppressed the actual paint, but the Element-tree rebuild and
/// `LayoutBuilder` re-measurement still ran every second — frame-budget
/// tax on lower-end Android devices for nothing user-visible except the
/// AppBar's seconds digit.
///
/// This provider holds the ticking value in isolation. `SolveAppBar` is
/// the only widget that watches it; everything else continues to watch
/// `solveProvider(...)` and rebuilds only on real state changes
/// (focus, progress, status). `SolveNotifier` still owns the canonical
/// elapsed-seconds for persistence — it reads from this provider when
/// it needs to save or persist a completion — but does not broadcast
/// per-tick state to its own watchers.
///
/// See issue #119.
@riverpod
class SolveElapsedSeconds extends _$SolveElapsedSeconds {
  Timer? _timer;

  @override
  int build(String puzzleId) {
    ref.onDispose(() => _timer?.cancel());
    return 0;
  }

  /// Sets the elapsed-second counter to [seconds] without changing the
  /// running/paused state. Used on session resume to restore the
  /// previously persisted value before [start] kicks off ticking.
  void seed(int seconds) {
    state = seconds;
  }

  /// Begins ticking from the current value. Safe to call when already
  /// running — the previous timer is cancelled first.
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state + 1;
    });
  }

  /// Stops ticking. The current value is preserved so [start] can
  /// resume from where the clock left off (used by pause and by the
  /// terminal-completion path).
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Cancels any running timer and resets the counter to zero. Used by
  /// "Reset puzzle" — the caller is expected to follow with [start].
  void reset() {
    _timer?.cancel();
    _timer = null;
    state = 0;
  }
}
