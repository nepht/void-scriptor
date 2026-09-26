import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_subscription_entitlement_model.dart';

void main() {
  group('AccountCenterSubscriptionEntitlementModel', () {
    test('manifest preserves every canonical 115.34 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_subscription_entitlement_model.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.34');
      expect(manifest['acceptance'], <String>[
        'plan',
        'entitlements',
        'limits',
        'renewal',
        'cancellation',
        'trial',
        'grace_period',
        'license_state',
      ]);
      expect(
        manifest['implementation'],
        'lib/features/account/domain/account_center_subscription_entitlement_model.dart',
      );
      expect(
        manifest['evidence'],
        'test/features/account/domain/account_center_subscription_entitlement_model_test.dart',
      );
    });

    test('plan separates tier, cycle, and explicitly unavailable pricing', () {
      final model = _fixture();

      expect(model.plan.planId, 'plan-pro');
      expect(model.plan.displayName, 'Pro');
      expect(model.plan.tier, PlanTier.premium);
      expect(model.plan.cycle, PlanBillingCycle.monthly);
      expect(model.plan.price!.amount, 9.99);
      expect(model.plan.price!.currency, 'usd');

      // Free plan: no cycle, no price.
      final free = SubscriptionPlan(
        planId: 'plan-free',
        displayName: 'Free',
        tier: PlanTier.free,
        cycle: PlanBillingCycle.none,
      );
      expect(free.price, isNull);

      // Paid plan with pricing not yet verifiable (billing contract is
      // PLANNED_NOT_VERIFIED) keeps price explicit-null instead of a guess.
      final unpriced = SubscriptionPlan(
        planId: 'plan-team',
        displayName: 'Team',
        tier: PlanTier.standard,
        cycle: PlanBillingCycle.yearly,
      );
      expect(unpriced.price, isNull);

      expect(
        () => SubscriptionPlan(
          planId: '   ',
          displayName: 'Free',
          tier: PlanTier.free,
          cycle: PlanBillingCycle.none,
        ),
        throwsArgumentError,
      );
      expect(
        () => SubscriptionPlan(
          planId: 'plan-free',
          displayName: '  ',
          tier: PlanTier.free,
          cycle: PlanBillingCycle.none,
        ),
        throwsArgumentError,
      );
      expect(
        () => SubscriptionPlan(
          planId: 'plan-free',
          displayName: 'Free',
          tier: PlanTier.free,
          cycle: PlanBillingCycle.monthly,
        ),
        throwsArgumentError,
      );
      expect(
        () => SubscriptionPlan(
          planId: 'plan-free',
          displayName: 'Free',
          tier: PlanTier.free,
          cycle: PlanBillingCycle.none,
          price: PlanPrice(amount: 1, currency: 'usd'),
        ),
        throwsArgumentError,
      );
      expect(
        () => SubscriptionPlan(
          planId: 'plan-pro',
          displayName: 'Pro',
          tier: PlanTier.premium,
          cycle: PlanBillingCycle.none,
        ),
        throwsArgumentError,
      );
      expect(() => PlanPrice(amount: -1, currency: 'usd'), throwsArgumentError);
      expect(
        () => PlanPrice(amount: double.nan, currency: 'usd'),
        throwsArgumentError,
      );
      expect(() => PlanPrice(amount: 1, currency: 'US'), throwsArgumentError);
      expect(() => PlanPrice(amount: 1, currency: ' '), throwsArgumentError);
    });

    test(
      'entitlement grants keep unique keys, UTC stamps, and bounded trial expiry',
      () {
        final model = _fixture();

        expect(model.entitlements.map((grant) => grant.key), <String>[
          'quota.credits',
          'feature.offline',
        ]);
        expect(() => model.entitlements.clear(), throwsUnsupportedError);
        expect(
          model.entitlementByKey('quota.credits').source,
          EntitlementSource.signedServer,
        );
        expect(
          model.entitlementByKey('feature.offline').source,
          EntitlementSource.offlineLicense,
        );
        expect(() => model.entitlementByKey('missing'), throwsStateError);

        expect(() => _grant('   '), throwsArgumentError);
        expect(
          () => EntitlementGrant(
            key: 'local.time',
            state: EntitlementState.granted,
            source: EntitlementSource.signedServer,
            grantedAt: DateTime(2026, 9, 1),
          ),
          throwsArgumentError,
        );
        expect(
          () => EntitlementGrant(
            key: 'same.instant',
            state: EntitlementState.granted,
            source: EntitlementSource.signedServer,
            grantedAt: DateTime.utc(2026, 9, 1),
            expiresAt: DateTime.utc(2026, 9, 1),
          ),
          throwsArgumentError,
        );
        // A trial-sourced grant is bounded by design.
        expect(
          () => EntitlementGrant(
            key: 'trial.bounded',
            state: EntitlementState.granted,
            source: EntitlementSource.trial,
            grantedAt: DateTime.utc(2026, 9, 1),
          ),
          throwsArgumentError,
        );
        expect(
          () => _fixture(
            entitlements: [_grant('dup'), _grant('dup')],
            limits: const [],
          ),
          throwsArgumentError,
        );
      },
    );

    test('entitlement state resolves at an explicit timestamp', () {
      final model = _fixture();

      expect(
        model.entitlementStateAt('quota.credits', DateTime.utc(2026, 9, 26)),
        EntitlementState.granted,
      );
      expect(
        model.entitlementStateAt('quota.credits', DateTime.utc(2026, 10, 1)),
        EntitlementState.expired,
      );
      expect(
        model.hasEntitlement('quota.credits', DateTime.utc(2026, 10, 1)),
        isFalse,
      );
      // No expiry means the grant does not silently expire.
      expect(
        model.hasEntitlement('feature.offline', DateTime.utc(2099, 1, 1)),
        isTrue,
      );

      final denied = _fixture(
        entitlements: [_grant('blocked.key', state: EntitlementState.denied)],
        limits: const [],
      );
      expect(
        denied.entitlementStateAt('blocked.key', DateTime.utc(2026, 9, 26)),
        EntitlementState.denied,
      );
      expect(
        denied.hasEntitlement('blocked.key', DateTime.utc(2026, 9, 26)),
        isFalse,
      );
      expect(() => denied.entitlementByKey('missing'), throwsStateError);

      expect(
        () => model.entitlementStateAt('quota.credits', DateTime(2026, 9, 26)),
        throwsArgumentError,
      );
    });

    test(
      'limits never go negative and never reference unknown entitlements',
      () {
        final model = _fixture();

        expect(model.limitByKey('quota.credits').limit, 1000);
        expect(model.limitByKey('quota.credits').unit, 'credits');
        // Explicitly unavailable, never a fabricated zero.
        expect(model.limitByKey('feature.offline').limit, isNull);
        expect(model.limits, hasLength(2));
        expect(() => model.limitByKey('missing'), throwsStateError);
        expect(() => model.limits.clear(), throwsUnsupportedError);

        expect(
          () => EntitlementLimit(key: 'k', unit: '   ', limit: 1),
          throwsArgumentError,
        );
        expect(
          () => EntitlementLimit(key: 'k', unit: 'units', limit: -1),
          throwsArgumentError,
        );
        expect(
          () =>
              EntitlementLimit(key: 'k', unit: 'units', limit: double.infinity),
          throwsArgumentError,
        );
        expect(
          () => _fixture(
            limits: [EntitlementLimit(key: 'ghost.limit', unit: 'units')],
          ),
          throwsArgumentError,
        );
        expect(
          () => _fixture(
            limits: [
              EntitlementLimit(key: 'quota.credits', unit: 'credits', limit: 1),
              EntitlementLimit(key: 'quota.credits', unit: 'credits', limit: 2),
            ],
          ),
          throwsArgumentError,
        );
      },
    );

    test('renewal mode carries the renewsAt contract', () {
      final model = _fixture();

      expect(model.renewal.mode, RenewalMode.auto);
      expect(model.renewal.renewsAt, DateTime.utc(2026, 10, 1));

      expect(RenewalInfo(mode: RenewalMode.none).renewsAt, isNull);
      expect(RenewalInfo(mode: RenewalMode.manual).renewsAt, isNull);
      // Auto renewal without a date, or a date on a mode that cannot renew,
      // is a fabrication and fails closed.
      expect(() => RenewalInfo(mode: RenewalMode.auto), throwsArgumentError);
      expect(
        () => RenewalInfo(
          mode: RenewalMode.none,
          renewsAt: DateTime.utc(2026, 10, 1),
        ),
        throwsArgumentError,
      );
      expect(
        () => RenewalInfo(
          mode: RenewalMode.unknown,
          renewsAt: DateTime.utc(2026, 10, 1),
        ),
        throwsArgumentError,
      );
      expect(
        () => RenewalInfo(
          mode: RenewalMode.auto,
          renewsAt: DateTime(2026, 10, 1),
        ),
        throwsArgumentError,
      );
    });

    test(
      'cancellation separates none, scheduled, and cancelled with UTC bounds',
      () {
        final model = _fixture();

        expect(model.cancellation.state, CancellationState.none);
        expect(model.cancellation.requestedAt, isNull);
        expect(model.cancellation.effectiveAt, isNull);
        expect(model.cancellation.reason, isNull);

        expect(
          () => CancellationInfo(
            state: CancellationState.none,
            requestedAt: DateTime.utc(2026, 9, 26),
          ),
          throwsArgumentError,
        );
        expect(
          () => CancellationInfo(
            state: CancellationState.none,
            reason: 'changed plan',
          ),
          throwsArgumentError,
        );
        expect(
          () => CancellationInfo(
            state: CancellationState.scheduled,
            requestedAt: DateTime.utc(2026, 9, 26),
          ),
          throwsArgumentError,
        );
        expect(
          () => CancellationInfo(
            state: CancellationState.scheduled,
            requestedAt: DateTime.utc(2026, 10, 1),
            effectiveAt: DateTime.utc(2026, 9, 26),
          ),
          throwsArgumentError,
        );
        expect(
          () => CancellationInfo(
            state: CancellationState.cancelled,
            requestedAt: DateTime.utc(2026, 9, 26),
            effectiveAt: DateTime.utc(2026, 10, 1),
            reason: '   ',
          ),
          throwsArgumentError,
        );
        expect(
          () => CancellationInfo(
            state: CancellationState.scheduled,
            requestedAt: DateTime(2026, 9, 26),
            effectiveAt: DateTime.utc(2026, 10, 1),
          ),
          throwsArgumentError,
        );

        final scheduled = CancellationInfo(
          state: CancellationState.scheduled,
          requestedAt: DateTime.utc(2026, 9, 26),
          effectiveAt: DateTime.utc(2026, 10, 1),
          reason: 'Downgrade path',
        );
        expect(scheduled.reason, 'Downgrade path');
      },
    );

    test(
      'trial and grace periods evaluate their phase at an explicit timestamp',
      () {
        final model = _fixture(
          trial: TrialInfo(
            startedAt: DateTime.utc(2026, 9, 20),
            endsAt: DateTime.utc(2026, 9, 30),
          ),
          gracePeriod: GracePeriodInfo(
            startedAt: DateTime.utc(2026, 9, 24),
            endsAt: DateTime.utc(2026, 9, 27),
          ),
        );

        expect(
          model.trialPhaseAt(DateTime.utc(2026, 9, 26)),
          TrialPhase.active,
        );
        expect(
          model.trialPhaseAt(DateTime.utc(2026, 9, 30)),
          TrialPhase.expired,
        );
        expect(model.trialPhaseAt(DateTime.utc(2026, 9, 19)), TrialPhase.none);
        expect(
          model.gracePhaseAt(DateTime.utc(2026, 9, 26)),
          GracePhase.active,
        );
        expect(
          model.gracePhaseAt(DateTime.utc(2026, 9, 27)),
          GracePhase.expired,
        );
        expect(model.gracePhaseAt(DateTime.utc(2026, 9, 23)), GracePhase.none);
        expect(
          _fixture().trialPhaseAt(DateTime.utc(2026, 9, 26)),
          TrialPhase.none,
        );
        expect(
          _fixture().gracePhaseAt(DateTime.utc(2026, 9, 26)),
          GracePhase.none,
        );
        expect(
          () => model.trialPhaseAt(DateTime(2026, 9, 26)),
          throwsArgumentError,
        );

        expect(
          () => TrialInfo(startedAt: DateTime.utc(2026, 9, 20)),
          throwsArgumentError,
        );
        expect(
          () => TrialInfo(endsAt: DateTime.utc(2026, 9, 30)),
          throwsArgumentError,
        );
        expect(
          () => TrialInfo(
            startedAt: DateTime.utc(2026, 9, 30),
            endsAt: DateTime.utc(2026, 9, 20),
          ),
          throwsArgumentError,
        );
        expect(
          () => TrialInfo(
            startedAt: DateTime.utc(2026, 9, 20),
            endsAt: DateTime.utc(2026, 9, 20),
          ),
          throwsArgumentError,
        );
        expect(
          () => GracePeriodInfo(
            startedAt: DateTime(2026, 9, 24),
            endsAt: DateTime.utc(2026, 9, 27),
          ),
          throwsArgumentError,
        );
      },
    );

    test('offline license state never fabricates availability', () {
      final model = _fixture();

      expect(model.license.state, OfflineLicenseState.active);
      expect(model.license.authority, LicenseAuthority.offlineLicense);
      expect(model.license.licensedTo, 'choirudin@example.invalid');
      expect(model.license.expiresAt, DateTime.utc(2026, 12, 1));
      expect(model.license.lastCheckedAt, DateTime.utc(2026, 9, 26));

      // Unknown is an explicit answer, never an assumed grant.
      final unknown = OfflineLicenseInfo(
        state: OfflineLicenseState.unknown,
        authority: LicenseAuthority.signedServer,
      );
      expect(unknown.expiresAt, isNull);
      expect(unknown.licensedTo, isNull);
      expect(unknown.lastCheckedAt, isNull);

      final unlicensed = OfflineLicenseInfo(
        state: OfflineLicenseState.unlicensed,
        authority: LicenseAuthority.offlineLicense,
      );
      expect(unlicensed.licensedTo, isNull);
      expect(unlicensed.expiresAt, isNull);

      final expired = OfflineLicenseInfo(
        state: OfflineLicenseState.expired,
        authority: LicenseAuthority.offlineLicense,
        licensedTo: 'choirudin@example.invalid',
        expiresAt: DateTime.utc(2026, 1, 1),
      );
      expect(expired.state, OfflineLicenseState.expired);

      expect(
        () => OfflineLicenseInfo(
          state: OfflineLicenseState.active,
          authority: LicenseAuthority.offlineLicense,
          licensedTo: 'choirudin@example.invalid',
        ),
        throwsArgumentError,
      );
      expect(
        () => OfflineLicenseInfo(
          state: OfflineLicenseState.active,
          authority: LicenseAuthority.offlineLicense,
          expiresAt: DateTime.utc(2026, 12, 1),
        ),
        throwsArgumentError,
      );
      expect(
        () => OfflineLicenseInfo(
          state: OfflineLicenseState.expired,
          authority: LicenseAuthority.offlineLicense,
          licensedTo: 'choirudin@example.invalid',
        ),
        throwsArgumentError,
      );
      expect(
        () => OfflineLicenseInfo(
          state: OfflineLicenseState.unlicensed,
          authority: LicenseAuthority.offlineLicense,
          expiresAt: DateTime.utc(2026, 12, 1),
        ),
        throwsArgumentError,
      );
      // A license that already passed its expiry cannot report as active.
      expect(
        () => OfflineLicenseInfo(
          state: OfflineLicenseState.active,
          authority: LicenseAuthority.offlineLicense,
          licensedTo: 'choirudin@example.invalid',
          expiresAt: DateTime.utc(2026, 9, 1),
          lastCheckedAt: DateTime.utc(2026, 9, 26),
        ),
        throwsArgumentError,
      );
      expect(
        () => OfflineLicenseInfo(
          state: OfflineLicenseState.active,
          authority: LicenseAuthority.offlineLicense,
          licensedTo: 'choirudin@example.invalid',
          expiresAt: DateTime(2026, 12, 1),
        ),
        throwsArgumentError,
      );
    });

    test('startTrial refuses overlapping trials', () {
      final model = _fixture();

      final trialing = model.startTrial(
        at: DateTime.utc(2026, 9, 26),
        endsAt: DateTime.utc(2026, 10, 3),
      );
      expect(
        trialing.trialPhaseAt(DateTime.utc(2026, 9, 27)),
        TrialPhase.active,
      );
      expect(trialing.trial.startedAt, DateTime.utc(2026, 9, 26));
      // Original snapshot stays untouched.
      expect(model.trialPhaseAt(DateTime.utc(2026, 9, 27)), TrialPhase.none);

      expect(
        () => trialing.startTrial(
          at: DateTime.utc(2026, 9, 27),
          endsAt: DateTime.utc(2026, 10, 4),
        ),
        throwsArgumentError,
      );
      expect(
        () => model.startTrial(
          at: DateTime.utc(2026, 9, 26),
          endsAt: DateTime.utc(2026, 9, 26),
        ),
        throwsArgumentError,
      );
      expect(
        () => model.startTrial(
          at: DateTime(2026, 9, 26),
          endsAt: DateTime.utc(2026, 10, 3),
        ),
        throwsArgumentError,
      );

      // A finished trial can start again once its end has passed.
      final finished = _fixture(
        trial: TrialInfo(
          startedAt: DateTime.utc(2026, 9, 1),
          endsAt: DateTime.utc(2026, 9, 20),
        ),
      );
      final restarted = finished.startTrial(
        at: DateTime.utc(2026, 9, 26),
        endsAt: DateTime.utc(2026, 10, 3),
      );
      expect(restarted.trial.startedAt, DateTime.utc(2026, 9, 26));
      expect(
        () => finished.startTrial(
          at: DateTime.utc(2026, 9, 19),
          endsAt: DateTime.utc(2026, 9, 28),
        ),
        throwsArgumentError,
      );
    });

    test(
      'cancellation follows renewal rules and confirms only after the effective time',
      () {
        final model = _fixture();

        expect(
          () => model.scheduleCancellation(
            at: DateTime.utc(2026, 9, 26),
            effectiveAt: DateTime.utc(2026, 9, 20),
          ),
          throwsArgumentError,
        );

        final scheduled = model.scheduleCancellation(
          at: DateTime.utc(2026, 9, 26),
          effectiveAt: DateTime.utc(2026, 10, 1),
          reason: 'Moving to free',
        );
        expect(scheduled.cancellation.state, CancellationState.scheduled);
        expect(scheduled.cancellation.requestedAt, DateTime.utc(2026, 9, 26));
        expect(scheduled.cancellation.effectiveAt, DateTime.utc(2026, 10, 1));
        expect(scheduled.cancellation.reason, 'Moving to free');
        expect(model.cancellation.state, CancellationState.none);

        expect(
          () => scheduled.scheduleCancellation(
            at: DateTime.utc(2026, 9, 27),
            effectiveAt: DateTime.utc(2026, 10, 2),
          ),
          throwsArgumentError,
        );
        expect(
          () => scheduled.confirmCancellation(at: DateTime.utc(2026, 9, 30)),
          throwsArgumentError,
        );
        expect(
          () => model.confirmCancellation(at: DateTime.utc(2026, 10, 1)),
          throwsArgumentError,
        );

        final cancelled = scheduled.confirmCancellation(
          at: DateTime.utc(2026, 10, 1),
        );
        expect(cancelled.cancellation.state, CancellationState.cancelled);
        expect(cancelled.cancellation.effectiveAt, DateTime.utc(2026, 10, 1));
        expect(
          () => cancelled.confirmCancellation(at: DateTime.utc(2026, 10, 1)),
          throwsArgumentError,
        );
        expect(
          () => cancelled.scheduleCancellation(
            at: DateTime.utc(2026, 10, 1),
            effectiveAt: DateTime.utc(2026, 11, 1),
          ),
          throwsArgumentError,
        );

        final manual = _fixture(renewal: RenewalInfo(mode: RenewalMode.manual));
        expect(
          manual
              .scheduleCancellation(
                at: DateTime.utc(2026, 9, 26),
                effectiveAt: DateTime.utc(2026, 10, 1),
              )
              .cancellation
              .state,
          CancellationState.scheduled,
        );

        final noRenewal = _fixture(
          renewal: RenewalInfo(mode: RenewalMode.none),
        );
        expect(
          () => noRenewal.scheduleCancellation(
            at: DateTime.utc(2026, 9, 26),
            effectiveAt: DateTime.utc(2026, 10, 1),
          ),
          throwsArgumentError,
        );
        final unknownRenewal = _fixture(
          renewal: RenewalInfo(mode: RenewalMode.unknown),
        );
        expect(
          () => unknownRenewal.scheduleCancellation(
            at: DateTime.utc(2026, 9, 26),
            effectiveAt: DateTime.utc(2026, 10, 1),
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      'grace requires auto renewal and clears when the payment resolves',
      () {
        final model = _fixture();

        expect(
          () => model.enterGrace(
            at: DateTime.utc(2026, 9, 26),
            endsAt: DateTime.utc(2026, 9, 25),
          ),
          throwsArgumentError,
        );
        final manual = _fixture(renewal: RenewalInfo(mode: RenewalMode.manual));
        expect(
          () => manual.enterGrace(
            at: DateTime.utc(2026, 9, 26),
            endsAt: DateTime.utc(2026, 9, 29),
          ),
          throwsArgumentError,
        );

        final inGrace = model.enterGrace(
          at: DateTime.utc(2026, 9, 26),
          endsAt: DateTime.utc(2026, 9, 29),
        );
        expect(
          inGrace.gracePhaseAt(DateTime.utc(2026, 9, 27)),
          GracePhase.active,
        );
        expect(model.gracePhaseAt(DateTime.utc(2026, 9, 27)), GracePhase.none);
        expect(
          () => inGrace.enterGrace(
            at: DateTime.utc(2026, 9, 27),
            endsAt: DateTime.utc(2026, 9, 30),
          ),
          throwsArgumentError,
        );
        expect(
          () => model.resolveGraceWithPayment(
            at: DateTime.utc(2026, 9, 26),
            nextRenewalAt: DateTime.utc(2026, 10, 1),
          ),
          throwsArgumentError,
        );
        expect(
          () => inGrace.resolveGraceWithPayment(
            at: DateTime.utc(2026, 9, 30),
            nextRenewalAt: DateTime.utc(2026, 10, 27),
          ),
          throwsArgumentError,
        );
        expect(
          () => inGrace.resolveGraceWithPayment(
            at: DateTime.utc(2026, 9, 27),
            nextRenewalAt: DateTime.utc(2026, 9, 26),
          ),
          throwsArgumentError,
        );

        final resolved = inGrace.resolveGraceWithPayment(
          at: DateTime.utc(2026, 9, 27),
          nextRenewalAt: DateTime.utc(2026, 10, 27),
        );
        expect(
          resolved.gracePhaseAt(DateTime.utc(2026, 9, 27)),
          GracePhase.none,
        );
        expect(resolved.renewal.mode, RenewalMode.auto);
        expect(resolved.renewal.renewsAt, DateTime.utc(2026, 10, 27));

        // A scheduled cancellation removes both grace paths.
        final scheduled = model.scheduleCancellation(
          at: DateTime.utc(2026, 9, 26),
          effectiveAt: DateTime.utc(2026, 10, 1),
        );
        expect(
          () => scheduled.enterGrace(
            at: DateTime.utc(2026, 9, 26),
            endsAt: DateTime.utc(2026, 9, 29),
          ),
          throwsArgumentError,
        );
        expect(
          () => scheduled.resolveGraceWithPayment(
            at: DateTime.utc(2026, 9, 27),
            nextRenewalAt: DateTime.utc(2026, 10, 27),
          ),
          throwsArgumentError,
        );
      },
    );

    test('aggregate separates all eight required fields fail-closed', () {
      final model = _fixture();

      expect(model.plan, isA<SubscriptionPlan>());
      expect(model.entitlements, isA<List<EntitlementGrant>>());
      expect(model.limits, isA<List<EntitlementLimit>>());
      expect(model.renewal, isA<RenewalInfo>());
      expect(model.cancellation, isA<CancellationInfo>());
      expect(model.trial, isA<TrialInfo>());
      expect(model.gracePeriod, isA<GracePeriodInfo>());
      expect(model.license, isA<OfflineLicenseInfo>());

      expect(
        () => _fixture(
          entitlements: [_grant('dup'), _grant('dup')],
          limits: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterSubscriptionEntitlementModel(
          plan: _plan(),
          entitlements: const [],
          limits: [
            EntitlementLimit(key: 'quota.credits', unit: 'credits', limit: 1),
          ],
          renewal: RenewalInfo(
            mode: RenewalMode.auto,
            renewsAt: DateTime.utc(2026, 10, 1),
          ),
          cancellation: CancellationInfo(state: CancellationState.none),
          trial: TrialInfo(),
          gracePeriod: GracePeriodInfo(),
          license: OfflineLicenseInfo(
            state: OfflineLicenseState.unknown,
            authority: LicenseAuthority.signedServer,
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}

AccountCenterSubscriptionEntitlementModel _fixture({
  SubscriptionPlan? plan,
  List<EntitlementGrant>? entitlements,
  List<EntitlementLimit>? limits,
  RenewalInfo? renewal,
  CancellationInfo? cancellation,
  TrialInfo? trial,
  GracePeriodInfo? gracePeriod,
  OfflineLicenseInfo? license,
}) => AccountCenterSubscriptionEntitlementModel(
  plan: plan ?? _plan(),
  entitlements:
      entitlements ??
      [
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
          source: EntitlementSource.offlineLicense,
          grantedAt: DateTime.utc(2026, 8, 1),
        ),
      ],
  limits:
      limits ??
      (entitlements == null
          ? [
              EntitlementLimit(
                key: 'quota.credits',
                unit: 'credits',
                limit: 1000,
              ),
              EntitlementLimit(key: 'feature.offline', unit: 'devices'),
            ]
          : const []),
  renewal:
      renewal ??
      RenewalInfo(mode: RenewalMode.auto, renewsAt: DateTime.utc(2026, 10, 1)),
  cancellation: cancellation ?? CancellationInfo(state: CancellationState.none),
  trial: trial ?? TrialInfo(),
  gracePeriod: gracePeriod ?? GracePeriodInfo(),
  license:
      license ??
      OfflineLicenseInfo(
        state: OfflineLicenseState.active,
        authority: LicenseAuthority.offlineLicense,
        licensedTo: 'choirudin@example.invalid',
        expiresAt: DateTime.utc(2026, 12, 1),
        lastCheckedAt: DateTime.utc(2026, 9, 26),
      ),
);

SubscriptionPlan _plan() => SubscriptionPlan(
  planId: 'plan-pro',
  displayName: 'Pro',
  tier: PlanTier.premium,
  cycle: PlanBillingCycle.monthly,
  price: PlanPrice(amount: 9.99, currency: 'usd'),
);

EntitlementGrant _grant(
  String key, {
  EntitlementState state = EntitlementState.granted,
  EntitlementSource source = EntitlementSource.signedServer,
}) => EntitlementGrant(
  key: key,
  state: state,
  source: source,
  grantedAt: DateTime.utc(2026, 9, 1),
  expiresAt: DateTime.utc(2026, 10, 1),
);
