import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/app/void_app.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/core/auth/auth_session_store.dart';

import '../../shared/theme_test_overrides.dart';

/// Sprint 145.20 — Core Without Account.
///
/// Proves the UI wiring of session restoration: a persisted local session
/// (here in-memory; the disk-backed persistence itself is covered by
/// core_without_account_journey_test.dart and auth_controller_persistence_test.dart)
/// must open the Dashboard directly on "restart" without ever showing the
/// login screen. No credentials are involved.
void main() {
  testWidgets(
    'a persisted local session opens the dashboard without login on restart',
    (tester) async {
      final store = InMemoryAuthSessionStore();
      await store.save(const AuthSession.guest());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...themeTestOverrides(),
            authSessionStoreProvider.overrideWithValue(store),
          ],
          child: const VoidScriptorApp(),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.text('Welcome back'),
        findsNothing,
        reason: 'login screen must be skipped for a restored session',
      );
      expect(find.text('Welcome back, Guest'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
