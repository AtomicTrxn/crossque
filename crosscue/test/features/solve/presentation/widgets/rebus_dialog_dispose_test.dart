// Regression tests for #105 — the rebus dialog's TextEditingController
// used to be created at the call-site and disposed immediately after
// showDialog's Future resolved. That tripped Flutter's
// `_dependents.isEmpty` framework assertion: with `barrierDismissible:
// true`, the route pops asynchronously, and the TextField subtree was
// still in the tree (mid-pop animation) when the outer dispose() ran.
//
// Fix: `RebusDialog` is now a StatefulWidget that owns the controller
// in its own State. The controller's lifetime matches the widget tree,
// so dispose() runs at the right moment (after the route unmounts) and
// the framework no longer sees dangling dependents.
//
// These tests open the real `RebusDialog` via `showDialog`, dismiss it
// every way the production code allows (Enter, Cancel, barrier tap,
// system back), and assert that no Flutter error surfaces. The
// recorded text / outcome from each path is also verified to catch
// regressions in the "save what you typed on barrier tap" behavior.

import 'package:crosscue/features/solve/presentation/widgets/crossword_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RebusDialog — #105 regression', () {
    /// Pumps a host scaffold with a button that opens the real
    /// `RebusDialog`, taps it, then runs the supplied [dismiss] callback.
    ///
    /// Returns the outcome the dialog popped with, plus the last
    /// `onTextChanged` value observed (which is what the production
    /// caller uses on the barrier-dismiss path).
    Future<({RebusOutcome? outcome, String latestText})> openAndDismiss(
      WidgetTester tester, {
      required Future<void> Function(WidgetTester) dismiss,
      String initialText = 'A',
    }) async {
      RebusOutcome? popped;
      var latestText = initialText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  popped = await showDialog<RebusOutcome>(
                    context: ctx,
                    barrierDismissible: true,
                    builder: (_) => RebusDialog(
                      initialText: initialText,
                      onTextChanged: (text) => latestText = text,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await dismiss(tester);
      await tester.pumpAndSettle();

      // The actual #105 regression check: no framework error fired
      // during dismissal.
      expect(
        tester.takeException(),
        isNull,
        reason: 'RebusDialog dismissal must not surface a framework '
            'exception (regression for #105 _dependents.isEmpty).',
      );
      expect(find.byType(AlertDialog), findsNothing);

      return (outcome: popped, latestText: latestText);
    }

    testWidgets('Enter button pops with the typed text', (tester) async {
      final r = await openAndDismiss(
        tester,
        dismiss: (t) async {
          await t.enterText(find.byType(TextField), 'EST');
          await t.tap(find.text('Enter'));
        },
      );
      expect(r.outcome, isA<RebusOutcomeEntered>());
      expect((r.outcome! as RebusOutcomeEntered).text, equals('EST'));
    });

    testWidgets('Cancel button pops with the cancelled sentinel',
        (tester) async {
      final r = await openAndDismiss(
        tester,
        dismiss: (t) async {
          await t.enterText(find.byType(TextField), 'IGNORED');
          await t.tap(find.text('Cancel'));
        },
      );
      expect(r.outcome, isA<RebusOutcomeCancelled>());
    });

    testWidgets('barrier tap pops with null AND the last text was emitted',
        (tester) async {
      final r = await openAndDismiss(
        tester,
        dismiss: (t) async {
          await t.enterText(find.byType(TextField), 'EST');
          // Top-left of the screen is well outside the centered AlertDialog
          // and inside the ModalBarrier hit area.
          await t.tapAt(const Offset(10, 10));
        },
      );
      // Barrier dismiss: outer code reads latestText, not the outcome.
      expect(r.outcome, isNull);
      expect(r.latestText, equals('EST'));
    });

    testWidgets('barrier tap with no edits still has the prefilled text',
        (tester) async {
      final r = await openAndDismiss(
        tester,
        initialText: 'A',
        dismiss: (t) async => t.tapAt(const Offset(10, 10)),
      );
      expect(r.outcome, isNull);
      expect(r.latestText, equals('A'));
    });

    testWidgets('system back pops cleanly with null', (tester) async {
      final r = await openAndDismiss(
        tester,
        dismiss: (t) async {
          final navigator =
              t.state<NavigatorState>(find.byType(Navigator).last);
          navigator.pop();
        },
      );
      // pop() with no argument — same shape as barrier dismiss.
      expect(r.outcome, isNull);
    });

    testWidgets('Enter key submission pops with the typed text',
        (tester) async {
      final r = await openAndDismiss(
        tester,
        dismiss: (t) async {
          await t.enterText(find.byType(TextField), 'EST');
          await t.testTextInput.receiveAction(TextInputAction.done);
        },
      );
      expect(r.outcome, isA<RebusOutcomeEntered>());
      expect((r.outcome! as RebusOutcomeEntered).text, equals('EST'));
    });
  });
}
