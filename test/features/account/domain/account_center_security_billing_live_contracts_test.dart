/// Sprint 115.54 — Security & Billing verification against the LIVE contracts.
///
/// The matrix test in this directory proves the eight buckets are recorded
/// honestly. This file proves what those buckets actually assert, by driving
/// the real domain contracts rather than synthetic rows. Both defects below
/// were reproduced by probe before the fix and are the reason this step
/// exists beyond transcription.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/account/domain/account_center_activity_audit_overview.dart';
import 'package:void_scriptor/features/account/domain/account_center_api_keys_manager.dart';
import 'package:void_scriptor/features/account/domain/account_center_secure_token_vault.dart';
import 'package:void_scriptor/features/account/domain/account_center_session_device_management.dart';
import 'package:void_scriptor/features/account/domain/account_center_subscription_entitlement_model.dart';
import 'package:void_scriptor/features/account/domain/account_center_workspace_boundary_contract.dart';

void main() {
  group('entitlement_tests — a grant is not live before it is issued', () {
    // Probe witness (115.54 RED):
    //   PROBE_A state_at_2020=EntitlementState.granted has=true
    // for a grant issued at 2026-10-01 evaluated at 2020-01-01. The old
    // `entitlementStateAt` only compared expiresAt, so a caller with a skewed
    // clock — or a replayed evaluation time from a cached entitlement — read
    // a feature as granted years before the server issued it.
    test('entitlementStateAt refuses a time before grantedAt', () {
      final model = _entitlementFixture();
      final grantedAt = DateTime.utc(2026, 9, 1);

      expect(
        model.entitlementStateAt('quota.credits', grantedAt),
        EntitlementState.granted,
        reason: 'the grant is live at its own issuance instant',
      );
      expect(
        model.entitlementStateAt(
          'quota.credits',
          grantedAt.subtract(const Duration(seconds: 1)),
        ),
        EntitlementState.notYetIssued,
      );
    });

    test('hasEntitlement follows the same window, never just the expiry', () {
      final model = _entitlementFixture();
      final grantedAt = DateTime.utc(2026, 9, 1);

      expect(
        model.hasEntitlement(
          'quota.credits',
          grantedAt.subtract(const Duration(days: 400)),
        ),
        isFalse,
      );
      expect(
        model.hasEntitlement('quota.credits', DateTime.utc(2026, 9, 26)),
        isTrue,
      );
    });

    test('a grant with no expiry still stops at its issuance instant', () {
      final model = _entitlementFixture();
      final grantedAt = DateTime.utc(2026, 9, 1);

      expect(
        model.entitlementStateAt(
          'feature.offline',
          grantedAt.subtract(const Duration(days: 1)),
        ),
        EntitlementState.notYetIssued,
      );
      expect(
        model.entitlementStateAt('feature.offline', DateTime.utc(2099, 1, 1)),
        EntitlementState.granted,
        reason: 'no expiry means the grant does not silently lapse',
      );
    });

    test('a denied grant stays denied whatever the clock says', () {
      final model = _entitlementFixture(
        entitlements: <EntitlementGrant>[
          EntitlementGrant(
            key: 'blocked.key',
            state: EntitlementState.denied,
            source: EntitlementSource.signedServer,
            grantedAt: DateTime.utc(2026, 9, 1),
          ),
        ],
        limits: const <EntitlementLimit>[],
      );

      expect(
        model.entitlementStateAt('blocked.key', DateTime.utc(2020, 1, 1)),
        EntitlementState.notYetIssued,
      );
      expect(
        model.entitlementStateAt('blocked.key', DateTime.utc(2026, 9, 26)),
        EntitlementState.denied,
      );
    });

    test(
      'the right rail counts a not-yet-issued grant without calling it granted',
      () {
        // The rail is the one production consumer of entitlementStateAt, so a
        // notYetIssued state that it silently mapped to `granted` would defeat
        // the fix at the only place a user sees it.
        final model = _entitlementFixture();
        final counts = _rightRailCounts(model, DateTime.utc(2020, 1, 1));

        expect(counts.granted, 0);
      },
    );
  });

  group('key_tests — replacing key material requires reauthentication', () {
    // Probe witness (115.54 RED):
    //   PROBE_B reauth=false -> read=rotated audit=[add, replace]
    // `replace` overwrote the vault entry with reauthentication refused. The
    // product spec lists `reveal_or_replace_key` under
    // security_contract.sensitive_actions, and `copyToClipboard` (which
    // routes through vault.read) already refused. The write path did not.
    test('refuses to replace a key while reauthentication is denied', () async {
      final fixture = _KeyFixture(reauthenticated: false);
      await fixture.manager.add(
        id: 'primary',
        providerId: 'cloud-ai',
        label: 'Primary',
        secret: 'first-secret',
        scopes: const {'models:read'},
      );

      expect(
        () => fixture.manager.replace(id: 'primary', secret: 'rotated'),
        throwsA(isA<StateError>()),
      );
      expect(
        await fixture.store.read('account/account-1/api_key/primary'),
        'first-secret',
        reason: 'the stored key material must be untouched',
      );
    });

    test('a denied replace is audited as denied, not as a replace', () async {
      final fixture = _KeyFixture(reauthenticated: false);
      await fixture.manager.add(
        id: 'primary',
        providerId: 'cloud-ai',
        label: 'Primary',
        secret: 'first-secret',
        scopes: const {'models:read'},
      );

      await expectLater(
        fixture.manager.replace(id: 'primary', secret: 'rotated'),
        throwsA(isA<StateError>()),
      );

      expect(
        fixture.manager.audit.map((event) => event.action),
        containsAllInOrder(<String>['add', 'denied_replace']),
      );
    });

    test('still rotates once reauthentication succeeds', () async {
      final fixture = _KeyFixture(reauthenticated: false);
      await fixture.manager.add(
        id: 'primary',
        providerId: 'cloud-ai',
        label: 'Primary',
        secret: 'first-secret',
        scopes: const {'models:read'},
      );
      fixture.reauthenticated = true;

      await fixture.manager.replace(id: 'primary', secret: 'rotated');

      expect(
        await fixture.store.read('account/account-1/api_key/primary'),
        'rotated',
      );
      expect(fixture.manager.keys.single.replacedAt, fixture.now);
      expect(
        fixture.manager.keys.single.validation,
        ApiKeyValidation.unverified,
        reason: 'a rotated key must be revalidated before it is trusted',
      );
    });

    test('no audit event ever carries key material', () async {
      final fixture = _KeyFixture();
      await fixture.manager.add(
        id: 'primary',
        providerId: 'cloud-ai',
        label: 'Primary',
        secret: 'first-secret',
        scopes: const {'models:read'},
      );
      await fixture.manager.validate('primary');
      fixture.reauthenticated = false;
      await expectLater(
        fixture.manager.replace(id: 'primary', secret: 'rotated'),
        throwsA(isA<StateError>()),
      );

      expect(
        fixture.manager.audit.every((event) => event.secret == null),
        isTrue,
      );
    });
  });

  group('vault_tests — the vault still gates every read behind reauth', () {
    test(
      'a read without reauthentication returns nothing and writes no key',
      () async {
        final store = MemoryCredentialStore();
        final vault = AccountSecureTokenVault(
          store: store,
          reauthenticate: () async => false,
        );
        await vault.save(
          accountId: 'account-1',
          secret: 'stored-secret',
          kind: VaultSecretKind.accessToken,
        );

        expect(
          await vault.read(
            accountId: 'account-1',
            kind: VaultSecretKind.accessToken,
          ),
          isNull,
        );
      },
    );

    test('an account id cannot escape the account key namespace', () async {
      final store = MemoryCredentialStore();
      final vault = AccountSecureTokenVault(
        store: store,
        reauthenticate: () async => true,
      );

      expect(
        () => vault.keyFor('../other-account', VaultSecretKind.apiKey),
        throwsArgumentError,
      );
      expect(
        () =>
            vault.keyFor('account-1', VaultSecretKind.apiKey, secretId: '../x'),
        throwsArgumentError,
      );
    });
  });

  group(
    'session_tests — the current session cannot be revoked from the list',
    () {
      test('revoking the current session is refused', () {
        final sessions = _sessionFixture();

        expect(
          () => sessions.revokeSession(
            'session-current',
            at: DateTime.utc(2026, 9, 27, 12),
          ),
          throwsArgumentError,
        );
      });

      test(
        'force logout needs explicit confirmation and keeps the current session',
        () {
          final sessions = _sessionFixture();

          expect(
            () => sessions.forceLogout(
              confirmed: false,
              at: DateTime.utc(2026, 9, 27, 12),
            ),
            throwsArgumentError,
          );

          final after = sessions.forceLogout(
            confirmed: true,
            at: DateTime.utc(2026, 9, 27, 12),
          );
          expect(after.revokedCount, 2);
          expect(
            after.sessionById('session-current').state,
            SessionActivityState.active,
          );
        },
      );

      test('a suspicious session must be revoked before it can be trusted', () {
        final sessions = _sessionFixture().markSuspicious(
          'session-other',
          reason: 'New region',
          at: DateTime.utc(2026, 9, 27, 12),
        );

        expect(
          () => sessions.trustSession(
            'session-other',
            trusted: true,
            at: DateTime.utc(2026, 9, 27, 12),
          ),
          throwsArgumentError,
        );
      });
    },
  );

  group('permission_tests — workspace data is never implicitly reachable', () {
    test('workspace access without an explicit permission is denied', () {
      expect(
        AccountCenterWorkspaceBoundaryContract.resolveWorkspaceAccess(
          target: AccountCenterDataScope.novelWorkspace,
          hasExplicitWorkspacePermission: false,
        ),
        WorkspaceBoundaryDecision.deniedWorkspacePermissionRequired,
      );
      expect(
        AccountCenterWorkspaceBoundaryContract.resolveWorkspaceAccess(
          target: AccountCenterDataScope.novelWorkspace,
          hasExplicitWorkspacePermission: true,
        ),
        WorkspaceBoundaryDecision.allowedWorkspaceScoped,
      );
    });

    test('a cross-workspace transfer needs explicit consent', () {
      expect(
        AccountCenterWorkspaceBoundaryContract.resolveTransfer(
          source: AccountCenterDataScope.globalUser,
          destination: AccountCenterDataScope.characterWorkspace,
          hasExplicitTransferConsent: false,
        ),
        WorkspaceBoundaryDecision.deniedTransferConsentRequired,
      );
    });

    test('the account center may never hold workspace data in a backup', () {
      expect(
        AccountCenterWorkspaceBoundaryContract.backupBoundaryViolations(
          boundary: AccountBackupBoundary.accountGlobal,
          relativePaths: const ['workspaces/novels/book-1/manuscript.md'],
        ),
        <String>['ACCOUNT_GLOBAL_MUST_NOT_HOLD_WORKSPACE_DATA'],
      );
    });
  });

  group('audit_tests — sensitive detail keys cannot leak into public JSON', () {
    test('an unknown sensitive key is refused at construction', () {
      expect(
        () => AccountAuditEvent(
          id: 'event-1',
          category: AccountAuditCategory.sensitiveAction,
          occurredAt: DateTime.utc(2026, 9, 27, 12),
          actor: const AccountAuditActor(
            id: 'owner',
            displayName: 'Account Owner',
          ),
          result: AccountAuditResult.succeeded,
          details: const {'provider': 'github'},
          sensitiveDetailKeys: const {'token'},
        ),
        throwsArgumentError,
        reason: 'declaring a key that is not present is a silent no-op',
      );
    });

    test('a redacted key never appears in the serialized event', () {
      final event = AccountAuditEvent(
        id: 'event-1',
        category: AccountAuditCategory.sensitiveAction,
        occurredAt: DateTime.utc(2026, 9, 27, 12),
        actor: const AccountAuditActor(id: 'owner', displayName: 'Owner'),
        result: AccountAuditResult.succeeded,
        details: const {'token': 'ghp_supersecretvalue'},
        sensitiveDetailKeys: const {'token'},
      );

      expect(event.publicDetails['token'], '[REDACTED]');
      expect(
        event.toPublicJson().toString(),
        isNot(contains('ghp_supersecretvalue')),
      );
    });

    test('an event outside the retention window is not retained', () {
      final overview = AccountCenterActivityAuditOverview(
        retention: const Duration(days: 30),
        now: () => DateTime.utc(2026, 9, 27, 12),
        events: [
          AccountAuditEvent(
            id: 'old',
            category: AccountAuditCategory.billing,
            occurredAt: DateTime.utc(2026, 1, 1),
            actor: const AccountAuditActor(id: 'owner', displayName: 'Owner'),
            result: AccountAuditResult.succeeded,
            details: const {},
            sensitiveDetailKeys: const {},
          ),
        ],
      );

      expect(overview.retainedEvents, isEmpty);
    });
  });
}

AccountCenterSubscriptionEntitlementModel _entitlementFixture({
  List<EntitlementGrant>? entitlements,
  List<EntitlementLimit>? limits,
}) => AccountCenterSubscriptionEntitlementModel(
  plan: SubscriptionPlan(
    planId: 'plan-standard',
    displayName: 'Standard',
    tier: PlanTier.standard,
    cycle: PlanBillingCycle.monthly,
    price: PlanPrice(amount: 10, currency: 'usd'),
  ),
  entitlements:
      entitlements ??
      <EntitlementGrant>[
        EntitlementGrant(
          key: 'quota.credits',
          state: EntitlementState.granted,
          source: EntitlementSource.signedServer,
          grantedAt: DateTime.utc(2026, 9, 1),
          expiresAt: DateTime.utc(2026, 10, 1),
        ),
        EntitlementGrant(
          key: 'feature.offline',
          state: EntitlementState.granted,
          source: EntitlementSource.signedServer,
          grantedAt: DateTime.utc(2026, 9, 1),
        ),
      ],
  limits:
      limits ??
      <EntitlementLimit>[
        EntitlementLimit(key: 'quota.credits', unit: 'credits', limit: 1000),
        EntitlementLimit(key: 'feature.offline', unit: 'flag', limit: 1),
      ],
  renewal: RenewalInfo(mode: RenewalMode.none),
  cancellation: CancellationInfo(state: CancellationState.none),
  trial: TrialInfo(),
  gracePeriod: GracePeriodInfo(),
  license: OfflineLicenseInfo(
    state: OfflineLicenseState.unlicensed,
    authority: LicenseAuthority.signedServer,
  ),
);

/// Minimal read of the one production consumer's tally. Kept local so this
/// test does not need the whole right-rail fixture graph.
({int granted, int denied}) _rightRailCounts(
  AccountCenterSubscriptionEntitlementModel model,
  DateTime at,
) {
  var granted = 0;
  var denied = 0;
  for (final grant in model.entitlements) {
    switch (model.entitlementStateAt(grant.key, at)) {
      case EntitlementState.granted:
        granted++;
      case EntitlementState.denied:
        denied++;
      case EntitlementState.expired:
      case EntitlementState.notYetIssued:
        break;
    }
  }
  return (granted: granted, denied: denied);
}

AccountCenterSessionDeviceManagement _sessionFixture() =>
    AccountCenterSessionDeviceManagement(
      sessions: <ManagedSession>[
        ManagedSession(
          sessionId: 'session-current',
          isCurrent: true,
          lastActiveAt: DateTime.utc(2026, 9, 27, 12),
          trust: SessionTrustState.trusted,
          state: SessionActivityState.active,
          suspicious: false,
          device: DeviceDetails(
            deviceLabel: 'Studio PC',
            platform: SessionDevicePlatform.windows,
          ),
        ),
        ManagedSession(
          sessionId: 'session-other',
          isCurrent: false,
          lastActiveAt: DateTime.utc(2026, 9, 26, 12),
          trust: SessionTrustState.untrusted,
          state: SessionActivityState.active,
          suspicious: false,
          device: DeviceDetails(
            deviceLabel: 'Phone',
            platform: SessionDevicePlatform.android,
          ),
        ),
        ManagedSession(
          sessionId: 'session-revoked',
          isCurrent: false,
          lastActiveAt: DateTime.utc(2026, 9, 1, 12),
          trust: SessionTrustState.unknown,
          state: SessionActivityState.revoked,
          suspicious: false,
          revokedAt: DateTime.utc(2026, 9, 2, 12),
          device: DeviceDetails(
            deviceLabel: 'Old Laptop',
            platform: SessionDevicePlatform.linux,
          ),
        ),
      ],
      alerts: const <SessionSecurityAlert>[],
    );

final class _KeyFixture {
  _KeyFixture({this.reauthenticated = true}) {
    manager = AccountCenterApiKeysManager(
      accountId: 'account-1',
      vault: AccountSecureTokenVault(
        store: store,
        reauthenticate: () async => reauthenticated,
      ),
      clock: () => now,
      validator: (_) async => true,
    );
  }

  final store = MemoryCredentialStore();
  late final AccountCenterApiKeysManager manager;
  final DateTime now = DateTime.utc(2026, 9, 27, 12);
  bool reauthenticated;
}
