import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_billing_entitlement_webhook_reconciliation.dart';

void main() {
  group('116.40 Billing, Entitlement & Webhook Reconciliation', () {
    test('locks the eight reconciliation acceptance areas', () {
      expect(
        Sprint116BillingReconciliationContract.requiredAcceptance,
        <String>[
          'idempotency',
          'signature',
          'event_order',
          'retry',
          'grace_period',
          'cancellation',
          'refund',
          'entitlement_consistency',
        ],
      );
    });

    test(
      'idempotent redelivery and out-of-order arrival apply once in event order',
      () {
        const renewal = Sprint116WebhookEvent(
          eventId: 'evt_renew_1',
          providerId: 'synthetic_local',
          sequence: 1,
          occurredAtEpochMs: 1700000000000,
          signatureStatus: 'VERIFIED',
          eventType: 'renewal',
          periodEndEpochMs: 1702592000000,
        );
        const paymentFailed = Sprint116WebhookEvent(
          eventId: 'evt_pay_2',
          providerId: 'synthetic_local',
          sequence: 2,
          occurredAtEpochMs: 1700000100000,
          signatureStatus: 'VERIFIED',
          eventType: 'payment_failed',
          retryCount: 2,
          graceEndEpochMs: 1700604900000,
        );
        const cancellation = Sprint116WebhookEvent(
          eventId: 'evt_cancel_3',
          providerId: 'synthetic_local',
          sequence: 3,
          occurredAtEpochMs: 1700000200000,
          signatureStatus: 'VERIFIED',
          eventType: 'cancellation',
          cancelAtPeriodEnd: false,
        );
        const offline = Sprint116OfflineEntitlement(
          status: 'revoked',
          entitlementUntilEpochMs: 1700000200000,
          asOfEpochMs: 1700000300000,
        );

        final arrivalA = Sprint116BillingReconciliation().reconcile(
          events: <Sprint116WebhookEvent>[
            paymentFailed,
            renewal,
            cancellation,
            renewal,
          ],
          offlineEntitlement: offline,
        );
        final arrivalB = Sprint116BillingReconciliation().reconcile(
          events: <Sprint116WebhookEvent>[
            cancellation,
            renewal,
            paymentFailed,
            renewal,
          ],
          offlineEntitlement: offline,
        );

        expect(arrivalA.state, Sprint116ReconciliationState.pass);
        expect(arrivalA.invalidRecords, isEmpty);
        expect(arrivalA.appliedOrder, <String>[
          'evt_renew_1',
          'evt_pay_2',
          'evt_cancel_3',
        ]);
        expect(arrivalA.dedupedEventIds, <String>['evt_renew_1']);
        expect(arrivalB.appliedOrder, arrivalA.appliedOrder);
        expect(arrivalB.dedupedEventIds, <String>['evt_renew_1']);
        expect(arrivalB.effectiveStatus, 'revoked');
        expect(arrivalA.entitlementUntilEpochMs, 1700000200000);
      },
    );

    test('unsigned events and exhausted retries fail closed', () {
      final events = <Sprint116WebhookEvent>[
        const Sprint116WebhookEvent(
          eventId: 'evt_unsigned_1',
          providerId: 'synthetic_local',
          sequence: 1,
          occurredAtEpochMs: 1700000000000,
          signatureStatus: 'MISSING',
          eventType: 'renewal',
          periodEndEpochMs: 1702592000000,
        ),
        const Sprint116WebhookEvent(
          eventId: 'evt_retry_exhausted_2',
          providerId: 'synthetic_local',
          sequence: 2,
          occurredAtEpochMs: 1700000100000,
          signatureStatus: 'VERIFIED',
          eventType: 'payment_failed',
          retryCount: 6,
          graceEndEpochMs: 1700604900000,
        ),
        const Sprint116WebhookEvent(
          eventId: 'evt_renew_3',
          providerId: 'synthetic_local',
          sequence: 3,
          occurredAtEpochMs: 1700000300000,
          signatureStatus: 'VERIFIED',
          eventType: 'renewal',
          periodEndEpochMs: 1702592000000,
        ),
      ];
      final report = Sprint116BillingReconciliation().reconcile(
        events: events,
        offlineEntitlement: const Sprint116OfflineEntitlement(
          status: 'active',
          entitlementUntilEpochMs: 1702592000000,
          asOfEpochMs: 1700000400000,
        ),
      );

      expect(report.state, Sprint116ReconciliationState.fail);
      expect(report.invalidRecords, contains('signature:evt_unsigned_1'));
      expect(report.invalidRecords, contains('retry:evt_retry_exhausted_2'));
      expect(report.rejectedEventIds, <String>[
        'evt_unsigned_1',
        'evt_retry_exhausted_2',
      ]);
      expect(report.appliedOrder, <String>['evt_renew_3']);
      expect(report.effectiveStatus, 'active');
    });

    test(
      'grace period is time-bounded and offline overclaim fails consistency',
      () {
        final events = <Sprint116WebhookEvent>[
          const Sprint116WebhookEvent(
            eventId: 'evt_renew_1',
            providerId: 'synthetic_local',
            sequence: 1,
            occurredAtEpochMs: 1700000000000,
            signatureStatus: 'VERIFIED',
            eventType: 'renewal',
            periodEndEpochMs: 1702592000000,
          ),
          const Sprint116WebhookEvent(
            eventId: 'evt_pay_2',
            providerId: 'synthetic_local',
            sequence: 2,
            occurredAtEpochMs: 1700000100000,
            signatureStatus: 'VERIFIED',
            eventType: 'payment_failed',
            graceEndEpochMs: 1700604900000,
          ),
        ];

        final withinGrace = Sprint116BillingReconciliation().reconcile(
          events: events,
          offlineEntitlement: const Sprint116OfflineEntitlement(
            status: 'active_grace',
            entitlementUntilEpochMs: 1700604900000,
            asOfEpochMs: 1700100000000,
          ),
        );
        expect(withinGrace.state, Sprint116ReconciliationState.pass);
        expect(withinGrace.effectiveStatus, 'active_grace');
        expect(withinGrace.entitlementUntilEpochMs, 1700604900000);

        final pastGrace = Sprint116BillingReconciliation().reconcile(
          events: events,
          offlineEntitlement: const Sprint116OfflineEntitlement(
            status: 'active_grace',
            entitlementUntilEpochMs: 1700604900000,
            asOfEpochMs: 1701000000000,
          ),
        );
        expect(pastGrace.state, Sprint116ReconciliationState.fail);
        expect(pastGrace.effectiveStatus, 'lapsed');
        expect(
          pastGrace.invalidRecords,
          contains('entitlement_consistency:offline'),
        );

        final missingSnapshot = Sprint116BillingReconciliation().reconcile(
          events: events,
        );
        expect(missingSnapshot.state, Sprint116ReconciliationState.fail);
        expect(
          missingSnapshot.invalidRecords,
          contains('entitlement_consistency:offline'),
        );
      },
    );

    test('cancellation and refund revoke the offline entitlement', () {
      const renewal = Sprint116WebhookEvent(
        eventId: 'evt_renew_1',
        providerId: 'synthetic_local',
        sequence: 1,
        occurredAtEpochMs: 1700000000000,
        signatureStatus: 'VERIFIED',
        eventType: 'renewal',
        periodEndEpochMs: 1702592000000,
      );

      final scheduled = Sprint116BillingReconciliation().reconcile(
        events: <Sprint116WebhookEvent>[
          renewal,
          const Sprint116WebhookEvent(
            eventId: 'evt_cancel_2',
            providerId: 'synthetic_local',
            sequence: 2,
            occurredAtEpochMs: 1700000200000,
            signatureStatus: 'VERIFIED',
            eventType: 'cancellation',
            cancelAtPeriodEnd: true,
            periodEndEpochMs: 1702592000000,
          ),
        ],
        offlineEntitlement: const Sprint116OfflineEntitlement(
          status: 'cancelled_scheduled',
          entitlementUntilEpochMs: 1702592000000,
          asOfEpochMs: 1700000300000,
        ),
      );
      expect(scheduled.state, Sprint116ReconciliationState.pass);
      expect(scheduled.effectiveStatus, 'cancelled_scheduled');

      final refunded = Sprint116BillingReconciliation().reconcile(
        events: <Sprint116WebhookEvent>[
          renewal,
          const Sprint116WebhookEvent(
            eventId: 'evt_refund_2',
            providerId: 'synthetic_local',
            sequence: 2,
            occurredAtEpochMs: 1700000250000,
            signatureStatus: 'VERIFIED',
            eventType: 'refund',
          ),
        ],
        offlineEntitlement: const Sprint116OfflineEntitlement(
          status: 'revoked',
          entitlementUntilEpochMs: 1700000250000,
          asOfEpochMs: 1700000300000,
        ),
      );
      expect(refunded.state, Sprint116ReconciliationState.pass);
      expect(refunded.effectiveStatus, 'revoked');
      expect(refunded.entitlementUntilEpochMs, 1700000250000);

      final overclaim = Sprint116BillingReconciliation().reconcile(
        events: <Sprint116WebhookEvent>[
          renewal,
          const Sprint116WebhookEvent(
            eventId: 'evt_refund_2',
            providerId: 'synthetic_local',
            sequence: 2,
            occurredAtEpochMs: 1700000250000,
            signatureStatus: 'VERIFIED',
            eventType: 'refund',
          ),
        ],
        offlineEntitlement: const Sprint116OfflineEntitlement(
          status: 'active',
          entitlementUntilEpochMs: 1702592000000,
          asOfEpochMs: 1700000300000,
        ),
      );
      expect(overclaim.state, Sprint116ReconciliationState.fail);
      expect(
        overclaim.invalidRecords,
        contains('entitlement_consistency:offline'),
      );
    });

    test(
      'manifest fixture reconciles locally without live provider claims or secrets',
      () {
        final report = Sprint116BillingReconciliation().reconcile();
        expect(report.state, Sprint116ReconciliationState.pass);
        expect(report.invalidRecords, isEmpty);
        expect(report.effectiveStatus, 'active_grace');
        expect(report.externalGates, 'DEFERRED-EXTERNAL');

        final manifest =
            jsonDecode(
                  File(
                    Sprint116BillingReconciliationContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.40');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        expect(manifest['live_provider_verification'], false);
        expect(manifest['required_acceptance'], <String>[
          'idempotency',
          'signature',
          'event_order',
          'retry',
          'grace_period',
          'cancellation',
          'refund',
          'entitlement_consistency',
        ]);
        expect(manifest['offline_entitlement'], isA<Map<String, dynamic>>());
        final events = manifest['events'] as List<dynamic>;
        expect(events, isNotEmpty);
        for (final event in events) {
          final map = event as Map<String, dynamic>;
          expect(map['signature_status'], 'VERIFIED');
          expect(
            (map['retry_count'] as num).toInt(),
            lessThanOrEqualTo(
              Sprint116BillingReconciliationContract.maxRetryCount,
            ),
          );
          expect(map['provider_id'], 'synthetic_local');
        }
        expect(
          manifest.keys
              .where(
                (key) =>
                    key.toLowerCase().contains('secret') ||
                    key.toLowerCase().contains('api_key') ||
                    key.toLowerCase().contains('password') ||
                    key.toLowerCase().contains('webhook_url'),
              )
              .toList(),
          isEmpty,
        );
      },
    );
  });
}
