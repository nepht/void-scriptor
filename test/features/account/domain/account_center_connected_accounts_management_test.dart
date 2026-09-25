import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_connected_accounts_management.dart';
import 'package:void_scriptor/features/account/domain/account_center_connection_health_state_machine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final manifestFile = File(
    'docs/planning/v1.2/sprint_115_connected_accounts_management.json',
  );

  AccountConnectedAccount account({
    String connectionId = 'google/account-42',
    String label = 'Personal Google',
    DateTime? lastCheckedAt,
  }) => AccountConnectedAccount(
    connectionId: connectionId,
    providerId: 'google',
    accountLabel: label,
    scopes: const {'openid', 'profile'},
    connectionState: AccountConnectionState.connected,
    healthState: AccountHealthState.healthy,
    lastCheckedAt: lastCheckedAt,
    reauthRequired: false,
  );

  group('115.14 Connected Accounts Management contract', () {
    test('pins the canonical step and acceptance', () {
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['canonical_step'], '115.14');
      expect(manifest['acceptance'], <String>[
        'list_connections',
        'add_connection',
        'scope_review',
        'reauth',
        'unlink_confirmation',
        'last_checked',
      ]);
      expect(manifest['boundary'], contains('does not claim'));
    });

    test('lists and adds connections without sharing mutable state', () {
      final manager = AccountConnectedAccountsManagement();
      final first = account();
      manager.add(first);

      expect(manager.connections, [first]);
      expect(manager.connections, isA<List<AccountConnectedAccount>>());
      expect(
        () => manager.connections.add(account(connectionId: 'x/y')),
        throwsUnsupportedError,
      );
    });

    test('replaces a label while preserving provider and scopes', () {
      final manager = AccountConnectedAccountsManagement(
        <AccountConnectedAccount>[account()],
      );

      final renamed = manager.rename(
        connectionId: 'google/account-42',
        label: 'Writing account',
      );

      expect(renamed.accountLabel, 'Writing account');
      expect(renamed.providerId, 'google');
      expect(manager.scopeReview('google/account-42'), {'openid', 'profile'});
    });

    test('rejects duplicate ids, blank labels, and unknown scope review', () {
      final manager = AccountConnectedAccountsManagement(
        <AccountConnectedAccount>[account()],
      );

      expect(() => manager.add(account()), throwsArgumentError);
      expect(
        () => manager.rename(connectionId: 'google/account-42', label: ' '),
        throwsArgumentError,
      );
      expect(() => manager.scopeReview('missing/id'), throwsStateError);
    });

    test(
      'reauth marks only the selected connection and exposes its scopes',
      () {
        final manager = AccountConnectedAccountsManagement(
          <AccountConnectedAccount>[
            account(),
            account(connectionId: 'github/account-7', label: 'Code'),
          ],
        );

        final request = manager.reauthenticate('google/account-42');

        expect(request.connectionId, 'google/account-42');
        expect(request.providerId, 'google');
        expect(request.scopes, {'openid', 'profile'});
        expect(manager.connections.first.reauthRequired, isTrue);
        expect(manager.connections[1].reauthRequired, isFalse);
      },
    );

    test(
      'unlink requires explicit confirmation and removes only confirmed account',
      () {
        final manager = AccountConnectedAccountsManagement(
          <AccountConnectedAccount>[account()],
        );

        expect(manager.unlink('google/account-42', confirmed: false), isFalse);
        expect(manager.connections, hasLength(1));
        expect(manager.unlink('google/account-42', confirmed: true), isTrue);
        expect(manager.connections, isEmpty);
      },
    );

    test('records an explicit health check timestamp', () {
      final manager = AccountConnectedAccountsManagement(
        <AccountConnectedAccount>[account()],
      );
      final checkedAt = DateTime.utc(2026, 9, 25, 9);

      final checked = manager.recordHealthCheck(
        'google/account-42',
        healthState: AccountHealthState.degraded,
        checkedAt: checkedAt,
      );

      expect(checked.healthState, AccountHealthState.degraded);
      expect(checked.lastCheckedAt, checkedAt);
      expect(checked.connectionState, AccountConnectionState.degraded);
    });
  });
}
