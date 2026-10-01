import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_connected_accounts_management.dart';
import 'package:void_scriptor/features/account/domain/account_center_connection_health_state_machine.dart';

/// Stand-in for a provider failure that must not leak into user-visible text.
class _ProviderExploded implements Exception {
  const _ProviderExploded();
}

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
        initial: <AccountConnectedAccount>[account()],
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
        initial: <AccountConnectedAccount>[account()],
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
          initial: <AccountConnectedAccount>[
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
      () async {
        final manager = AccountConnectedAccountsManagement(
          initial: <AccountConnectedAccount>[account()],
        );

        final unconfirmed = await manager.unlink(
          'google/account-42',
          confirmed: false,
        );
        expect(unconfirmed.localRemoved, isFalse);
        expect(unconfirmed.providerRevokeAttempted, isFalse);
        expect(manager.connections, hasLength(1));

        // No revoker was supplied, so this disconnect is local-only by
        // declaration and says so; it is not the same row as a revoked one.
        final confirmed = await manager.unlink(
          'google/account-42',
          confirmed: true,
        );
        expect(confirmed.localRemoved, isTrue);
        expect(confirmed.providerRevokeAttempted, isFalse);
        expect(confirmed.providerRevoked, isFalse);
        expect(manager.connections, isEmpty);
      },
    );

    test(
      'a disconnect revokes at the provider when a revoker is supplied',
      () async {
        final calls = <String>[];
        final manager = AccountConnectedAccountsManagement(
          initial: <AccountConnectedAccount>[account()],
          providerRevoker: (connectionId, providerId) async {
            calls.add('$connectionId@$providerId');
            return true;
          },
        );

        final result = await manager.unlink(
          'google/account-42',
          confirmed: true,
        );

        expect(calls, <String>['google/account-42@google']);
        expect(result.providerRevokeAttempted, isTrue);
        expect(result.providerRevoked, isTrue);
        expect(result.localRemoved, isTrue);
        expect(result.isComplete, isTrue);
        expect(result.needsProviderRetry, isFalse);
        expect(manager.connections, isEmpty);
      },
    );

    test(
      'a failed provider revocation keeps the link so it can be retried',
      () async {
        final manager = AccountConnectedAccountsManagement(
          initial: <AccountConnectedAccount>[account()],
          providerRevoker: (connectionId, providerId) async => false,
        );

        final result = await manager.unlink(
          'google/account-42',
          confirmed: true,
        );

        expect(result.providerRevokeAttempted, isTrue);
        expect(result.providerRevoked, isFalse);
        expect(result.localRemoved, isFalse);
        expect(result.needsProviderRetry, isFalse);
        // The row survives, so the retry has something to retry from.
        expect(manager.connections, hasLength(1));
        expect(result.summary, contains('failed'));
      },
    );

    test(
      'a throwing revoker is reported without leaking provider internals',
      () async {
        final manager = AccountConnectedAccountsManagement(
          initial: <AccountConnectedAccount>[account()],
          providerRevoker: (connectionId, providerId) async =>
              throw const _ProviderExploded(),
        );

        final result = await manager.unlink(
          'google/account-42',
          confirmed: true,
        );

        expect(result.providerRevokeAttempted, isTrue);
        expect(result.providerRevoked, isFalse);
        expect(result.localRemoved, isFalse);
        expect(
          result.providerRevokeError.runtimeType.toString(),
          '_ProviderExploded',
        );
        expect(result.summary, isNot(contains('_ProviderExploded')));
        expect(manager.connections, hasLength(1));
      },
    );

    test(
      'a recorded health observation clears a pending reauthentication request',
      () {
        // 115.10 refreshHealth sets reauthRequired to false for every health
        // state, so the token that answered is the token that still works.
        // 115.14 kept the flag set instead, so a reauthentication request
        // outlived every proof that it had been satisfied.
        final manager = AccountConnectedAccountsManagement(
          initial: <AccountConnectedAccount>[account()],
        );
        manager.reauthenticate('google/account-42');
        expect(manager.connections.single.reauthRequired, isTrue);

        final checked = manager.recordHealthCheck(
          'google/account-42',
          healthState: AccountHealthState.healthy,
          checkedAt: DateTime.utc(2026, 9, 26, 4),
        );

        expect(checked.reauthRequired, isFalse);
        expect(manager.connections.single.reauthRequired, isFalse);
      },
    );

    test('records an explicit health check timestamp', () {
      final manager = AccountConnectedAccountsManagement(
        initial: <AccountConnectedAccount>[account()],
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
