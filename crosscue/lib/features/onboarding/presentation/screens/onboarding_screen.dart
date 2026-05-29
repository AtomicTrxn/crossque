import 'dart:async';

import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/features/import/presentation/notifiers/crosshare_notifier.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'onboarding_widgets.dart';

// ---------------------------------------------------------------------------
// First-run onboarding (v3.6) — a 3-step sync-setup flow whose only job is to
// get the player a puzzle and into solving as fast as possible:
//
//   0. Welcome      — brand + value prop.
//   1. Source       — pick Crosshare daily sync and/or local import.
//   2. Fetch/result — download today's mini and drop straight into solving.
//
// The crossword *tutorial* ("how to play") now lives in Settings → Help, not
// here. Completion is gated by hasSeenOnboarding, identical to before.
// ---------------------------------------------------------------------------

enum _OnbStep { welcome, source, fetch }

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _OnbStep _step = _OnbStep.welcome;
  bool _wantCrosshare = false;
  bool _wantImport = false;

  bool get _canContinue => _wantCrosshare || _wantImport;

  void _goToSource() => setState(() => _step = _OnbStep.source);

  Future<void> _onContinue() async {
    if (!_canContinue) return;
    if (_wantCrosshare) {
      // Persist the preference now; the fetch step drives the visible download
      // itself so we don't double-fetch via the auto-download service.
      await ref.read(crosshareAutoDownloadProvider.notifier).enable();
    }
    if (!mounted) return;
    setState(() => _step = _OnbStep.fetch);
    if (_wantCrosshare) {
      unawaited(ref.read(crosshareProvider.notifier).download());
    }
  }

  void _retry() => unawaited(ref.read(crosshareProvider.notifier).download());

  Future<void> _markSeen() =>
      ref.read(hasSeenOnboardingProvider.notifier).markSeen();

  Future<void> _finishToHome() async {
    final nav = GoRouter.of(context);
    await _markSeen();
    if (mounted) nav.go(Routes.home);
  }

  Future<void> _finishToSolve(String puzzleId) async {
    final nav = GoRouter.of(context);
    await _markSeen();
    if (!mounted) return;
    // Land Today under the puzzle so backing out of solving returns home,
    // mirroring how the Today screen opens puzzles.
    nav.go(Routes.home);
    unawaited(nav.push(Routes.solveFor(Uri.encodeComponent(puzzleId))));
  }

  Future<void> _finishToImport() async {
    final nav = GoRouter.of(context);
    await _markSeen();
    if (!mounted) return;
    nav.go(Routes.home);
    unawaited(nav.push(Routes.import_));
  }

  void _openHowToPlay() => context.push(Routes.howToPlay);

  @override
  Widget build(BuildContext context) {
    // Watch unconditionally (not just on the fetch step) so the autoDispose
    // crosshareProvider has a live listener before _onContinue kicks off
    // download(). Otherwise the notifier we read to start the download is
    // disposed for lack of watchers, and the fetch step rebuilds against a
    // fresh idle instance that never updates — leaving the spinner stuck.
    final crosshareState = ref.watch(crosshareProvider);

    final child = switch (_step) {
      _OnbStep.welcome => _WelcomeView(
          key: const ValueKey('welcome'),
          onGetStarted: _goToSource,
          onHowToPlay: _openHowToPlay,
        ),
      _OnbStep.source => _SourceChoiceView(
          key: const ValueKey('source'),
          wantCrosshare: _wantCrosshare,
          wantImport: _wantImport,
          onToggleCrosshare: () =>
              setState(() => _wantCrosshare = !_wantCrosshare),
          onToggleImport: () => setState(() => _wantImport = !_wantImport),
          canContinue: _canContinue,
          onContinue: _onContinue,
          onLater: _finishToHome,
          onHowToPlay: _openHowToPlay,
        ),
      _OnbStep.fetch => _FetchView(
          key: const ValueKey('fetch'),
          wantCrosshare: _wantCrosshare,
          wantImport: _wantImport,
          state: crosshareState,
          onStartSolving: _finishToSolve,
          onGoToday: _finishToHome,
          onRetry: _retry,
          onChooseFile: _finishToImport,
          onLater: _finishToHome,
        ),
    };

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: child,
      ),
    );
  }
}
