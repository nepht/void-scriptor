import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_ai_usage_credits_cost_view.dart';
import 'package:void_scriptor/features/account/domain/account_center_cloud_storage_aggregation.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_quota_adapter.dart';
import 'package:void_scriptor/features/account/domain/account_center_right_rail_summary.dart';
import 'package:void_scriptor/features/account/domain/account_center_subscription_entitlement_model.dart';
import 'package:void_scriptor/features/account/domain/account_center_team_collaboration_summary.dart';

const String _productSpecPath =
    'C:/Users/nepht/Documents/Codex/2026-08-22/'
    'referenced-chatgpt-conversation-this-is-an-2/outputs/'
    'account_cloud_center_spec.json';

void main() {
  group('AccountCenterRightRailSummary', () {
    test('manifest preserves every canonical 115.38 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_right_rail_account_summary.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.38');
      expect(manifest['acceptance'], <String>[
        'plan',
        'entitlements',
        'credits',
        'remote_storage',
        'seats',
        'renewal',
        'manage_actions',
      ]);
      expect(
        manifest['implementation'],
        'lib/features/account/domain/account_center_right_rail_summary.dart',
      );
      expect(
        manifest['evidence'],
        'test/features/account/domain/account_center_right_rail_summary_test.dart',
      );
    });

    test('acceptance list is pinned to canonical sprint 115.38', () {
      final file = File(AccountCenterRightRailSummary.canonicalSprintPath);
      expect(file.existsSync(), isTrue);
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final step = (json['steps'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['id'] == '115.38');

      expect(step['title'], 'Right-Rail Account Summary');
      expect(
        step['acceptance'],
        AccountCenterRightRailSummary.canonicalAcceptance,
      );
      expect(
        AccountCenterRightRailSummary.canonicalSprintSha256,
        'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba',
      );
    });

    test(
      'product spec keeps the right rail sections and the no-fake-data rules',
      () {
        final spec =
            jsonDecode(File(_productSpecPath).readAsStringSync())
                as Map<String, Object?>;
        final sections =
            spec['information_architecture'] as Map<String, Object?>;

        expect(sections['right_summary_sections'], contains('account_summary'));
        expect(sections['right_summary_sections'], contains('credits_tokens'));
        expect(sections['right_summary_sections'], contains('quick_actions'));
        expect(
          (spec['acceptance_invariants'] as List<dynamic>),
          contains(
            'storage_and_credit_values_are_api_backed_or_explicitly_unavailable',
          ),
        );
        expect(
          (spec['acceptance_invariants'] as List<dynamic>),
          contains('reference_mock_values_never_reach_production_state'),
        );
        expect(
          (spec['security_contract']
              as Map<String, Object?>)['sensitive_actions'],
          contains('change_billing'),
        );
      },
    );

    test('plan summary mirrors the subscription plan without inventing it', () {
      final summary = _summary(subscription: _subscription());
      final plan = summary.plan;

      expect(plan.planId, 'plan-standard');
      expect(plan.displayName, 'Standard');
      expect(plan.tier, PlanTier.standard);
      expect(plan.cycle, PlanBillingCycle.monthly);
      expect(plan.priceLabel, 'USD 12.00');
    });

    test('entitlement counts are evaluated at an instant, never assumed', () {
      final summary = _summary(subscription: _subscription());
      final beforeExpiry = summary.entitlementsAt(_utc(2026, 4, 1));
      final afterExpiry = summary.entitlementsAt(_utc(2026, 7, 1));

      expect(beforeExpiry.granted, 2);
      expect(beforeExpiry.denied, 1);
      expect(beforeExpiry.expired, 0);
      expect(beforeExpiry.total, 3);
      expect(beforeExpiry.label, '2 granted, 1 denied');

      // A grant whose expiry has passed stops being granted without anybody
      // rewriting the model.
      expect(afterExpiry.granted, 1);
      expect(afterExpiry.expired, 1);
      expect(afterExpiry.denied, 1);

      expect(summary.entitlementKeys, <String>[
        'aiAccess',
        'exportRights',
        'seatAssignments',
      ]);
    });

    test(
      'credits stay explicitly unavailable instead of collapsing to zero',
      () {
        final measured = _summary(
          subscription: _subscription(),
          credits: ApplicationCreditBalance.available(
            remaining: 250,
            measuredAt: _utc(2026, 4, 1),
          ),
        );
        expect(measured.credits.isAvailable, isTrue);
        expect(measured.credits.valueOrNull, 250);
        expect(measured.creditsLabel, '250 credits');

        final missing = _summary(subscription: _subscription());
        expect(missing.credits.isAvailable, isFalse);
        expect(missing.credits.valueOrNull, isNull);
        expect(missing.creditsLabel, 'Credits unavailable');
        expect(
          () => missing.credits.value,
          throwsStateError,
          reason: 'An unavailable credit balance must never read as zero.',
        );
      },
    );

    test('remote storage is labelled remote and never merged with local', () {
      final summary = _summary(subscription: _subscription());
      final storage = summary.remoteStorage;

      expect(storage.scope, RightRailStorageScope.remote);
      expect(storage.scopeLabel, 'Remote cloud');
      expect(storage.isAvailable, isTrue);
      expect(storage.usedLabel, '1.0 GB');
      expect(storage.quotaLabel, '2.0 GB');
      expect(storage.lastUpdated, _utc(2026, 4, 1));
      expect(storage.label, contains('Remote cloud'));

      final offline = _summary(
        subscription: _subscription(),
        storage: _unavailableStorage,
      );
      expect(offline.remoteStorage.isAvailable, isFalse);
      expect(offline.remoteStorage.quotaLabel, 'Quota unavailable');
      expect(
        offline.remoteStorage.usedLabel,
        isNot(contains('0')),
        reason:
            'An unavailable provider reading never becomes a zero byte row.',
      );
      expect(offline.remoteStorage.summaryLabel, 'Remote cloud — unavailable');
    });

    test('reference mock quota numbers can never be produced by the rail', () {
      final spec =
          jsonDecode(File(_productSpecPath).readAsStringSync())
              as Map<String, Object?>;
      final storageContract =
          spec['storage_usage_contract'] as Map<String, Object?>;
      final mocks =
          (storageContract['reference_mock_values']
                  as Map<String, Object?>)['examples_from_image']
              as List<dynamic>;
      final summary = _summary(subscription: _subscription());
      final rendered = <String>[
        summary.remoteStorage.usedLabel,
        summary.remoteStorage.quotaLabel,
        summary.remoteStorage.label,
        summary.creditsLabel,
      ];

      expect(mocks, isNotEmpty);
      for (final mock in mocks) {
        expect(rendered, isNot(contains(mock)));
      }
      expect(AccountCenterRightRailSummary.referenceMockValuesAllowed, isFalse);
    });

    test(
      'seats are unavailable without a team instead of reported as zero',
      () {
        final solo = _summary(subscription: _subscription());
        expect(solo.seats.isAvailable, isFalse);
        expect(solo.seatsLabel, 'Seats unavailable');

        final team = _summary(
          subscription: _subscription(),
          seats: TeamSeatSummary(assigned: 2, total: 3),
        );
        expect(team.seats.isAvailable, isTrue);
        expect(team.seatsLabel, '2 of 3 seats used');
        expect(team.seats.valueOrNull!.available, 1);
      },
    );

    test('renewal state follows renewal mode, cancellation, and dates', () {
      final auto = _summary(subscription: _subscription());
      expect(auto.renewal.state, RightRailRenewalState.renews);
      expect(auto.renewal.renewsAt, _utc(2026, 5, 1));
      expect(auto.renewalLabel, 'Renews 2026-05-01');

      final scheduled = _summary(
        subscription: _subscription(
          cancellation: CancellationInfo(
            state: CancellationState.scheduled,
            requestedAt: _utc(2026, 4, 10),
            effectiveAt: _utc(2026, 5, 1),
          ),
        ),
      );
      expect(scheduled.renewal.state, RightRailRenewalState.cancelsOn);
      expect(scheduled.renewal.effectiveAt, _utc(2026, 5, 1));
      expect(scheduled.renewalLabel, 'Cancels 2026-05-01');

      final cancelled = _summary(
        subscription: _subscription(
          renewal: RenewalInfo(mode: RenewalMode.none),
          cancellation: CancellationInfo(
            state: CancellationState.cancelled,
            requestedAt: _utc(2026, 4, 10),
            effectiveAt: _utc(2026, 5, 1),
          ),
        ),
      );
      expect(cancelled.renewal.state, RightRailRenewalState.cancelled);
      expect(cancelled.renewal.renewsAt, isNull);
      expect(cancelled.renewalLabel, 'Subscription cancelled');

      // A free plan with no billing cycle shows no renewal date, ever.
      final free = _summary(subscription: _freeSubscription());
      expect(free.renewal.state, RightRailRenewalState.none);
      expect(free.renewal.renewsAt, isNull);
      expect(free.renewalLabel, 'No renewal');
    });

    test('manage actions are permission-aware and fail closed', () {
      final summary = _summary(
        subscription: _subscription(),
        permissions: const RightRailPermissionSnapshot.granted(),
      );

      final allowed = summary.resolveAction(
        RightRailManageActionKind.viewInvoices,
      );
      expect(allowed.availability, RightRailActionAvailability.enabled);
      expect(allowed.reason, isNull);

      final denied = _summary(
        subscription: _subscription(),
        permissions: const RightRailPermissionSnapshot.denied('Viewer role'),
      );
      final blocked = denied.resolveAction(
        RightRailManageActionKind.changeBilling,
      );
      expect(blocked.availability, RightRailActionAvailability.disabled);
      expect(blocked.reason, 'Viewer role');

      // Unknown permission state never reads as permission granted.
      final unknown = _summary(
        subscription: _subscription(),
        permissions: const RightRailPermissionSnapshot.unavailable(),
      );
      final unknownResult = unknown.resolveAction(
        RightRailManageActionKind.viewInvoices,
      );
      expect(unknownResult.availability, RightRailActionAvailability.disabled);
      expect(unknownResult.reason, 'Permission state unavailable');
    });

    test(
      'sensitive manage actions require reauthentication before they run',
      () {
        final summary = _summary(
          subscription: _subscription(),
          permissions: const RightRailPermissionSnapshot.granted(),
        );

        final gated = summary.resolveAction(
          RightRailManageActionKind.changeBilling,
        );
        expect(
          gated.availability,
          RightRailActionAvailability.reauthenticationRequired,
        );
        expect(gated.reason, isNull);
        expect(
          () => summary.invokeAction(
            RightRailManageActionKind.changeBilling,
            reauthenticated: false,
          ),
          throwsStateError,
        );
        expect(summary.audit, isEmpty);

        final result = summary.invokeAction(
          RightRailManageActionKind.changeBilling,
          reauthenticated: true,
        );
        expect(result.availability, RightRailActionAvailability.enabled);
        expect(summary.audit, hasLength(1));
        expect(
          summary.audit.first.action,
          RightRailManageActionKind.changeBilling,
        );
        expect(summary.audit.first.at, _now);
        expect(
          summary
              .resolveAction(
                RightRailManageActionKind.changeBilling,
                reauthenticated: true,
              )
              .availability,
          RightRailActionAvailability.enabled,
        );

        // A non-sensitive action runs without a reauthentication ceremony but
        // is still audited.
        summary.invokeAction(RightRailManageActionKind.viewInvoices);
        expect(summary.audit, hasLength(2));
        expect(
          summary.audit.last.action,
          RightRailManageActionKind.viewInvoices,
        );
        expect(
          summary.audit.map((event) => event.action).toList(),
          <RightRailManageActionKind>[
            RightRailManageActionKind.changeBilling,
            RightRailManageActionKind.viewInvoices,
          ],
        );
      },
    );

    test('unknown or duplicate manage actions cannot be resolved or run', () {
      final summary = _summary(
        subscription: _subscription(),
        permissions: const RightRailPermissionSnapshot.granted(),
      );
      expect(
        () => summary.resolveAction(RightRailManageActionKind.manageSeats),
        throwsStateError,
      );
      expect(
        () => summary.invokeAction(
          RightRailManageActionKind.manageSeats,
          reauthenticated: true,
        ),
        throwsStateError,
      );
      expect(
        () => AccountCenterRightRailSummary(
          subscription: _subscription(),
          credits: ApplicationCreditBalance.unavailable(),
          storage: _storage,
          permissions: const RightRailPermissionSnapshot.granted(),
          actions: const [
            RightRailManageAction(kind: RightRailManageActionKind.viewInvoices),
            RightRailManageAction(kind: RightRailManageActionKind.viewInvoices),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('sections are immutable and cannot be reordered from outside', () {
      final summary = _summary(
        subscription: _subscription(),
        permissions: const RightRailPermissionSnapshot.granted(),
      );

      expect(
        () => summary.sections.add(RightRailSectionKind.accountSummary),
        throwsUnsupportedError,
      );
      expect(
        () => summary.manageActions.add(
          const RightRailManageAction(
            kind: RightRailManageActionKind.manageSeats,
          ),
        ),
        throwsUnsupportedError,
      );
      expect(summary.sections, AccountCenterRightRailSummary.sectionOrder);
      expect(summary.sections, <RightRailSectionKind>[
        RightRailSectionKind.accountSummary,
        RightRailSectionKind.credits,
        RightRailSectionKind.quickActions,
      ]);
    });
  });
}

final DateTime _now = _utc(2026, 4, 2);

DateTime _utc(int year, int month, int day) =>
    DateTime.utc(year, month, day, 8);

final CloudStorageAggregation _storage =
    CloudStorageAggregation.from(<ProviderQuotaResult>[
      ProviderQuotaResult.fromReading(
        ProviderQuotaReading(
          providerId: 'drive',
          usedBytes: 1024 * 1024 * 1024,
          quotaBytes: 2 * 1024 * 1024 * 1024,
          availableBytes: 1024 * 1024 * 1024,
          measuredAt: _utc(2026, 4, 1),
          unit: ProviderQuotaUnit.bytes,
        ),
        now: _now,
      ),
    ]);

final CloudStorageAggregation _unavailableStorage =
    CloudStorageAggregation.from(const <ProviderQuotaResult>[]);

AccountCenterSubscriptionEntitlementModel _subscription({
  RenewalInfo? renewal,
  CancellationInfo? cancellation,
}) {
  return AccountCenterSubscriptionEntitlementModel(
    plan: SubscriptionPlan(
      planId: 'plan-standard',
      displayName: 'Standard',
      tier: PlanTier.standard,
      cycle: PlanBillingCycle.monthly,
      price: PlanPrice(amount: 12, currency: 'usd'),
    ),
    entitlements: <EntitlementGrant>[
      EntitlementGrant(
        key: 'aiAccess',
        state: EntitlementState.granted,
        source: EntitlementSource.signedServer,
        grantedAt: _utc(2026, 1, 1),
      ),
      EntitlementGrant(
        key: 'exportRights',
        state: EntitlementState.granted,
        source: EntitlementSource.manualGrant,
        grantedAt: _utc(2026, 1, 1),
        expiresAt: _utc(2026, 6, 1),
      ),
      EntitlementGrant(
        key: 'seatAssignments',
        state: EntitlementState.denied,
        source: EntitlementSource.signedServer,
        grantedAt: _utc(2026, 1, 1),
      ),
    ],
    limits: const <EntitlementLimit>[],
    renewal:
        renewal ??
        RenewalInfo(mode: RenewalMode.auto, renewsAt: _utc(2026, 5, 1)),
    cancellation:
        cancellation ?? CancellationInfo(state: CancellationState.none),
    trial: TrialInfo(),
    gracePeriod: GracePeriodInfo(),
    license: OfflineLicenseInfo(
      state: OfflineLicenseState.unlicensed,
      authority: LicenseAuthority.signedServer,
    ),
  );
}

AccountCenterSubscriptionEntitlementModel _freeSubscription() {
  return AccountCenterSubscriptionEntitlementModel(
    plan: SubscriptionPlan(
      planId: 'plan-free',
      displayName: 'Free',
      tier: PlanTier.free,
      cycle: PlanBillingCycle.none,
    ),
    entitlements: const <EntitlementGrant>[],
    limits: const <EntitlementLimit>[],
    renewal: RenewalInfo(mode: RenewalMode.none),
    cancellation: CancellationInfo(state: CancellationState.none),
    trial: TrialInfo(),
    gracePeriod: GracePeriodInfo(),
    license: OfflineLicenseInfo(
      state: OfflineLicenseState.unlicensed,
      authority: LicenseAuthority.signedServer,
    ),
  );
}

AccountCenterRightRailSummary _summary({
  required AccountCenterSubscriptionEntitlementModel subscription,
  ApplicationCreditBalance? credits,
  CloudStorageAggregation? storage,
  TeamSeatSummary? seats,
  RightRailPermissionSnapshot? permissions,
}) {
  return AccountCenterRightRailSummary(
    subscription: subscription,
    credits: credits ?? ApplicationCreditBalance.unavailable(),
    storage: storage ?? _storage,
    seats: seats,
    permissions: permissions ?? const RightRailPermissionSnapshot.unavailable(),
    actions: const <RightRailManageAction>[
      RightRailManageAction(kind: RightRailManageActionKind.viewInvoices),
      RightRailManageAction(
        kind: RightRailManageActionKind.changeBilling,
        requiresReauthentication: true,
      ),
    ],
    now: () => _now,
  );
}
