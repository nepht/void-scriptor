import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/bootstrap/app_bootstrap.dart';

/// Regression guard for the Riverpod 2 -> 3 upgrade (major).
///
/// Riverpod 3 introduced automatic provider retry: a failed provider is
/// re-run with exponential backoff (up to 10 attempts by default). Void
/// Scriptor renders its own error surfaces -- sidebar/catalog error rows with
/// a manual Retry action, plus SectionErrorBoundary -- so auto-retry makes
/// those rows flash and vanish, which is exactly the silent masking the rows
/// exist to prevent, and leaves the manual Retry button useless.
///
/// Riverpod 2 never auto-retried, so the app disables it explicitly on its
/// root scopes. If a future upgrade or refactor drops that, a real error row
/// disappears again after ~200ms and no test would notice. This test pins the
/// contract at the root scope the app actually boots with.
void main() {
  testWidgets(
    'AppBootstrap disables Riverpod auto-retry so manual error rows survive',
    (tester) async {
      await tester.pumpWidget(const AppBootstrap());

      final scope = tester.widget<ProviderScope>(
        find.descendant(
          of: find.byType(AppBootstrap),
          matching: find.byType(ProviderScope),
        ),
      );

      expect(
        scope.retry,
        isNotNull,
        reason:
            'AppBootstrap must pass an explicit retry policy; otherwise '
            'Riverpod 3 restores its auto-retry default and manual error '
            'rows silently disappear.',
      );

      // A null return means "give up": no retry is scheduled, so the failed
      // state stays on screen for the user to act on.
      expect(scope.retry!(0, StateError('boom')), isNull);
      expect(scope.retry!(1, Exception('boom')), isNull);
      expect(scope.retry!(9, Exception('boom')), isNull);
    },
  );

  testWidgets('the bootstrap scope actually boots the app', (tester) async {
    await tester.pumpWidget(const AppBootstrap());
    expect(tester.takeException(), isNull);
  });
}