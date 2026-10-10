import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_connection_health_state_machine.dart';
import '../../../canonical_source_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final manifestFile = File(
    'docs/planning/v1.2/sprint_115_connection_health_state_machine.json',
  );

  String sha256Of(String path) {
    final file = File(path);
    if (!file.existsSync()) return '';
    return sha256.convert(file.readAsBytesSync()).toString();
  }

  Map<String, dynamic> readManifest() {
    expect(manifestFile.existsSync(), isTrue);
    return jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  }

  group('115.10 Connection & Health State Machine contract', () {
    test('pins the canonical step acceptance and source hashes', () {
      if (skipUnlessExternalCanonical(
        "pins the canonical step acceptance and source hashes",
      )) {
        return;
      }
      final sprint = File(
        AccountConnectionHealthStateMachine.canonicalSprintPath,
      );
      expect(sprint.existsSync(), isTrue);
      final json =
          jsonDecode(sprint.readAsStringSync()) as Map<String, dynamic>;
      final step = (json['steps'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['id'] == '115.10');

      expect(step['title'], 'Connection & Health State Machine');
      expect(
        step['acceptance'],
        AccountConnectionHealthStateMachine.canonicalAcceptance,
      );
      expect(
        AccountConnectionHealthStateMachine.canonicalSprintSha256,
        'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba',
      );

      final manifest = readManifest();
      expect(manifest['canonical_step'], '115.10');
      expect(
        manifest['document_role'],
        'SPRINT_115_CONNECTION_HEALTH_STATE_MACHINE_MANIFEST',
      );
      final sources = manifest['sources'] as Map<String, dynamic>;
      final canonical = sources['canonical_steps'] as Map<String, dynamic>;
      final productSpec = sources['product_spec'] as Map<String, dynamic>;
      final connectorSdk =
          sources['connector_sdk_spec'] as Map<String, dynamic>;
      expect(
        canonical['sha256'],
        AccountConnectionHealthStateMachine.canonicalSprintSha256,
      );
      expect(
        productSpec['sha256'],
        'f0589fe77428b94a608f44939df8bbd599e11b45d8605c59866ddaede99bd88a',
      );
      expect(connectorSdk['sha256'], isNotEmpty);
      expect(sha256Of(canonical['path'] as String), canonical['sha256']);
      expect(sha256Of(productSpec['path'] as String), productSpec['sha256']);
      expect(sha256Of(connectorSdk['path'] as String), connectorSdk['sha256']);
    });

    test('manifest records the canonical state and health vocabularies', () {
      final manifest = readManifest();
      expect(
        manifest['connection_states'],
        AccountConnectionState.values
            .map((state) => state.wireName)
            .toList(growable: false),
      );
      expect(
        manifest['health_states'],
        AccountHealthState.values
            .map((state) => state.wireName)
            .toList(growable: false),
      );
      expect(
        manifest['transitions'],
        AccountConnectionTransition.values
            .map((transition) => transition.wireName)
            .toList(growable: false),
      );
      expect(
        manifest['acceptance'],
        containsAll(<String>[
          'state_transitions',
          'retry_policy',
          'reauth_path',
          'revoke_path',
          'health_refresh',
          'user_visible_error',
        ]),
      );
    });
  });

  group('initial state and validation', () {
    test(
      'starts as not configured and never invents health or credentials',
      () {
        final machine = AccountConnectionHealthStateMachine.notConfigured(
          providerId: ' OpenAI ',
          accountLabel: 'OpenAI account',
          connectorVersion: 'manifest-v1',
        );

        expect(machine.snapshot.providerId, 'openai');
        expect(
          machine.snapshot.connectionState,
          AccountConnectionState.notConfigured,
        );
        expect(machine.snapshot.healthState, AccountHealthState.unknown);
        expect(machine.snapshot.lastCheckedAt, isNull);
        expect(machine.snapshot.reauthRequired, isFalse);
        expect(machine.snapshot.userVisibleError, isNull);
        expect(machine.snapshot.errorCode, isNull);
        expect(machine.snapshot.statusLabel, 'Not configured');
        expect(
          machine.canTransition(AccountConnectionTransition.connectSucceeded),
          isFalse,
        );
      },
    );

    test('rejects empty identifiers, labels, and retry limits', () {
      expect(
        () => AccountConnectionHealthStateMachine.notConfigured(
          providerId: ' ',
          accountLabel: 'Account',
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountConnectionHealthStateMachine.notConfigured(
          providerId: 'provider',
          accountLabel: ' ',
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountConnectionRetryPolicy(maxAttempts: 0),
        throwsArgumentError,
      );
      expect(
        () => AccountConnectionHealthStateMachine.notConfigured(
          providerId: 'provider',
          accountLabel: 'Account',
          retryPolicy: AccountConnectionRetryPolicy(maxAttempts: 0),
        ),
        throwsArgumentError,
      );
    });
  });

  group('state transitions', () {
    test('connect, health refresh, and terminal paths are explicit', () {
      final machine = AccountConnectionHealthStateMachine.notConfigured(
        providerId: 'fixture',
        accountLabel: 'Fixture account',
        connectorVersion: 'fixture-v1',
      );

      expect(
        machine.transition(
          AccountConnectionTransition.beginConnecting,
          at: DateTime.utc(2026, 1, 1),
        ),
        isA<AccountConnectionHealthSnapshot>(),
      );
      expect(
        machine.snapshot.connectionState,
        AccountConnectionState.connecting,
      );

      machine.transition(
        AccountConnectionTransition.connectSucceeded,
        at: DateTime.utc(2026, 1, 1, 0, 1),
      );
      expect(
        machine.snapshot.connectionState,
        AccountConnectionState.connected,
      );
      expect(machine.snapshot.healthState, AccountHealthState.healthy);
      expect(machine.snapshot.retryAttempt, 0);
      expect(machine.snapshot.statusLabel, 'Connected');

      machine.transition(
        AccountConnectionTransition.refreshHealth,
        at: DateTime.utc(2026, 1, 1, 0, 2),
        healthState: AccountHealthState.degraded,
      );
      expect(machine.snapshot.connectionState, AccountConnectionState.degraded);
      expect(machine.snapshot.healthState, AccountHealthState.degraded);
      expect(machine.snapshot.userVisibleError, isNotNull);
      expect(machine.snapshot.statusLabel, 'Degraded');

      machine.transition(
        AccountConnectionTransition.refreshHealth,
        at: DateTime.utc(2026, 1, 1, 0, 3),
        healthState: AccountHealthState.outage,
      );
      expect(
        machine.snapshot.connectionState,
        AccountConnectionState.unavailable,
      );
      expect(machine.snapshot.healthState, AccountHealthState.outage);
      expect(machine.snapshot.statusLabel, 'Provider outage');

      machine.transition(
        AccountConnectionTransition.reauthenticate,
        at: DateTime.utc(2026, 1, 1, 0, 4),
      );
      expect(
        machine.snapshot.connectionState,
        AccountConnectionState.connecting,
      );
      expect(machine.snapshot.healthState, AccountHealthState.unknown);
      expect(machine.snapshot.userVisibleError, isNull);
    });

    test('rejects transitions that skip required states', () {
      final machine = AccountConnectionHealthStateMachine.notConfigured(
        providerId: 'fixture',
        accountLabel: 'Fixture account',
      );

      expect(
        () => machine.transition(
          AccountConnectionTransition.connectSucceeded,
          at: DateTime.utc(2026, 1, 1),
        ),
        throwsStateError,
      );
      expect(
        () => machine.transition(
          AccountConnectionTransition.retry,
          at: DateTime.utc(2026, 1, 1),
        ),
        throwsStateError,
      );
      expect(
        () => machine.transition(
          AccountConnectionTransition.reauthenticate,
          at: DateTime.utc(2026, 1, 1),
        ),
        throwsStateError,
      );
    });

    test('expiry requires a visible reauthentication path', () {
      final machine = _connectedMachine();
      machine.transition(
        AccountConnectionTransition.expire,
        at: DateTime.utc(2026, 1, 1, 0, 2),
      );

      expect(machine.snapshot.connectionState, AccountConnectionState.expired);
      expect(machine.snapshot.reauthRequired, isTrue);
      expect(machine.snapshot.statusLabel, 'Connection expired');
      expect(machine.snapshot.userVisibleError, contains('Reauthenticate'));
      expect(machine.canTransition(AccountConnectionTransition.retry), isFalse);
      expect(
        machine.canTransition(AccountConnectionTransition.reauthenticate),
        isTrue,
      );
    });

    test(
      'revocation is explicit and cleanup is the only terminal recovery path',
      () {
        final machine = _connectedMachine();
        machine.transition(
          AccountConnectionTransition.revoke,
          at: DateTime.utc(2026, 1, 1, 0, 2),
        );

        expect(
          machine.snapshot.connectionState,
          AccountConnectionState.revoked,
        );
        expect(machine.snapshot.reauthRequired, isFalse);
        expect(machine.snapshot.statusLabel, 'Connection revoked');
        expect(machine.snapshot.userVisibleError, contains('revoked'));
        for (final transition in AccountConnectionTransition.values) {
          expect(
            machine.canTransition(transition),
            transition == AccountConnectionTransition.disconnectCleanup,
            reason: transition.wireName,
          );
        }
      },
    );
  });

  group('retry, health, and user-visible errors', () {
    test(
      'retry is bounded, preserves attempts, and rejects terminal states',
      () {
        final machine = AccountConnectionHealthStateMachine.notConfigured(
          providerId: 'fixture',
          accountLabel: 'Fixture account',
          retryPolicy: AccountConnectionRetryPolicy(maxAttempts: 2),
        );
        machine.transition(
          AccountConnectionTransition.beginConnecting,
          at: DateTime.utc(2026, 1, 1),
        );
        machine.transition(
          AccountConnectionTransition.error,
          at: DateTime.utc(2026, 1, 1, 0, 1),
          errorCode: 'timeout',
          userVisibleError: 'The provider did not respond.',
        );

        expect(machine.snapshot.connectionState, AccountConnectionState.error);
        expect(
          machine.snapshot.userVisibleError,
          'The provider did not respond.',
        );
        expect(machine.snapshot.errorCode, 'timeout');
        expect(machine.snapshot.statusLabel, 'Connection error');

        machine.transition(
          AccountConnectionTransition.retry,
          at: DateTime.utc(2026, 1, 1, 0, 2),
        );
        expect(
          machine.snapshot.connectionState,
          AccountConnectionState.connecting,
        );
        expect(machine.snapshot.retryAttempt, 1);
        machine.transition(
          AccountConnectionTransition.error,
          at: DateTime.utc(2026, 1, 1, 0, 3),
          errorCode: 'timeout',
          userVisibleError: 'The provider did not respond.',
        );
        expect(
          machine.canTransition(AccountConnectionTransition.retry),
          isTrue,
        );
        machine.transition(
          AccountConnectionTransition.retry,
          at: DateTime.utc(2026, 1, 1, 0, 4),
        );
        expect(machine.snapshot.retryAttempt, 2);
        expect(
          machine.canTransition(AccountConnectionTransition.retry),
          isFalse,
        );
        expect(
          () => machine.transition(
            AccountConnectionTransition.retry,
            at: DateTime.utc(2026, 1, 1, 0, 5),
          ),
          throwsStateError,
        );
      },
    );

    test('rate limit and outage are health states with visible text', () {
      final machine = _connectedMachine();
      machine.transition(
        AccountConnectionTransition.refreshHealth,
        at: DateTime.utc(2026, 1, 1, 0, 2),
        healthState: AccountHealthState.rateLimited,
      );
      expect(
        machine.snapshot.connectionState,
        AccountConnectionState.connected,
      );
      expect(machine.snapshot.healthState, AccountHealthState.rateLimited);
      expect(machine.snapshot.statusLabel, 'Rate limited');
      expect(machine.snapshot.userVisibleError, contains('rate limit'));

      machine.transition(
        AccountConnectionTransition.refreshHealth,
        at: DateTime.utc(2026, 1, 1, 0, 3),
        healthState: AccountHealthState.outage,
      );
      expect(
        machine.snapshot.connectionState,
        AccountConnectionState.unavailable,
      );
      expect(machine.snapshot.healthState, AccountHealthState.outage);
      expect(machine.snapshot.statusLabel, 'Provider outage');
      expect(machine.snapshot.userVisibleError, contains('outage'));
    });

    test('latency is a first-class degraded health state', () {
      final machine = _connectedMachine();
      machine.transition(
        AccountConnectionTransition.refreshHealth,
        at: DateTime.utc(2026, 1, 1, 0, 2),
        healthState: AccountHealthState.latency,
      );

      expect(machine.snapshot.connectionState, AccountConnectionState.degraded);
      expect(machine.snapshot.healthState, AccountHealthState.latency);
      expect(machine.snapshot.statusLabel, 'High latency');
      expect(machine.snapshot.errorCode, 'latency');
      expect(machine.snapshot.userVisibleError, contains('latency'));
    });

    test(
      'health refresh requires a health value and records its timestamp',
      () {
        final machine = _connectedMachine();
        expect(
          () => machine.transition(
            AccountConnectionTransition.refreshHealth,
            at: DateTime.utc(2026, 1, 1, 0, 2),
          ),
          throwsArgumentError,
        );

        final checkedAt = DateTime.utc(2026, 1, 1, 0, 2, 30);
        machine.transition(
          AccountConnectionTransition.refreshHealth,
          at: checkedAt,
          healthState: AccountHealthState.healthy,
        );
        expect(machine.snapshot.lastCheckedAt, checkedAt);
      },
    );

    test('failure states require a non-empty, redacted user-visible error', () {
      final machine = _connectedMachine();
      for (final transition in [
        AccountConnectionTransition.error,
        AccountConnectionTransition.unavailable,
      ]) {
        expect(
          () => machine.transition(
            transition,
            at: DateTime.utc(2026, 1, 1, 0, 2),
          ),
          throwsArgumentError,
        );
        expect(
          () => machine.transition(
            transition,
            at: DateTime.utc(2026, 1, 1, 0, 2),
            errorCode: 'secret',
            userVisibleError: 'Bearer «redacted:sk-…»',
          ),
          throwsArgumentError,
        );
      }
    });

    test('default recovery text is visible and never contains credentials', () {
      final machine = _connectedMachine();
      for (final transition in [
        AccountConnectionTransition.expire,
        AccountConnectionTransition.revoke,
      ]) {
        machine.transition(transition, at: DateTime.utc(2026, 1, 1, 0, 2));
        expect(machine.snapshot.userVisibleError, isNotNull);
        expect(machine.snapshot.userVisibleError, isNot(contains('Bearer ')));
        expect(machine.snapshot.userVisibleError, isNot(contains('sk-')));
        expect(machine.snapshot.userVisibleError, isNot(contains('token')));
      }
    });

    test(
      'disconnect cleanup returns a revoked connection to not configured',
      () {
        final machine = _connectedMachine();
        machine.transition(
          AccountConnectionTransition.revoke,
          at: DateTime.utc(2026, 1, 1, 0, 2),
        );

        expect(
          machine.canTransition(AccountConnectionTransition.disconnectCleanup),
          isTrue,
        );
        machine.transition(
          AccountConnectionTransition.disconnectCleanup,
          at: DateTime.utc(2026, 1, 1, 0, 3),
        );

        expect(
          machine.snapshot.connectionState,
          AccountConnectionState.notConfigured,
        );
        expect(machine.snapshot.healthState, AccountHealthState.unknown);
        expect(machine.snapshot.reauthRequired, isFalse);
        expect(machine.snapshot.userVisibleError, isNull);
        expect(machine.snapshot.errorCode, isNull);
      },
    );
  });

  test('status is stable and exposes the required action paths', () {
    final machine = _connectedMachine();
    expect(
      machine.availableTransitions,
      contains(AccountConnectionTransition.refreshHealth),
    );
    expect(
      machine.availableTransitions,
      contains(AccountConnectionTransition.revoke),
    );
    expect(
      machine.availableTransitions,
      isNot(contains(AccountConnectionTransition.connectSucceeded)),
    );
    expect(
      machine.snapshot
          .copyWith(lastCheckedAt: DateTime.utc(2026, 1, 1))
          .lastCheckedAt,
      DateTime.utc(2026, 1, 1),
    );
  });
}

AccountConnectionHealthStateMachine _connectedMachine() {
  final machine = AccountConnectionHealthStateMachine.notConfigured(
    providerId: 'fixture',
    accountLabel: 'Fixture account',
    connectorVersion: 'fixture-v1',
  );
  machine.transition(
    AccountConnectionTransition.beginConnecting,
    at: DateTime.utc(2026, 1, 1),
  );
  machine.transition(
    AccountConnectionTransition.connectSucceeded,
    at: DateTime.utc(2026, 1, 1, 0, 1),
  );
  return machine;
}
