import 'package:crosscue/features/solve/presentation/notifiers/solve_elapsed_notifier.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the standalone elapsed-seconds notifier introduced by #119.
///
/// The notifier owns the per-second tick in isolation from `SolveNotifier`
/// so that timer rebuilds do not invalidate the rest of the solve screen.
/// These tests cover the seed/start/stop/reset API and verify ticking.
///
/// The provider is auto-dispose (released when no listener / no ref keeps
/// it alive) which is the right default in production — `SolveAppBar` and
/// `SolveNotifier` each hold a reference for the lifetime of the puzzle.
/// In tests we attach a no-op `container.listen` to mimic that liveness.
void main() {
  group('SolveElapsedSeconds', () {
    test('seed sets the counter without starting the timer', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final provider = solveElapsedSecondsProvider('puzzle');
        container.listen(provider, (_, __) {});

        container.read(provider.notifier).seed(42);

        expect(container.read(provider), 42);

        // Without start(), the value must not advance.
        async.elapse(const Duration(seconds: 5));
        expect(container.read(provider), 42);
      });
    });

    test('start ticks once per second from the seeded value', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final provider = solveElapsedSecondsProvider('puzzle');
        container.listen(provider, (_, __) {});

        container.read(provider.notifier)
          ..seed(10)
          ..start();

        async.elapse(const Duration(seconds: 3));
        expect(container.read(provider), 13);
      });
    });

    test('stop halts ticking but preserves the current value', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final provider = solveElapsedSecondsProvider('puzzle');
        container.listen(provider, (_, __) {});

        container.read(provider.notifier).start();
        async.elapse(const Duration(seconds: 4));
        expect(container.read(provider), 4);

        container.read(provider.notifier).stop();
        async.elapse(const Duration(seconds: 10));
        expect(container.read(provider), 4);
      });
    });

    test('start after stop resumes from the preserved value', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final provider = solveElapsedSecondsProvider('puzzle');
        container.listen(provider, (_, __) {});

        container.read(provider.notifier).start();
        async.elapse(const Duration(seconds: 3));
        container.read(provider.notifier).stop();
        async.elapse(const Duration(seconds: 10));
        container.read(provider.notifier).start();
        async.elapse(const Duration(seconds: 2));

        expect(container.read(provider), 5);
      });
    });

    test('reset cancels the timer and zeroes the counter', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final provider = solveElapsedSecondsProvider('puzzle');
        container.listen(provider, (_, __) {});

        container.read(provider.notifier)
          ..seed(99)
          ..start();
        async.elapse(const Duration(seconds: 2));

        container.read(provider.notifier).reset();
        expect(container.read(provider), 0);

        // Reset must also cancel the running timer.
        async.elapse(const Duration(seconds: 5));
        expect(container.read(provider), 0);
      });
    });

    test('start while already running cancels the previous timer', () {
      // Calling start() multiple times in a row must not result in
      // faster-than-1-Hz ticking.
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final provider = solveElapsedSecondsProvider('puzzle');
        container.listen(provider, (_, __) {});

        container.read(provider.notifier)
          ..start()
          ..start()
          ..start();

        async.elapse(const Duration(seconds: 3));
        expect(container.read(provider), 3);
      });
    });

    test('families are independent per puzzleId', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final a = solveElapsedSecondsProvider('a');
        final b = solveElapsedSecondsProvider('b');
        container
          ..listen(a, (_, __) {})
          ..listen(b, (_, __) {});

        container.read(a.notifier)
          ..seed(10)
          ..start();
        container.read(b.notifier).seed(100);

        async.elapse(const Duration(seconds: 2));
        expect(container.read(a), 12);
        expect(container.read(b), 100);
      });
    });
  });
}
