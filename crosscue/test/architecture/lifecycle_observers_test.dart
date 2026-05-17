// Architectural guard test.
//
// The app intentionally registers exactly two lifecycle observers, with
// non-overlapping responsibilities:
//
//   1. `lib/app.dart`
//      — `_CrosshareLifecycleObserver` handles `resumed`
//        (retrigger Crosshare auto-download on foreground)
//
//   2. `lib/features/solve/presentation/screens/solve_screen.dart`
//      — `_SolveScreenState` mixes in `WidgetsBindingObserver` and handles
//        `paused` / `hidden` (auto-pause timer) and `detached` (flush save)
//
// Any other file in `lib/` that references the lifecycle observer surface
// is a policy violation: a third owner means two observers will both wake
// on every state change, and the ordering between them becomes load-bearing
// and easy to break.
//
// If you have a genuine third use case, either:
//   - extend one of the existing observers (preferred), or
//   - add the new file to [_allowedOwners] below with a comment explaining
//     why it cannot be folded into an existing observer
//
// See the doc comments on the two existing observers for the policy.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('only allowlisted files own a WidgetsBindingObserver', () {
    final libDir = Directory('lib');
    if (!libDir.existsSync()) {
      fail('Expected to run from the crosscue/ package root.');
    }

    // Patterns that indicate a file owns or registers a lifecycle observer.
    // We're not matching every possible reference — only the patterns that
    // mean "this file installs an observer," not "this file mentions one."
    final ownershipPatterns = <RegExp>[
      RegExp(r'\bextends\s+WidgetsBindingObserver\b'),
      RegExp(r'\bwith\s+WidgetsBindingObserver\b'),
      RegExp(r'\bextends\s+AppLifecycleListener\b'),
      RegExp(r'\bWidgetsBinding\.instance\.addObserver\b'),
      RegExp(r'\bdidChangeAppLifecycleState\b'),
    ];

    // Allowlist of files permitted to own a lifecycle observer.
    // Add to this list ONLY with a written justification in the diff —
    // see the file header for the policy.
    final allowedOwners = <String>{
      p.join('lib', 'app.dart'),
      p.join(
        'lib',
        'features',
        'solve',
        'presentation',
        'screens',
        'solve_screen.dart',
      ),
    };

    final offenders = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // Skip generated files (.g.dart, .freezed.dart) — they can't own
      // observers but might mention the symbols via reflection helpers.
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) {
        continue;
      }
      final relative = p.relative(entity.path);
      if (allowedOwners.contains(relative)) continue;

      final contents = entity.readAsStringSync();
      for (final pattern in ownershipPatterns) {
        if (pattern.hasMatch(contents)) {
          offenders.add('$relative — matched ${pattern.pattern}');
          break;
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Found files outside the allowlist that own a lifecycle observer.\n'
          'Policy: the app registers exactly two observers (app.dart and\n'
          'solve_screen.dart). See test/architecture/lifecycle_observers_test.dart\n'
          'for the rationale. If you have a genuine third use case, extend an\n'
          'existing observer or add the file to the allowlist with a written\n'
          'justification.\n\n'
          'Offenders:\n  ${offenders.join('\n  ')}',
    );
  });

  test('both allowlisted owners still register an observer', () {
    // Companion check: if we ever delete one of the two observers (e.g.
    // during a refactor) the allowlist becomes stale silently. This test
    // forces the allowlist to stay accurate.
    final required = {
      p.join('lib', 'app.dart'): RegExp(
        r'WidgetsBinding\.instance\.addObserver',
      ),
      p.join(
        'lib',
        'features',
        'solve',
        'presentation',
        'screens',
        'solve_screen.dart',
      ): RegExp(
        r'WidgetsBinding\.instance\.addObserver',
      ),
    };

    for (final entry in required.entries) {
      final file = File(entry.key);
      expect(
        file.existsSync(),
        isTrue,
        reason: '${entry.key} is in the lifecycle-observer allowlist but '
            'no longer exists. Update the allowlist.',
      );
      expect(
        entry.value.hasMatch(file.readAsStringSync()),
        isTrue,
        reason: '${entry.key} is in the allowlist but no longer registers a '
            'lifecycle observer. Remove it from the allowlist in '
            'test/architecture/lifecycle_observers_test.dart.',
      );
    }
  });
}
