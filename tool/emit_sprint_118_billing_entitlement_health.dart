// Emit the 118.12 Billing & Entitlement Health record from the gate's own
// report.
//
// The committed 118.4 baseline, 118.2 charter, 115.34 subscription &
// entitlement model, 115.35 billing account & cost summary, 115.36 payment
// method abstraction, 115.37 invoices/receipts/billing history, 116.40 billing
// entitlement & webhook reconciliation, 116.36 Stripe billing certification,
// 116.37 PayPal billing certification, and 116.38 Midtrans billing
// certification witnesses are the evidence *input*: the gate reads them and
// decides whether the declared review is well-formed. This file is the
// *output*: the gate's measured verdict plus the review's canonical fields, all
// derived from the contract constants and the gate's own report. Nothing here
// is typed by hand, so the record cannot be made to agree with itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_billing_entitlement_health.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_billing_entitlement_health.dart';

Map<String, Object?> _entry(Sprint118BillingEntitlementHealthEntry entry) =>
    <String, Object?>{
      'signal': entry.signal,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'window': entry.window,
      'limitations': entry.limitations,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118BillingEntitlementHealthGate();
  final report = gate.evaluate();
  final anchor = const Sprint118BillingEntitlementHealthLoader().loadAnchor();
  final review = Sprint118BillingEntitlementHealthContract.canonicalReview;

  final record = <String, Object?>{
    'canonical_step': Sprint118BillingEntitlementHealthContract.canonicalStep,
    'title': Sprint118BillingEntitlementHealthContract.title,
    'document_role': 'billing-entitlement-health-review-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'review_verified': report.reviewVerified,
    'required_fields': Sprint118BillingEntitlementHealthContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed witnesses this review is anchored to, from the contract
    // constants -- not retyped, so the record cannot cite a path the gate never
    // opens.
    'evidence_sources': <String, String>{
      'baseline':
          Sprint118BillingEntitlementHealthContract.baselineManifestPath,
      'charter': Sprint118BillingEntitlementHealthContract.charterManifestPath,
      'subscription_entitlement': Sprint118BillingEntitlementHealthContract
          .subscriptionEntitlementManifestPath,
      'billing_account':
          Sprint118BillingEntitlementHealthContract.billingAccountManifestPath,
      'payment_method':
          Sprint118BillingEntitlementHealthContract.paymentMethodManifestPath,
      'invoices':
          Sprint118BillingEntitlementHealthContract.invoicesManifestPath,
      'webhook_reconciliation': Sprint118BillingEntitlementHealthContract
          .webhookReconciliationManifestPath,
      'stripe': Sprint118BillingEntitlementHealthContract.stripeManifestPath,
      'paypal': Sprint118BillingEntitlementHealthContract.paypalManifestPath,
      'midtrans':
          Sprint118BillingEntitlementHealthContract.midtransManifestPath,
    },
    // Facts read from the committed witnesses, never typed.
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'witness_subscription_entitlement_acceptance':
        anchor?.witnessSubscriptionEntitlementAcceptance,
    'witness_billing_account_acceptance':
        anchor?.witnessBillingAccountAcceptance,
    'witness_payment_method_acceptance': anchor?.witnessPaymentMethodAcceptance,
    'witness_invoices_acceptance': anchor?.witnessInvoicesAcceptance,
    'witness_webhook_reconciliation_acceptance':
        anchor?.witnessWebhookReconciliationAcceptance,
    'witness_stripe_fields': anchor?.witnessStripeFields,
    'witness_paypal_fields': anchor?.witnessPaypalFields,
    'witness_midtrans_fields': anchor?.witnessMidtransFields,
    'readable_source_count': anchor?.readableSources.length,
    // The review itself, derived from the contract constants.
    'declared_signal_count': report.declaredSignals.length,
    'declared_signals': report.declaredSignals,
    'canonical_signals':
        Sprint118BillingEntitlementHealthContract.billingSignals,
    'canonical_sources':
        Sprint118BillingEntitlementHealthContract.canonicalSources,
    'observed_count': report.observedCount,
    'entries': review.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.4 baseline, 118.2 charter, 115.34 subscription & entitlement model, 115.35 billing account & cost summary, 115.36 payment method abstraction, 115.37 invoices/receipts/billing history, 116.40 billing entitlement & webhook reconciliation, 116.36 Stripe billing certification, 116.37 PayPal billing certification, and 116.38 Midtrans billing certification evidence. A pass means the declared review carries all five required fields for every one of the nine canonical billing & entitlement signals; it does not run any checkout, webhook delivery, invoice settlement, entitlement mutation, renewal charge, cancellation, refund, or dispute, and it does not authorize any release.',
      'The review is written against the delayed release state (GA_DELAYED). No release ran, so no entry observes a billing reading and every entry carries at least one stated limitation.',
      'The gate reads the committed witnesses directly, derives its reference-state vocabulary from the 115.34, 115.35, 115.36, and 115.37 acceptance items, the 116.40 required acceptance items, and the 116.36/116.37/116.38 required fields, and verifies each entry cites a committed, readable evidence source; an unreadable witness or an unfrozen baseline keeps the review blocked rather than assumed.',
      'The reference-state vocabulary is the distinct union of the subscription & entitlement, billing account, payment method, invoices, webhook reconciliation, Stripe, PayPal, and Midtrans witness vocabularies, read from the committed witnesses, so the review and the billing contracts cannot drift apart silently.',
      'Live checkout, provider webhook delivery, invoice settlement, entitlement mutation, renewal charging, cancellation, refund, dispute handling, provider certification, provider exposure, and publication remain DEFERRED-EXTERNAL; nothing here is performed or authorized.',
    ],
    'external_gates': <String>[
      'live checkout session creation',
      'provider webhook delivery and signature verification',
      'invoice settlement',
      'entitlement mutation',
      'subscription renewal charge',
      'subscription cancellation',
      'refund execution',
      'dispute handling',
      'payment provider credential and token access',
      'billing provider certification evidence',
      'provider exposure',
      'public release publication',
    ],
  };

  final target = File(Sprint118BillingEntitlementHealthContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );

  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('release_state=${report.releaseState}');
  stdout.writeln('declared_signals=${report.declaredSignals.length}');
  stdout.writeln('observed_count=${report.observedCount}');
  stdout.writeln(
    'readable_source_count=${anchor?.readableSources.length ?? 0}',
  );
  stdout.writeln('blockers=${report.blockers.length}');
  stdout.writeln('violations=${report.violations.length}');
  stdout.writeln('open_items=${report.openItems.length}');
  stdout.writeln('written=${target.path}');
}
