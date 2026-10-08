/// Fail-closed billing & entitlement health review for roadmap step 118.12 --
/// Billing & Entitlement Health.
///
/// Objective (external canonical `sprint_118.json`): monitor checkout,
/// webhooks, idempotency, invoices, entitlement, renewal, cancellation,
/// refunds, and disputes. The canonical signal list is exactly nine items:
/// `checkout`, `webhook`, `idempotency`, `invoice`, `entitlement`, `renewal`,
/// `cancellation`, `refund`, and `dispute`.
///
/// This is the review the delayed corrective path (Sprint 118 on `GA_DELAYED`)
/// registers *before* any live billing observation runs. The gate answers a
/// single question: does the declared review carry, for every canonical billing
/// signal, a reference state drawn from the committed billing witnesses, a
/// committed readable evidence source, a positive window bounded by the
/// charter, and a stated limitation -- while claiming no live observation?
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`). A review built on
///   a baseline that did not freeze describes billing readings nobody measured.
/// * The committed 118.2 charter anchor must be complete
///   (`CHARTER_COMPLETE_LOCAL`); the review is bound to the charter's declared
///   observation window.
/// * The review's release state must agree with the baseline anchor.
/// * On the delayed path no signal may claim an observation: with no release, an
///   observation describes a checkout, webhook, invoice, or entitlement reading
///   that was never fetched. Refused by name, per signal.
/// * Every canonical signal must be present exactly once, must carry a
///   non-blank reference state, a committed readable source, a positive window
///   no larger than the charter window, and at least one stated limitation.
/// * Every reference state must be drawn from the committed subscription &
///   entitlement model (115.34), the committed billing account & cost summary
///   (115.35), the committed payment method abstraction (115.36), the committed
///   invoices, receipts & billing history (115.37), the committed billing,
///   entitlement & webhook reconciliation (116.40), the committed Stripe
///   billing certification (116.36), the committed PayPal billing certification
///   (116.37), and the committed Midtrans billing certification (116.38), so the
///   review and the billing contracts cannot drift apart.
///
/// Live checkout, provider webhook delivery, invoice settlement, entitlement
/// mutation, renewal charging, cancellation, refund, dispute handling, provider
/// certification, provider exposure, release authorization, and publication
/// remain `DEFERRED-EXTERNAL`; this review freezes local declared state and
/// executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a billing & entitlement health review can rest in.
/// `blocked` is the honest resting state for "this review cannot yet be
/// trusted", and it is distinct from `fail`, which means the review contradicts
/// its own evidence.
enum Sprint118BillingEntitlementHealthState { pass, fail, blocked }

/// One billing & entitlement entry: the declared reference for a single
/// canonical signal, with the boundary it was frozen under.
class Sprint118BillingEntitlementHealthEntry {
  const Sprint118BillingEntitlementHealthEntry({
    required this.signal,
    required this.referenceState,
    required this.source,
    required this.window,
    required this.limitations,
    this.observed = false,
  });

  /// The billing & entitlement signal, drawn from the canonical signal
  /// vocabulary.
  final String signal;

  /// The declared reference state, drawn from the committed billing witness
  /// vocabulary.
  final String referenceState;

  /// The committed evidence file this reference is anchored to.
  final String source;

  /// The measurement window in minutes.
  final int window;

  /// The limitations the reference was frozen under. At least one is required so
  /// the review cannot imply live billing reads.
  final List<String> limitations;

  /// Whether the entry claims an observed value. On the delayed path this must
  /// stay `false`.
  final bool observed;
}

/// The declared review. `entries` is the review surface for the delayed
/// corrective path; on that path no entry may claim an observation.
class Sprint118BillingEntitlementHealthReview {
  const Sprint118BillingEntitlementHealthReview({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118BillingEntitlementHealthEntry> entries;

  List<String> get signals => <String>[
    for (final entry in entries) entry.signal,
  ];

  int get observedCount => entries.where((entry) => entry.observed).length;
}

/// What the committed 118.4 baseline, 118.2 charter, and billing witnesses
/// actually say. A review is only as honest as the witnesses it reads.
class Sprint118BillingEntitlementHealthAnchor {
  const Sprint118BillingEntitlementHealthAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.charterWindowMinutes,
    required this.witnessSubscriptionEntitlementAcceptance,
    required this.witnessBillingAccountAcceptance,
    required this.witnessPaymentMethodAcceptance,
    required this.witnessInvoicesAcceptance,
    required this.witnessWebhookReconciliationAcceptance,
    required this.witnessStripeFields,
    required this.witnessPaypalFields,
    required this.witnessMidtransFields,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;
  final int charterWindowMinutes;

  /// The acceptance items the committed 115.34 subscription & entitlement model
  /// declares.
  final List<String> witnessSubscriptionEntitlementAcceptance;

  /// The acceptance items the committed 115.35 billing account & cost summary
  /// declares.
  final List<String> witnessBillingAccountAcceptance;

  /// The acceptance items the committed 115.36 payment method abstraction
  /// declares.
  final List<String> witnessPaymentMethodAcceptance;

  /// The acceptance items the committed 115.37 invoices, receipts & billing
  /// history declares.
  final List<String> witnessInvoicesAcceptance;

  /// The required acceptance items the committed 116.40 billing, entitlement &
  /// webhook reconciliation declares.
  final List<String> witnessWebhookReconciliationAcceptance;

  /// The required fields the committed 116.36 Stripe billing certification
  /// declares.
  final List<String> witnessStripeFields;

  /// The required fields the committed 116.37 PayPal billing certification
  /// declares.
  final List<String> witnessPaypalFields;

  /// The required fields the committed 116.38 Midtrans billing certification
  /// declares.
  final List<String> witnessMidtransFields;

  /// The committed evidence paths present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is well-formed; `blocked` means
/// it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118BillingEntitlementHealthReport {
  const Sprint118BillingEntitlementHealthReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.missingFields = const <String>[],
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredSignals = const <String>[],
    this.observedCount = 0,
  });

  final Sprint118BillingEntitlementHealthState state;
  final String verdict;
  final String releaseState;
  final List<String> missingFields;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredSignals;
  final int observedCount;

  /// Whether the review may be treated as well-formed. Only a genuine `pass`
  /// allows it.
  bool get reviewVerified =>
      state == Sprint118BillingEntitlementHealthState.pass;

  String get externalGates =>
      Sprint118BillingEntitlementHealthContract.externalGates;
}

/// The fixed vocabulary of step 118.12, kept in one place so the loader, the
/// gate, and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118BillingEntitlementHealthContract {
  const Sprint118BillingEntitlementHealthContract._();

  static const String canonicalStep = '118.12';
  static const String title = 'Billing & Entitlement Health';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_billing_entitlement_health.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this review is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter that declares the observation window.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 115.34 subscription & entitlement model that declares the
  /// entitlement, renewal, and cancellation acceptance items.
  static const String subscriptionEntitlementManifestPath =
      'docs/planning/v1.2/sprint_115_subscription_entitlement_model.json';

  /// The committed 115.35 billing account & cost summary that declares the
  /// billing cycle acceptance item.
  static const String billingAccountManifestPath =
      'docs/planning/v1.2/sprint_115_billing_account_cost_summary.json';

  /// The committed 115.36 payment method abstraction that declares the reauth
  /// acceptance item.
  static const String paymentMethodManifestPath =
      'docs/planning/v1.2/sprint_115_payment_method_abstraction.json';

  /// The committed 115.37 invoices, receipts & billing history that declares the
  /// invoice list and dispute path acceptance items.
  static const String invoicesManifestPath =
      'docs/planning/v1.2/sprint_115_invoices_receipts_billing_history.json';

  /// The committed 116.40 billing, entitlement & webhook reconciliation that
  /// declares the idempotency acceptance item.
  static const String webhookReconciliationManifestPath =
      'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json';

  /// The committed 116.36 Stripe billing certification that declares the
  /// webhooks and refunds fields.
  static const String stripeManifestPath =
      'docs/planning/v1.2/sprint_116_stripe_billing_certification.json';

  /// The committed 116.37 PayPal billing certification that declares the
  /// checkout and refunds fields.
  static const String paypalManifestPath =
      'docs/planning/v1.2/sprint_116_paypal_billing_certification.json';

  /// The committed 116.38 Midtrans billing certification that declares the
  /// signature field.
  static const String midtransManifestPath =
      'docs/planning/v1.2/sprint_116_midtrans_billing_certification.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The five canonical entry fields from `sprint_118.json` step 118.12.
  static const List<String> requiredFields = <String>[
    'signal',
    'reference_state',
    'source',
    'window',
    'limitations',
  ];

  /// The nine canonical billing & entitlement signals the objective names.
  static const List<String> billingSignals = <String>[
    'checkout',
    'webhook',
    'idempotency',
    'invoice',
    'entitlement',
    'renewal',
    'cancellation',
    'refund',
    'dispute',
  ];

  /// The charter's declared observation window, in minutes: 42 days.
  static const int charterWindowMinutes = 42 * 24 * 60;

  /// The committed evidence source registered for each canonical signal, in
  /// canonical-signal order.
  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.2/sprint_116_paypal_billing_certification.json',
    'docs/planning/v1.2/sprint_116_stripe_billing_certification.json',
    'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
    'docs/planning/v1.2/sprint_115_invoices_receipts_billing_history.json',
    'docs/planning/v1.2/sprint_115_subscription_entitlement_model.json',
    'docs/planning/v1.2/sprint_115_billing_account_cost_summary.json',
    'docs/planning/v1.2/sprint_115_subscription_entitlement_model.json',
    'docs/planning/v1.2/sprint_116_paypal_billing_certification.json',
    'docs/planning/v1.2/sprint_115_invoices_receipts_billing_history.json',
  ];

  /// The distinct union of the committed billing witness vocabularies, in
  /// witness order.
  static List<String> stateVocabulary(List<List<String>> vocabularies) {
    final seen = <String>{};
    final result = <String>[];
    for (final vocabulary in vocabularies) {
      for (final state in vocabulary) {
        if (seen.add(state)) result.add(state);
      }
    }
    return result;
  }

  /// The evidence source registered for a canonical signal.
  static String sourceFor(String signal) {
    final index = billingSignals.indexOf(signal);
    if (index < 0) return '';
    return canonicalSources[index];
  }

  /// The canonical review, declared here as the single source of truth. The gate
  /// evaluates exactly this object, and the emitter writes exactly this object,
  /// so the record cannot be made to agree with itself. With the release
  /// delayed, every entry declares a reference and observes nothing.
  static const Sprint118BillingEntitlementHealthReview
  canonicalReview = Sprint118BillingEntitlementHealthReview(
    releaseState: delayedReleaseState,
    entries: <Sprint118BillingEntitlementHealthEntry>[
      Sprint118BillingEntitlementHealthEntry(
        signal: 'checkout',
        referenceState: 'payment_subscription_flow',
        source:
            'docs/planning/v1.2/sprint_116_paypal_billing_certification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118BillingEntitlementHealthEntry(
        signal: 'webhook',
        referenceState: 'webhooks',
        source:
            'docs/planning/v1.2/sprint_116_stripe_billing_certification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118BillingEntitlementHealthEntry(
        signal: 'idempotency',
        referenceState: 'idempotency',
        source:
            'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118BillingEntitlementHealthEntry(
        signal: 'invoice',
        referenceState: 'invoice_list',
        source:
            'docs/planning/v1.2/sprint_115_invoices_receipts_billing_history.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118BillingEntitlementHealthEntry(
        signal: 'entitlement',
        referenceState: 'entitlements',
        source:
            'docs/planning/v1.2/sprint_115_subscription_entitlement_model.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118BillingEntitlementHealthEntry(
        signal: 'renewal',
        referenceState: 'billing_cycle',
        source:
            'docs/planning/v1.2/sprint_115_billing_account_cost_summary.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118BillingEntitlementHealthEntry(
        signal: 'cancellation',
        referenceState: 'cancellation',
        source:
            'docs/planning/v1.2/sprint_115_subscription_entitlement_model.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118BillingEntitlementHealthEntry(
        signal: 'refund',
        referenceState: 'refunds',
        source:
            'docs/planning/v1.2/sprint_116_paypal_billing_certification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118BillingEntitlementHealthEntry(
        signal: 'dispute',
        referenceState: 'dispute_path',
        source:
            'docs/planning/v1.2/sprint_115_invoices_receipts_billing_history.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
    ],
  );
}

/// Reads the committed 118.4 baseline, 118.2 charter, and billing witnesses.
/// Never invents: an unreadable witness yields `null`, which the gate reports as
/// blocked rather than as a pass.
class Sprint118BillingEntitlementHealthLoader {
  const Sprint118BillingEntitlementHealthLoader();

  Sprint118BillingEntitlementHealthAnchor? loadAnchor() {
    final baseline = _readJsonObject(
      Sprint118BillingEntitlementHealthContract.baselineManifestPath,
    );
    if (baseline == null) return null;
    final charter = _readJsonObject(
      Sprint118BillingEntitlementHealthContract.charterManifestPath,
    );
    if (charter == null) return null;
    final subscriptionEntitlement = _readJsonObject(
      Sprint118BillingEntitlementHealthContract
          .subscriptionEntitlementManifestPath,
    );
    if (subscriptionEntitlement == null) return null;
    final billingAccount = _readJsonObject(
      Sprint118BillingEntitlementHealthContract.billingAccountManifestPath,
    );
    if (billingAccount == null) return null;
    final paymentMethod = _readJsonObject(
      Sprint118BillingEntitlementHealthContract.paymentMethodManifestPath,
    );
    if (paymentMethod == null) return null;
    final invoices = _readJsonObject(
      Sprint118BillingEntitlementHealthContract.invoicesManifestPath,
    );
    if (invoices == null) return null;
    final webhookReconciliation = _readJsonObject(
      Sprint118BillingEntitlementHealthContract
          .webhookReconciliationManifestPath,
    );
    if (webhookReconciliation == null) return null;
    final stripe = _readJsonObject(
      Sprint118BillingEntitlementHealthContract.stripeManifestPath,
    );
    if (stripe == null) return null;
    final paypal = _readJsonObject(
      Sprint118BillingEntitlementHealthContract.paypalManifestPath,
    );
    if (paypal == null) return null;
    final midtrans = _readJsonObject(
      Sprint118BillingEntitlementHealthContract.midtransManifestPath,
    );
    if (midtrans == null) return null;

    final window = charter['window'];
    final windowMap = window is Map<String, dynamic>
        ? window
        : const <String, dynamic>{};
    final durationDays = _int(windowMap['duration_days']);
    final charterWindowMinutes = durationDays > 0
        ? durationDays * 24 * 60
        : Sprint118BillingEntitlementHealthContract.charterWindowMinutes;

    final readable = <String>[
      for (final source
          in Sprint118BillingEntitlementHealthContract.canonicalSources)
        if (File(source).existsSync()) source,
    ];

    return Sprint118BillingEntitlementHealthAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterWindowMinutes: charterWindowMinutes,
      witnessSubscriptionEntitlementAcceptance: _stringList(
        subscriptionEntitlement['acceptance'],
      ),
      witnessBillingAccountAcceptance: _stringList(
        billingAccount['acceptance'],
      ),
      witnessPaymentMethodAcceptance: _stringList(paymentMethod['acceptance']),
      witnessInvoicesAcceptance: _stringList(invoices['acceptance']),
      witnessWebhookReconciliationAcceptance: _stringList(
        webhookReconciliation['required_acceptance'],
      ),
      witnessStripeFields: _stringList(stripe['required_fields']),
      witnessPaypalFields: _stringList(paypal['required_fields']),
      witnessMidtransFields: _stringList(midtrans['required_fields']),
      readableSources: readable,
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return <String>[
        for (final item in value)
          if (item is String) item,
      ];
    }
    return const <String>[];
  }

  static Map<String, dynamic>? _readJsonObject(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static String _text(Object? value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}

class Sprint118BillingEntitlementHealthGate {
  const Sprint118BillingEntitlementHealthGate();

  /// Evaluate the canonical review against committed evidence. This is the
  /// entry point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118BillingEntitlementHealthReport evaluate() => evaluateWith(
    const Sprint118BillingEntitlementHealthLoader().loadAnchor(),
    Sprint118BillingEntitlementHealthContract.canonicalReview,
  );

  Sprint118BillingEntitlementHealthReport evaluateWith(
    Sprint118BillingEntitlementHealthAnchor? anchor,
    Sprint118BillingEntitlementHealthReview review,
  ) {
    if (anchor == null) {
      return Sprint118BillingEntitlementHealthReport(
        state: Sprint118BillingEntitlementHealthState.blocked,
        verdict: 'SPRINT_118_BILLING_ENTITLEMENT_HEALTH_EVIDENCE_UNREADABLE',
        releaseState: review.releaseState,
        missingFields: List<String>.from(
          Sprint118BillingEntitlementHealthContract.requiredFields,
        ),
        blockers: const <String>[
          'committed_billing_entitlement_health_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_billing_entitlement_health_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    // (1) The 118.4 baseline anchor must be a genuine frozen pass. A review
    // written against an unfrozen baseline describes billing readings nobody
    // measured.
    if (anchor.baselineState !=
            Sprint118BillingEntitlementHealthContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118BillingEntitlementHealthContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be complete. A review bound to an
    // incomplete charter has no declared window to respect.
    if (anchor.charterState !=
            Sprint118BillingEntitlementHealthContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118BillingEntitlementHealthContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (3) The release state must agree with the baseline anchor.
    if (anchor.releaseState != review.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'review=${review.releaseState}',
      );
    }

    // (4) On the delayed path no signal may claim an observation: with no
    // release, an observation describes a billing reading never fetched.
    final delayed =
        review.releaseState ==
        Sprint118BillingEntitlementHealthContract.delayedReleaseState;
    if (delayed) {
      for (final entry in review.entries) {
        if (entry.observed) {
          violations.add(
            'billing_claims_observation_without_release:${entry.signal}',
          );
        }
      }
    }

    // (5) The committed witness vocabulary must be present, so the review has
    // something to draw its reference states from.
    final witnessIncomplete =
        anchor.witnessSubscriptionEntitlementAcceptance.isEmpty ||
        anchor.witnessBillingAccountAcceptance.isEmpty ||
        anchor.witnessPaymentMethodAcceptance.isEmpty ||
        anchor.witnessInvoicesAcceptance.isEmpty ||
        anchor.witnessWebhookReconciliationAcceptance.isEmpty ||
        anchor.witnessStripeFields.isEmpty ||
        anchor.witnessPaypalFields.isEmpty ||
        anchor.witnessMidtransFields.isEmpty;
    if (witnessIncomplete) {
      blockers.add('upstream_billing_vocabulary_missing');
    }
    final vocabulary =
        Sprint118BillingEntitlementHealthContract.stateVocabulary(
          <List<String>>[
            anchor.witnessSubscriptionEntitlementAcceptance,
            anchor.witnessBillingAccountAcceptance,
            anchor.witnessPaymentMethodAcceptance,
            anchor.witnessInvoicesAcceptance,
            anchor.witnessWebhookReconciliationAcceptance,
            anchor.witnessStripeFields,
            anchor.witnessPaypalFields,
            anchor.witnessMidtransFields,
          ],
        );

    // (6) Every canonical signal must be present exactly once, and each entry
    // must carry its declared fields.
    final declared = <String, int>{};
    for (final entry in review.entries) {
      declared[entry.signal] = (declared[entry.signal] ?? 0) + 1;
    }
    for (final entry in review.entries) {
      final signal = entry.signal;
      if (!Sprint118BillingEntitlementHealthContract.billingSignals.contains(
        signal,
      )) {
        violations.add('signal_unknown:$signal');
      }
      if (entry.referenceState.trim().isEmpty) {
        violations.add('entry_blank_reference_state:$signal');
      }
      if (entry.source.trim().isEmpty) {
        violations.add('entry_blank_source:$signal');
      }
      if (entry.limitations.isEmpty) {
        violations.add('entry_no_limitations:$signal');
      }
      if (entry.window <= 0) {
        violations.add('entry_nonpositive_window:$signal:${entry.window}');
      } else if (entry.window > anchor.charterWindowMinutes) {
        violations.add(
          'entry_window_exceeds_charter:$signal:${entry.window}:'
          '${anchor.charterWindowMinutes}',
        );
      }
      // A reference state is judged against the witness vocabulary. The witness
      // is required for the review to pass, so an unknown reference state is a
      // violation, not an open item.
      if (entry.referenceState.trim().isNotEmpty && !witnessIncomplete) {
        if (!vocabulary.contains(entry.referenceState)) {
          violations.add(
            'entry_unknown_reference_state:$signal:${entry.referenceState}',
          );
        }
      }
      if (entry.source.trim().isNotEmpty &&
          !anchor.readableSources.contains(entry.source)) {
        violations.add('entry_unreadable_source:$signal:${entry.source}');
      }
    }
    for (final signal in declared.keys) {
      if (declared[signal]! > 1) {
        violations.add('signal_duplicate:$signal');
      }
    }
    for (final signal
        in Sprint118BillingEntitlementHealthContract.billingSignals) {
      if (!declared.containsKey(signal)) {
        violations.add('signal_missing:$signal');
      }
    }

    // (7) Every committed review-evidence source must be readable.
    for (final source
        in Sprint118BillingEntitlementHealthContract.canonicalSources) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('unreadable_source:$source');
      }
    }

    final allOpen = <String>[...violations, ...blockers, ...openItems];
    final signals = review.signals;

    if (violations.isNotEmpty) {
      return Sprint118BillingEntitlementHealthReport(
        state: Sprint118BillingEntitlementHealthState.fail,
        verdict: 'SPRINT_118_BILLING_ENTITLEMENT_HEALTH_EVIDENCE_VIOLATION',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118BillingEntitlementHealthReport(
        state: Sprint118BillingEntitlementHealthState.blocked,
        verdict: 'SPRINT_118_BILLING_ENTITLEMENT_HEALTH_BLOCKED_UPSTREAM',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    return Sprint118BillingEntitlementHealthReport(
      state: Sprint118BillingEntitlementHealthState.pass,
      verdict: 'BILLING_ENTITLEMENT_HEALTH_VERIFIED_LOCAL',
      releaseState: review.releaseState,
      openItems: allOpen,
      declaredSignals: signals,
      observedCount: review.observedCount,
    );
  }
}
