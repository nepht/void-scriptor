import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/bootstrap/bootstrap_gate.dart';
import 'package:void_scriptor/app/bootstrap/startup_recovery_policy.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('RecoveryShell', () {
    testWidgets('safe mode renders its label', (tester) async {
      await tester.pumpWidget(
        _wrap(const RecoveryShell(mode: StartupMode.safe)),
      );
      expect(find.text('Safe Mode'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('recovery mode renders its label', (tester) async {
      await tester.pumpWidget(
        _wrap(const RecoveryShell(mode: StartupMode.recovery)),
      );
      expect(find.text('Recovery Mode'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the failure count it was given', (tester) async {
      await tester.pumpWidget(
        _wrap(const RecoveryShell(mode: StartupMode.safe, failureCount: 3)),
      );
      expect(find.textContaining('3'), findsAtLeastNWidgets(1));
    });

    testWidgets('retry button fires the callback', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _wrap(
          RecoveryShell(mode: StartupMode.safe, onRetry: () => retried = true),
        ),
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('reset configuration appears only in recovery mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(RecoveryShell(mode: StartupMode.safe, onResetConfig: () {})),
      );
      expect(find.text('Reset configuration'), findsNothing);

      await tester.pumpWidget(
        _wrap(RecoveryShell(mode: StartupMode.recovery, onResetConfig: () {})),
      );
      expect(find.text('Reset configuration'), findsOneWidget);
    });

    testWidgets('reset configuration fires the callback', (tester) async {
      var reset = false;
      await tester.pumpWidget(
        _wrap(
          RecoveryShell(
            mode: StartupMode.recovery,
            onResetConfig: () => reset = true,
          ),
        ),
      );
      await tester.tap(find.text('Reset configuration'));
      await tester.pump();
      expect(reset, isTrue);
    });

    testWidgets('diagnostics hint appears when suggested', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const RecoveryShell(
            mode: StartupMode.recovery,
            suggestDiagnostics: true,
          ),
        ),
      );
      expect(
        find.byKey(const Key('recovery-diagnostics-hint')),
        findsOneWidget,
      );
    });
  });

  group('BootstrapGate', () {
    const child = Key('normal-child');

    testWidgets('normal outcome renders the app child untouched', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BootstrapGate(
            outcome: StartupRecoveryOutcome(
              mode: StartupMode.normal,
              failureCountAfterDecision: 1,
            ),
            child: SizedBox(key: child),
          ),
        ),
      );
      expect(find.byKey(child), findsOneWidget);
      expect(find.byType(RecoveryShell), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('safe outcome swaps the app for the recovery shell', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BootstrapGate(
            outcome: StartupRecoveryOutcome(
              mode: StartupMode.safe,
              failureCountAfterDecision: 2,
            ),
            child: SizedBox(key: child),
          ),
        ),
      );
      expect(find.byType(RecoveryShell), findsOneWidget);
      expect(find.byKey(child), findsNothing);
      expect(find.text('Safe Mode'), findsOneWidget);
    });

    testWidgets('recovery outcome surfaces count and diagnostics hint', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BootstrapGate(
            outcome: StartupRecoveryOutcome(
              mode: StartupMode.recovery,
              failureCountAfterDecision: 4,
              suggestDiagnostics: true,
            ),
            child: SizedBox(key: child),
          ),
        ),
      );
      expect(find.text('Recovery Mode'), findsOneWidget);
      expect(find.textContaining('4'), findsAtLeastNWidgets(1));
      expect(
        find.byKey(const Key('recovery-diagnostics-hint')),
        findsOneWidget,
      );
    });
  });
}
