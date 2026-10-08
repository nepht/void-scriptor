import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_billing_entitlement_health.dart';

/// A single billing & entitlement health entry. Each test flips exactly the one
/// thing it is about, so a test that flips nothing proves the pass path exists
/// and every other test proves one way the gate refuses to take it.
Sprint118BillingEntitlementHealthEntry _entry({
  String signal = 'checkout',
  String referenceState = 'payment_subscription_flow',
  String source =
      'docs/planning/v1.2/sprint_116_paypal_billing_certification.json',
  int window = 1440,
  List<String>? limitations,
  bool observed = false,
}) {
  return Sprint118BillingEntitlementHealthEntry(
    signal: signal,
    referenceState: referenceState,
    source: source,
    window: window,
    limitations: limitations ?? const <String>['live_observation_deferred'],
    observed: observed,
  );
}

Sprint118BillingEntitlementHealthReview _review({
  String releaseState =
      Sprint118BillingEntitlementHealthContract.delayedReleaseState,
  List<Sprint118BillingEntitlementHealthEntry>? entries,
}) {
  return Sprint118BillingEntitlementHealthReview(
    releaseState: releaseState,
    entries:
        entries ??
        Sprint118BillingEntitlementHealthContract.canonicalReview.entries,
  );
}

/// The canonical entries with exactly one signal replaced, so a test can flip a
/// single field without rebuilding the whole review.
List<Sprint118BillingEntitlementHealthEntry> _replacing(
  String signal,
  Sprint118BillingEntitlementHealthEntry replacement,
) {
  return <Sprint118BillingEntitlementHealthEntry>[
    for (final e
        in Sprint118BillingEntitlementHealthContract.canonicalReview.entries)
      if (e.signal == signal) replacement else e,
  ];
}

Sprint118BillingEntitlementHealthAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118BillingEntitlementHealthContract.requiredBaselineVerdict,
  String releaseState =
      Sprint118BillingEntitlementHealthContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118BillingEntitlementHealthContract.requiredCharterVerdict,
  int charterWindowMinutes =
      Sprint118BillingEntitlementHealthContract.charterWindowMinutes,
  List<String>? witnessSubscriptionEntitlementAcceptance,
  List<String>? witnessBillingAccountAcceptance,
  List<String>? witnessPaymentMethodAcceptance,
  List<String>? witnessInvoicesAcceptance,
  List<String>? witnessWebhookReconciliationAcceptance,
  List<String>? witnessStripeFields,
  List<String>? witnessPaypalFields,
  List<String>? witnessMidtransFields,
  List<String>? readableSources,
}) {
  return Sprint118BillingEntitlementHealthAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    witnessSubscriptionEntitlementAcceptance:
        witnessSubscriptionEntitlementAcceptance ??
        const <String>[
          'plan',
          'entitlements',
          'limits',
          'renewal',
          'cancellation',
          'trial',
          'grace_period',
          'license_state',
        ],
    witnessBillingAccountAcceptance:
        witnessBillingAccountAcceptance ??
        const <String>[
          'billing_identity',
          'currency',
          'tax',
          'billing_cycle',
          'charges',
          'credits',
          'estimated_label',
          'status',
        ],
    witnessPaymentMethodAcceptance:
        witnessPaymentMethodAcceptance ??
        const <String>[
          'provider_token_only',
          'masked_details',
          'default_method',
          'replace_remove',
          'region_availability',
          'reauth',
        ],
    witnessInvoicesAcceptance:
        witnessInvoicesAcceptance ??
        const <String>[
          'invoice_list',
          'receipt',
          'payment_status',
          'tax_info',
          'download',
          'refund_path',
          'dispute_path',
        ],
    witnessWebhookReconciliationAcceptance:
        witnessWebhookReconciliationAcceptance ??
        const <String>[
          'idempotency',
          'signature',
          'event_order',
          'retry',
          'grace_period',
          'cancellation',
          'refund',
          'entitlement_consistency',
        ],
    witnessStripeFields:
        witnessStripeFields ??
        const <String>[
          'customer',
          'subscription',
          'payment_method_tokens',
          'invoices',
          'webhooks',
          'refunds',
          'tax_metadata',
          'portal',
        ],
    witnessPaypalFields:
        witnessPaypalFields ??
        const <String>[
          'payment_subscription_flow',
          'redirects',
          'webhooks',
          'refunds',
          'region',
          'errors',
        ],
    witnessMidtransFields:
        witnessMidtransFields ??
        const <String>[
          'payment_methods',
          'redirects',
          'notifications',
          'signature',
          'region',
          'settlement',
          'errors',
        ],
    readableSources:
        readableSources ??
        Sprint118BillingEntitlementHealthContract.canonicalSources,
  );
}

Sprint118BillingEntitlementHealthReport _run(
  Sprint118BillingEntitlementHealthReview review, {
  Sprint118BillingEntitlementHealthAnchor? anchor,
}) {
  return const Sprint118BillingEntitlementHealthGate().evaluateWith(
    anchor ?? _anchor(),
    review,
  );
}

void main() {
  group('118.12 Billing & Entitlement Health', () {
    test('declares the canonical step, title, fields, and paths', () {
      expect(Sprint118BillingEntitlementHealthContract.canonicalStep, '118.12');
      expect(
        Sprint118BillingEntitlementHealthContract.title,
        'Billing & Entitlement Health',
      );
      expect(
        Sprint118BillingEntitlementHealthContract.manifestPath,
        'docs/planning/v1.3/sprint_118_billing_entitlement_health.json',
      );
      expect(Sprint118BillingEntitlementHealthContract.requiredFields, <String>[
        'signal',
        'reference_state',
        'source',
        'window',
        'limitations',
      ]);
      expect(
        Sprint118BillingEntitlementHealthContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(
        Sprint118BillingEntitlementHealthContract.requiredFields.length,
        5,
      );
      expect(
        Sprint118BillingEntitlementHealthContract.billingSignals.length,
        9,
      );
      expect(
        Sprint118BillingEntitlementHealthContract.canonicalSources.length,
        9,
      );
      // Every canonical signal maps to a committed evidence source.
      for (final s
          in Sprint118BillingEntitlementHealthContract.billingSignals) {
        expect(
          Sprint118BillingEntitlementHealthContract.sourceFor(s),
          isNotEmpty,
        );
      }
      // The reference-state vocabulary is the distinct union of the witness
      // vocabularies, in witness order.
      final vocab = Sprint118BillingEntitlementHealthContract.stateVocabulary(
        const <List<String>>[
          <String>['plan', 'entitlements', 'renewal'],
          <String>['entitlements', 'billing_identity'],
          <String>['masked_details', 'reauth'],
          <String>['invoice_list', 'refund_path'],
          <String>['idempotency', 'signature'],
          <String>['webhooks', 'refunds'],
          <String>['redirects', 'webhooks'],
          <String>['notifications', 'settlement'],
        ],
      );
      expect(vocab, <String>[
        'plan',
        'entitlements',
        'renewal',
        'billing_identity',
        'masked_details',
        'reauth',
        'invoice_list',
        'refund_path',
        'idempotency',
        'signature',
        'webhooks',
        'refunds',
        'redirects',
        'notifications',
        'settlement',
      ]);
    });

    test('canonical review covers the nine signals and claims no live '
        'observation', () {
      final review = Sprint118BillingEntitlementHealthContract.canonicalReview;
      expect(review.signals.length, 9);
      expect(review.signals.toSet(), <String>{
        'checkout',
        'webhook',
        'idempotency',
        'invoice',
        'entitlement',
        'renewal',
        'cancellation',
        'refund',
        'dispute',
      });
      for (final entry in review.entries) {
        expect(entry.observed, isFalse);
        expect(entry.window, greaterThan(0));
        expect(entry.limitations, isNotEmpty);
      }
      expect(review.observedCount, 0);
    });

    test('passes on the canonical review', () {
      final report = _run(_review());
      expect(report.state, Sprint118BillingEntitlementHealthState.pass);
      expect(report.verdict, 'BILLING_ENTITLEMENT_HEALTH_VERIFIED_LOCAL');
      expect(report.reviewVerified, isTrue);
      expect(report.declaredSignals.length, 9);
      expect(report.observedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118BillingEntitlementHealthGate().evaluateWith(
        null,
        _review(),
      );
      expect(report.state, Sprint118BillingEntitlementHealthState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_BILLING_ENTITLEMENT_HEALTH_EVIDENCE_UNREADABLE',
      );
      expect(
        report.blockers,
        contains('committed_billing_entitlement_health_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118BillingEntitlementHealthState.blocked);
      expect(
        report.blockers,
        contains('baseline_not_frozen:SPRINT_118_BASELINE_EVIDENCE_VIOLATION'),
      );
    });

    test('blocks when the 118.2 charter is not complete', () {
      final report = _run(
        _review(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE'),
      );
      expect(report.state, Sprint118BillingEntitlementHealthState.blocked);
      expect(
        report.blockers,
        contains('charter_not_complete:CHARTER_INCOMPLETE'),
      );
    });

    test('fails when the release state disagrees with the baseline', () {
      final report = _run(
        _review(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'GA_DELAYED'),
      );
      expect(report.state, Sprint118BillingEntitlementHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a signal claims observation on the delayed path', () {
      final report = _run(
        _review(
          entries: _replacing(
            'checkout',
            _entry(
              signal: 'checkout',
              referenceState: 'payment_subscription_flow',
              source:
                  'docs/planning/v1.2/sprint_116_paypal_billing_certification.json',
              observed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118BillingEntitlementHealthState.fail);
      expect(
        report.violations,
        contains('billing_claims_observation_without_release:checkout'),
      );
    });

    test('fails when an entry carries an unknown reference state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'idempotency',
            _entry(
              signal: 'idempotency',
              referenceState: 'SOMETHING_ELSE',
              source:
                  'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118BillingEntitlementHealthState.fail);
      expect(
        report.violations,
        contains('entry_unknown_reference_state:idempotency:SOMETHING_ELSE'),
      );
    });

    test('fails when an entry cites unreadable evidence', () {
      final report = _run(
        _review(
          entries: _replacing(
            'dispute',
            _entry(
              signal: 'dispute',
              referenceState: 'dispute_path',
              source: 'docs/planning/missing.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118BillingEntitlementHealthState.fail);
      expect(
        report.violations,
        contains('entry_unreadable_source:dispute:docs/planning/missing.json'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _review(
          entries: _replacing(
            'checkout',
            _entry(signal: 'checkout', referenceState: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118BillingEntitlementHealthState.fail);
      expect(
        report.violations,
        contains('entry_blank_reference_state:checkout'),
      );
    });

    test('fails when an entry has no limitation', () {
      final report = _run(
        _review(
          entries: _replacing(
            'refund',
            _entry(
              signal: 'refund',
              referenceState: 'refunds',
              source:
                  'docs/planning/v1.2/sprint_116_stripe_billing_certification.json',
              limitations: const <String>[],
            ),
          ),
        ),
      );
      expect(report.state, Sprint118BillingEntitlementHealthState.fail);
      expect(report.violations, contains('entry_no_limitations:refund'));
    });

    test('fails when a window is non-positive', () {
      final report = _run(
        _review(
          entries: _replacing(
            'invoice',
            _entry(
              signal: 'invoice',
              referenceState: 'invoice_list',
              source:
                  'docs/planning/v1.2/sprint_115_invoices_receipts_billing_history.json',
              window: 0,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118BillingEntitlementHealthState.fail);
      expect(report.violations, contains('entry_nonpositive_window:invoice:0'));
    });

    test('fails when a window exceeds the charter window', () {
      final report = _run(
        _review(
          entries: _replacing(
            'entitlement',
            _entry(
              signal: 'entitlement',
              referenceState: 'entitlements',
              source:
                  'docs/planning/v1.2/sprint_115_subscription_entitlement_model.json',
              window: 999999,
            ),
          ),
        ),
        anchor: _anchor(charterWindowMinutes: 60480),
      );
      expect(report.state, Sprint118BillingEntitlementHealthState.fail);
      expect(
        report.violations,
        contains('entry_window_exceeds_charter:entitlement:999999:60480'),
      );
    });

    test('fails on a duplicate signal', () {
      final entries = <Sprint118BillingEntitlementHealthEntry>[
        ...Sprint118BillingEntitlementHealthContract.canonicalReview.entries,
        _entry(signal: 'checkout'),
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118BillingEntitlementHealthState.fail);
      expect(report.violations, contains('signal_duplicate:checkout'));
    });

    test('fails when a canonical signal is missing', () {
      final entries = <Sprint118BillingEntitlementHealthEntry>[
        for (final e
            in Sprint118BillingEntitlementHealthContract
                .canonicalReview
                .entries)
          if (e.signal != 'renewal') e,
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118BillingEntitlementHealthState.fail);
      expect(report.violations, contains('signal_missing:renewal'));
    });

    test('fails when an entry names an unknown signal', () {
      final report = _run(
        _review(
          entries: _replacing(
            'checkout',
            _entry(
              signal: 'unknown_signal',
              referenceState: 'payment_subscription_flow',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118BillingEntitlementHealthState.fail);
      // The replacement also removes the real 'checkout' entry, so both the
      // unknown-signal and the missing-signal violations are expected.
      expect(report.violations, contains('signal_unknown:unknown_signal'));
      expect(report.violations, contains('signal_missing:checkout'));
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.2/sprint_115_subscription_entitlement_model.json',
          ],
        ),
      );
      expect(report.state, Sprint118BillingEntitlementHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('blocks when the witness vocabulary is empty', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          witnessSubscriptionEntitlementAcceptance: const <String>[],
          witnessBillingAccountAcceptance: const <String>[],
          witnessPaymentMethodAcceptance: const <String>[],
          witnessInvoicesAcceptance: const <String>[],
          witnessWebhookReconciliationAcceptance: const <String>[],
          witnessStripeFields: const <String>[],
          witnessPaypalFields: const <String>[],
          witnessMidtransFields: const <String>[],
        ),
      );
      expect(report.state, Sprint118BillingEntitlementHealthState.blocked);
      expect(report.blockers, contains('upstream_billing_vocabulary_missing'));
    });

    test('sourceFor maps each signal to its committed evidence source', () {
      expect(
        Sprint118BillingEntitlementHealthContract.sourceFor('checkout'),
        'docs/planning/v1.2/sprint_116_paypal_billing_certification.json',
      );
      expect(
        Sprint118BillingEntitlementHealthContract.sourceFor('dispute'),
        'docs/planning/v1.2/sprint_115_invoices_receipts_billing_history.json',
      );
      expect(
        Sprint118BillingEntitlementHealthContract.sourceFor('unknown'),
        '',
      );
    });
  });
}
