/// Fail-closed payment connector expansion for roadmap step 118.38 -- Payment
/// Connector Expansion.
///
/// Objective (external canonical `sprint_118.json`): certify the next payment
/// connector one at a time with tokenization, webhooks, idempotency, refund,
/// tax, and region evidence. The canonical requirement set is exactly seven
/// items: `selected_provider`, `tokenization`, `webhooks`, `idempotency`,
/// `refund`, `tax`, and `regions`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered), the 118.2 charter froze an expansion budget of zero new
/// certified connectors out of 32 registered, the committed 117.45 approval gate
/// records `decision=delay`, `approval_state=PENDING_CHOIRUDIN`,
/// `execution_authorized=false`, and `release_blocked=true`, and the committed
/// 118.12 billing & entitlement health review records
/// `BILLING_ENTITLEMENT_HEALTH_VERIFIED_LOCAL` with `state=pass`. No payment
/// connector has been selected, no tokenization has been verified live, no
/// webhook has been delivered live, no idempotency guarantee has been verified
/// against a live provider, no refund has been executed, no tax figure has been
/// read from a live provider, and no region availability has been verified live.
/// A payment connector expansion review written against that state therefore has
/// exactly one honest shape: enumerate all 32 registered providers, anchor each
/// of the seven requirements to a committed witness vocabulary, and claim no
/// live certification.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.2 charter anchor must be a genuine complete charter and
///   its expansion budget must stay frozen (`max_new_certified_connectors` and
///   `currently_certified` both zero). A certification review anchored to an
///   unfrozen budget certifies a connector nobody authorized.
/// * The committed 118.3 certified connector snapshot must be a genuine frozen
///   pass (`CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL`). A certification review
///   anchored to an unfrozen snapshot rests on a release nobody recorded.
/// * The committed 117.45 approval gate must record the delay decision
///   (`decision == delay`), read with the owner's exact grammar, never
///   case-folded or trimmed into agreement. If it is not a delay, the anchor is
///   untrustworthy and the honest answer is `blocked`, not `fail`.
/// * The committed 118.12 billing & entitlement health review must be a genuine
///   pass (`BILLING_ENTITLEMENT_HEALTH_VERIFIED_LOCAL`). A certification review
///   anchored to an unhealthy billing surface certifies a connector whose
///   payment contract nobody proved.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, the frozen snapshot count, and the
///   charter count must agree. A certification review over a drifting registry
///   is not a certification review.
/// * Every registered provider must appear exactly once. A record that drops a
///   provider, invents `telepathy`, or duplicates `stripe` is not a
///   certification review.
/// * Every entry must carry all eight canonical fields non-blank, and each of
///   the seven requirements must be grounded by the committed witness vocabulary
///   for that requirement, so a certification value cannot be invented into the
///   list without a witness to ground it.
/// * On the delayed path a certified connector, a selected provider, a
///   live-verified tokenization, a live-verified webhook, a live-verified
///   idempotency guarantee, an executed refund, a live tax read, a live region
///   verification, or a released provider describe behavior that never ran.
///   This is refused by name, per entry.
///
/// **A provider is never recorded as a certified payment connector without live
/// provider verification and an authorized release.** When no payment connector
/// was selected and no release is authorized, the only honest certification
/// review records the committed payment-connector reference for each requirement
/// and claims nothing live; any certified, selected, tokenization-verified,
/// webhook-verified, idempotency-verified, refund-verified, tax-verified,
/// region-verified, or released claim is refused by name.
///
/// The output vocabulary is *derived from committed witnesses* (the 115.36
/// payment method abstraction acceptance set, the 115.12 secure token & secret
/// vault acceptance set, the 116.37 PayPal billing certification required-field
/// set, the 116.40 billing entitlement & webhook reconciliation required
/// acceptance set, the 115.37 invoices/receipts/billing history acceptance set,
/// the 115.35 billing account & cost summary acceptance set, and the 116.38
/// Midtrans billing certification required-field set), and the source for each
/// requirement is a committed manifest, not copied by hand, so the record and
/// its witnesses cannot drift apart silently.
///
/// Payment connector selection, live tokenization verification, live webhook
/// delivery, live idempotency verification, refund execution, live tax reads,
/// live region verification, credential access, connector certification,
/// provider exposure, and publication remain `DEFERRED-EXTERNAL`; this review
/// freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a payment connector expansion review can rest in.
/// `blocked` is the honest resting state for "this review cannot yet be
/// trusted", and it is distinct from `fail`, which means the record contradicts
/// its own evidence.
enum Sprint118PaymentConnectorState { pass, fail, blocked }

/// One frozen payment connector expansion entry: the declared reference for each
/// of the seven canonical requirements of a single registered provider.
///
/// `certified`, `selected`, `tokenizationVerified`, `webhooksVerified`,
/// `idempotencyVerified`, `refundVerified`, `taxVerified`, `regionsVerified`,
/// and `released` are deliberately *not* among the eight required fields; they
/// are the flags the gate refuses when set, so that a declared reference
/// certification can be recorded while never being read as a certified
/// connector, a selected provider, a live-verified tokenization, a
/// live-verified webhook, a live-verified idempotency guarantee, an executed
/// refund, a live tax read, a live region verification, or a released provider.
class Sprint118PaymentConnectorEntry {
  const Sprint118PaymentConnectorEntry({
    required this.providerId,
    required this.selectedProvider,
    required this.tokenization,
    required this.webhooks,
    required this.idempotency,
    required this.refund,
    required this.tax,
    required this.regions,
    this.certified = false,
    this.selected = false,
    this.tokenizationVerified = false,
    this.webhooksVerified = false,
    this.idempotencyVerified = false,
    this.refundVerified = false,
    this.taxVerified = false,
    this.regionsVerified = false,
    this.released = false,
  });

  /// The registered provider identifier, drawn from the committed icon registry.
  final String providerId;

  /// The selected-provider reference state, drawn from the committed 115.36
  /// payment method abstraction acceptance set.
  final String selectedProvider;

  /// The tokenization reference state, drawn from the committed 115.12 secure
  /// token & secret vault acceptance set.
  final String tokenization;

  /// The webhooks reference state, drawn from the committed 116.37 PayPal
  /// billing certification required-field set.
  final String webhooks;

  /// The idempotency reference state, drawn from the committed 116.40 billing
  /// entitlement & webhook reconciliation required acceptance set.
  final String idempotency;

  /// The refund reference state, drawn from the committed 115.37 invoices,
  /// receipts & billing history acceptance set.
  final String refund;

  /// The tax reference state, drawn from the committed 115.35 billing account &
  /// cost summary acceptance set.
  final String tax;

  /// The regions reference state, drawn from the committed 116.38 Midtrans
  /// billing certification required-field set.
  final String regions;

  /// Whether the entry claims the connector was certified. On the delayed path
  /// this must stay `false`.
  final bool certified;

  /// Whether the entry claims the provider was selected. On the delayed path
  /// this must stay `false`.
  final bool selected;

  /// Whether the entry claims tokenization was verified live. On the delayed
  /// path this must stay `false`.
  final bool tokenizationVerified;

  /// Whether the entry claims webhooks were verified live. On the delayed path
  /// this must stay `false`.
  final bool webhooksVerified;

  /// Whether the entry claims idempotency was verified live. On the delayed path
  /// this must stay `false`.
  final bool idempotencyVerified;

  /// Whether the entry claims a refund was executed. On the delayed path this
  /// must stay `false`.
  final bool refundVerified;

  /// Whether the entry claims a live tax read. On the delayed path this must
  /// stay `false`.
  final bool taxVerified;

  /// Whether the entry claims a live region verification. On the delayed path
  /// this must stay `false`.
  final bool regionsVerified;

  /// Whether the entry claims a released provider. On the delayed path this must
  /// stay `false`.
  final bool released;

  /// The eight canonical fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'provider_id': providerId,
    'selected_provider': selectedProvider,
    'tokenization': tokenization,
    'webhooks': webhooks,
    'idempotency': idempotency,
    'refund': refund,
    'tax': tax,
    'regions': regions,
  };

  /// The seven requirements as a requirement -> value map, so the gate can test
  /// grounding per requirement.
  Map<String, String> get outputFields => <String, String>{
    'selected_provider': selectedProvider,
    'tokenization': tokenization,
    'webhooks': webhooks,
    'idempotency': idempotency,
    'refund': refund,
    'tax': tax,
    'regions': regions,
  };
}

/// The frozen payment connector expansion review. `entries` is the declared
/// reference for each registered provider. On the delayed path no entry may
/// claim a live certification.
class Sprint118PaymentConnectorRecord {
  const Sprint118PaymentConnectorRecord({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118PaymentConnectorEntry> entries;

  List<String> get providerIds => <String>[
    for (final entry in entries) entry.providerId,
  ];

  /// The providers the record claims were certified. On the delayed path this
  /// must stay empty.
  List<String> get certifiedProviders => <String>[
    for (final entry in entries)
      if (entry.certified) entry.providerId,
  ];

  /// The providers the record claims were selected. On the delayed path this
  /// must stay empty.
  List<String> get selectedProviders => <String>[
    for (final entry in entries)
      if (entry.selected) entry.providerId,
  ];

  int get certifiedCount => entries.where((entry) => entry.certified).length;

  int get selectedCount => entries.where((entry) => entry.selected).length;
}

/// What the committed witnesses actually say. A gate is only as honest as the
/// witnesses it is anchored to.
class Sprint118PaymentConnectorAnchor {
  const Sprint118PaymentConnectorAnchor({
    required this.charterState,
    required this.charterVerdict,
    required this.charterMaxNewCertified,
    required this.charterCurrentlyCertified,
    required this.charterRegisteredProviders,
    required this.snapshotState,
    required this.snapshotVerdict,
    required this.snapshotCertified,
    required this.snapshotRegistered,
    required this.releaseState,
    required this.registryExpectedCount,
    required this.approvalDecision,
    required this.approvalState,
    required this.executionAuthorized,
    required this.releaseBlocked,
    required this.paymentWorkflowStatus,
    required this.paymentWorkflowVerdict,
    required this.registeredProviders,
    required this.selectedProviderVocabulary,
    required this.tokenizationVocabulary,
    required this.webhooksVocabulary,
    required this.idempotencyVocabulary,
    required this.refundVocabulary,
    required this.taxVocabulary,
    required this.regionsVocabulary,
    required this.readableSources,
  });

  final String charterState;
  final String charterVerdict;

  /// The maximum number of new certified connectors the committed 118.2 charter
  /// allows. A frozen budget is zero.
  final int charterMaxNewCertified;

  /// The number of connectors already certified in the committed 118.2 charter.
  final int charterCurrentlyCertified;

  /// The registered provider count the committed 118.2 charter declares.
  final int charterRegisteredProviders;

  final String snapshotState;
  final String snapshotVerdict;

  /// The certified connector count the committed 118.3 snapshot declares.
  final int snapshotCertified;

  /// The registered provider count the committed 118.3 snapshot declares.
  final int snapshotRegistered;

  /// The release state the committed 118.3 snapshot declares.
  final String releaseState;

  /// The expected provider count the committed 116.3 reconciliation declares.
  final int registryExpectedCount;

  /// The decision the committed 117.45 approval gate records, read with the
  /// owner's exact grammar (never case-folded or trimmed).
  final String approvalDecision;

  /// The approval state the committed 117.45 approval gate records.
  final String approvalState;

  /// Whether the committed 117.45 approval gate authorizes execution. On the
  /// delayed path this must stay `false`.
  final bool executionAuthorized;

  /// Whether the committed 117.45 approval gate records the release as blocked.
  final bool releaseBlocked;

  /// The status the committed 118.12 billing & entitlement health review
  /// declares.
  final String paymentWorkflowStatus;

  /// The verdict the committed 118.12 billing & entitlement health review
  /// declares.
  final String paymentWorkflowVerdict;

  /// The registered provider ids, unioned from the committed 115.8 icon registry.
  final List<String> registeredProviders;

  /// The selected-provider vocabulary the committed 115.36 payment method
  /// abstraction declares. It grounds the selected-provider requirement.
  final List<String> selectedProviderVocabulary;

  /// The tokenization vocabulary the committed 115.12 secure token & secret
  /// vault declares. It grounds the tokenization requirement.
  final List<String> tokenizationVocabulary;

  /// The webhooks vocabulary the committed 116.37 PayPal billing certification
  /// declares. It grounds the webhooks requirement.
  final List<String> webhooksVocabulary;

  /// The idempotency vocabulary the committed 116.40 billing entitlement &
  /// webhook reconciliation declares. It grounds the idempotency requirement.
  final List<String> idempotencyVocabulary;

  /// The refund vocabulary the committed 115.37 invoices, receipts & billing
  /// history declares. It grounds the refund requirement.
  final List<String> refundVocabulary;

  /// The tax vocabulary the committed 115.35 billing account & cost summary
  /// declares. It grounds the tax requirement.
  final List<String> taxVocabulary;

  /// The regions vocabulary the committed 116.38 Midtrans billing certification
  /// declares. It grounds the regions requirement.
  final List<String> regionsVocabulary;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is a faithful freeze; `blocked`
/// means it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118PaymentConnectorReport {
  const Sprint118PaymentConnectorReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredProviders = const <String>[],
    this.certifiedProviders = const <String>[],
    this.selectedProviders = const <String>[],
    this.certifiedCount = 0,
    this.selectedCount = 0,
    this.expansionBudgetFrozen = false,
  });

  final Sprint118PaymentConnectorState state;
  final String verdict;
  final String releaseState;

  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredProviders;
  final List<String> certifiedProviders;
  final List<String> selectedProviders;
  final int certifiedCount;
  final int selectedCount;
  final bool expansionBudgetFrozen;

  /// Whether the review may be treated as a frozen certification record. Only a
  /// genuine `pass` allows it.
  bool get certificationVerified =>
      state == Sprint118PaymentConnectorState.pass;

  String get externalGates => Sprint118PaymentConnectorContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.38.
abstract final class Sprint118PaymentConnectorContract {
  const Sprint118PaymentConnectorContract._();

  static const String canonicalStep = '118.38';
  static const String title = 'Payment Connector Expansion';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_payment_connector_expansion.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.2 charter that declares the frozen expansion budget.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 118.3 certified connector snapshot this review rests on.
  static const String snapshotManifestPath =
      'docs/planning/v1.3/sprint_118_certified_connector_snapshot.json';

  /// The committed 117.45 approval gate that records the delay decision.
  static const String approvalGateManifestPath =
      'docs/planning/v1.3/sprint_117_ga_approval_gate.json';

  /// The committed 115.8 provider icon registry that is the single provider-id
  /// seam and the registered-provider source.
  static const String iconRegistryManifestPath =
      'docs/planning/v1.2/sprint_115_provider_icon_registry.json';

  /// The committed 116.3 provider registry reconciliation that declares the
  /// expected provider count.
  static const String registryReconciliationManifestPath =
      'docs/planning/v1.2/sprint_116_provider_registry_reconciliation.json';

  /// The committed 118.12 billing & entitlement health review that records the
  /// payment-domain pass this review rests on.
  static const String billingEntitlementHealthManifestPath =
      'docs/planning/v1.3/sprint_118_billing_entitlement_health.json';

  /// The committed 115.36 payment method abstraction that grounds the
  /// selected-provider requirement.
  static const String paymentMethodAbstractionManifestPath =
      'docs/planning/v1.2/sprint_115_payment_method_abstraction.json';

  /// The committed 115.12 secure token & secret vault that grounds the
  /// tokenization requirement.
  static const String secureTokenSecretVaultManifestPath =
      'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json';

  /// The committed 116.37 PayPal billing certification that grounds the webhooks
  /// requirement.
  static const String paypalBillingCertificationManifestPath =
      'docs/planning/v1.2/sprint_116_paypal_billing_certification.json';

  /// The committed 116.40 billing entitlement & webhook reconciliation that
  /// grounds the idempotency requirement.
  static const String billingEntitlementWebhookReconciliationManifestPath =
      'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json';

  /// The committed 115.37 invoices, receipts & billing history that grounds the
  /// refund requirement.
  static const String invoicesReceiptsBillingHistoryManifestPath =
      'docs/planning/v1.2/sprint_115_invoices_receipts_billing_history.json';

  /// The committed 115.35 billing account & cost summary that grounds the tax
  /// requirement.
  static const String billingAccountCostSummaryManifestPath =
      'docs/planning/v1.2/sprint_115_billing_account_cost_summary.json';

  /// The committed 116.38 Midtrans billing certification that grounds the
  /// regions requirement.
  static const String midtransBillingCertificationManifestPath =
      'docs/planning/v1.2/sprint_116_midtrans_billing_certification.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  /// The verdict and state the 118.3 snapshot anchor must carry.
  static const String requiredSnapshotVerdict =
      'CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL';
  static const String requiredSnapshotState = 'pass';

  /// The decision the committed 117.45 approval gate must record. Read with the
  /// owner's exact grammar, never case-folded.
  static const String requiredApprovalDecision = 'delay';

  /// The status and verdict the committed 118.12 billing & entitlement health
  /// review must carry to be a genuine pass.
  static const String requiredPaymentWorkflowStatus = 'pass';
  static const String requiredPaymentWorkflowVerdict =
      'BILLING_ENTITLEMENT_HEALTH_VERIFIED_LOCAL';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The number of registered providers the committed witnesses reconcile to.
  static const int expectedProviderCount = 32;

  /// The marker an entry declares when no committed witness names a reference
  /// state for a requirement. A record that uses it records an honest upstream
  /// gap rather than inventing a state.
  static const String noReferenceState = 'no_reference_state';

  /// The canonical field set each entry must carry, so a record cannot drop a
  /// field and still read as complete.
  static const List<String> requiredFields = <String>[
    'provider_id',
    'selected_provider',
    'tokenization',
    'webhooks',
    'idempotency',
    'refund',
    'tax',
    'regions',
  ];

  /// The seven canonical requirements named by the objective, in canonical
  /// order. `provider_id` is the key, not a requirement.
  static const List<String> requiredOutputs = <String>[
    'selected_provider',
    'tokenization',
    'webhooks',
    'idempotency',
    'refund',
    'tax',
    'regions',
  ];

  /// The committed evidence file each canonical requirement is anchored to, in
  /// canonical order.
  static const List<String> canonicalSources = <String>[
    paymentMethodAbstractionManifestPath,
    secureTokenSecretVaultManifestPath,
    paypalBillingCertificationManifestPath,
    billingEntitlementWebhookReconciliationManifestPath,
    invoicesReceiptsBillingHistoryManifestPath,
    billingAccountCostSummaryManifestPath,
    midtransBillingCertificationManifestPath,
  ];

  /// The committed evidence files every review is anchored to. All must be
  /// readable.
  static const List<String> witnessSources = <String>[
    charterManifestPath,
    snapshotManifestPath,
    approvalGateManifestPath,
    iconRegistryManifestPath,
    registryReconciliationManifestPath,
    billingEntitlementHealthManifestPath,
    paymentMethodAbstractionManifestPath,
    secureTokenSecretVaultManifestPath,
    paypalBillingCertificationManifestPath,
    billingEntitlementWebhookReconciliationManifestPath,
    invoicesReceiptsBillingHistoryManifestPath,
    billingAccountCostSummaryManifestPath,
    midtransBillingCertificationManifestPath,
  ];

  /// The registered provider ids, in first-seen icon-registry order. This is the
  /// canonical review key set: every id appears exactly once and no id is
  /// invented.
  static const List<String> canonicalProviders = <String>[
    'email',
    'google',
    'microsoft',
    'apple',
    'github',
    'discord',
    'x',
    'facebook',
    'google_drive',
    'onedrive',
    'dropbox',
    'mega',
    'local_storage',
    'openai',
    'gemini',
    'anthropic',
    'flux',
    'openrouter',
    'local_ai',
    'gitlab',
    'bitbucket',
    'azure_devops',
    'figma',
    'adobe',
    'canva',
    'blender_cloud',
    'sketchfab',
    'paypal',
    'stripe',
    'midtrans',
    'saweria',
    'kofi',
  ];

  /// The declared reference state for the selected-provider requirement. No
  /// shipped payment connector reads a live provider on the delayed path, so the
  /// honest reference is the committed 115.36 payment method abstraction
  /// acceptance (`provider_token_only`).
  static const String selectedProviderToken = 'provider_token_only';

  /// The declared reference state for the tokenization requirement. Tokenization
  /// is declared and unverified live, so the honest reference is the committed
  /// 115.12 secure token & secret vault acceptance (`os_secure_store`).
  static const String tokenizationToken = 'os_secure_store';

  /// The declared reference state for the webhooks requirement. No webhook is
  /// delivered live on the delayed path, so the honest reference is the
  /// committed 116.37 PayPal billing certification required field (`webhooks`).
  static const String webhooksToken = 'webhooks';

  /// The declared reference state for the idempotency requirement. No idempotency
  /// guarantee is verified against a live provider on the delayed path, so the
  /// honest reference is the committed 116.40 webhook reconciliation required
  /// acceptance (`idempotency`).
  static const String idempotencyToken = 'idempotency';

  /// The declared reference state for the refund requirement. No refund is
  /// executed on the delayed path, so the honest reference is the committed
  /// 115.37 invoices/receipts/billing history acceptance (`refund_path`).
  static const String refundToken = 'refund_path';

  /// The declared reference state for the tax requirement. No tax figure is read
  /// from a live provider on the delayed path, so the honest reference is the
  /// committed 115.35 billing account & cost summary acceptance (`tax`).
  static const String taxToken = 'tax';

  /// The declared reference state for the regions requirement. No region
  /// availability is verified live on the delayed path, so the honest reference
  /// is the committed 116.38 Midtrans billing certification required field
  /// (`region`).
  static const String regionsToken = 'region';

  /// The committed witness vocabulary that grounds each canonical requirement,
  /// in canonical order.
  static List<List<String>> outputVocabularies(
    Sprint118PaymentConnectorAnchor anchor,
  ) => <List<String>>[
    anchor.selectedProviderVocabulary,
    anchor.tokenizationVocabulary,
    anchor.webhooksVocabulary,
    anchor.idempotencyVocabulary,
    anchor.refundVocabulary,
    anchor.taxVocabulary,
    anchor.regionsVocabulary,
  ];

  /// Union of the committed witness vocabularies, de-duplicated in first-seen
  /// order, plus the honest no-reference marker.
  static List<String> stateVocabulary(List<List<String>> vocabularies) {
    final seen = <String>{};
    final result = <String>[];
    for (final vocabulary in vocabularies) {
      for (final value in vocabulary) {
        if (seen.add(value)) result.add(value);
      }
    }
    if (seen.add(noReferenceState)) result.add(noReferenceState);
    return result;
  }

  /// Whether a committed witness vocabulary grounds a reference-state token.
  ///
  /// A witness grounds a token when it names the token exactly
  /// (`provider_token_only`, `os_secure_store`, `refund_path`), or when every
  /// underscore-separated part of a compound token is itself a witness-declared
  /// value. The vocabulary is measured from the committed witnesses, so a
  /// reference state cannot be invented into the list without a witness to
  /// ground it.
  static bool grounds(List<String> vocabulary, String token) {
    if (vocabulary.contains(token)) return true;
    final parts = token.split('_');
    if (parts.length < 2) return false;
    return parts.every(vocabulary.contains);
  }

  /// The committed witness vocabulary for a canonical requirement, or the empty
  /// list when the requirement is unknown.
  static List<String> vocabularyFor(
    Sprint118PaymentConnectorAnchor anchor,
    String output,
  ) {
    final index = requiredOutputs.indexOf(output);
    if (index < 0) return const <String>[];
    return outputVocabularies(anchor)[index];
  }

  /// The committed source for a canonical requirement, or `''` if unknown.
  static String sourceFor(String output) {
    final index = requiredOutputs.indexOf(output);
    return index < 0 ? '' : canonicalSources[index];
  }

  /// The canonical frozen review: every registered provider, each anchored to the
  /// committed witness vocabularies, claiming nothing live.
  static Sprint118PaymentConnectorRecord get canonicalRecord =>
      Sprint118PaymentConnectorRecord(
        releaseState: delayedReleaseState,
        entries: <Sprint118PaymentConnectorEntry>[
          for (final id in canonicalProviders)
            Sprint118PaymentConnectorEntry(
              providerId: id,
              selectedProvider: selectedProviderToken,
              tokenization: tokenizationToken,
              webhooks: webhooksToken,
              idempotency: idempotencyToken,
              refund: refundToken,
              tax: taxToken,
              regions: regionsToken,
            ),
        ],
      );
}

/// Reads the committed witnesses for step 118.38. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118PaymentConnectorLoader {
  const Sprint118PaymentConnectorLoader();

  Sprint118PaymentConnectorAnchor? loadAnchor() {
    final charter = _read(
      Sprint118PaymentConnectorContract.charterManifestPath,
    );
    final snapshot = _read(
      Sprint118PaymentConnectorContract.snapshotManifestPath,
    );
    final approval = _read(
      Sprint118PaymentConnectorContract.approvalGateManifestPath,
    );
    final icon = _read(
      Sprint118PaymentConnectorContract.iconRegistryManifestPath,
    );
    final reconciliation = _read(
      Sprint118PaymentConnectorContract.registryReconciliationManifestPath,
    );
    final billingHealth = _read(
      Sprint118PaymentConnectorContract.billingEntitlementHealthManifestPath,
    );
    final paymentMethod = _read(
      Sprint118PaymentConnectorContract.paymentMethodAbstractionManifestPath,
    );
    final tokenVault = _read(
      Sprint118PaymentConnectorContract.secureTokenSecretVaultManifestPath,
    );
    final paypal = _read(
      Sprint118PaymentConnectorContract.paypalBillingCertificationManifestPath,
    );
    final webhookReconciliation = _read(
      Sprint118PaymentConnectorContract
          .billingEntitlementWebhookReconciliationManifestPath,
    );
    final invoices = _read(
      Sprint118PaymentConnectorContract
          .invoicesReceiptsBillingHistoryManifestPath,
    );
    final billingAccount = _read(
      Sprint118PaymentConnectorContract.billingAccountCostSummaryManifestPath,
    );
    final midtrans = _read(
      Sprint118PaymentConnectorContract
          .midtransBillingCertificationManifestPath,
    );
    if (charter == null ||
        snapshot == null ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        billingHealth == null ||
        paymentMethod == null ||
        tokenVault == null ||
        paypal == null ||
        webhookReconciliation == null ||
        invoices == null ||
        billingAccount == null ||
        midtrans == null) {
      return null;
    }

    final budget = charter['expansion_budget'];
    final budgetMap = budget is Map<String, dynamic>
        ? budget
        : const <String, dynamic>{};

    final approvalMap = approval['approval'];
    final approvalInner = approvalMap is Map<String, dynamic>
        ? approvalMap
        : const <String, dynamic>{};
    final blockerMap = approval['blocker_status'];
    final blockerInner = blockerMap is Map<String, dynamic>
        ? blockerMap
        : const <String, dynamic>{};

    final categories = icon['categories'];
    final categoryMap = categories is Map<String, dynamic>
        ? categories
        : const <String, dynamic>{};
    final registered = <String>[];
    for (final value in categoryMap.values) {
      if (value is List) {
        for (final item in value) {
          if (item is String && !registered.contains(item)) {
            registered.add(item);
          }
        }
      }
    }

    final sources = Sprint118PaymentConnectorContract.witnessSources.toSet();

    return Sprint118PaymentConnectorAnchor(
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterMaxNewCertified: _int(budgetMap['max_new_certified_connectors']),
      charterCurrentlyCertified: _int(budgetMap['currently_certified']),
      charterRegisteredProviders: _int(budgetMap['registered_providers']),
      snapshotState: _text(snapshot['state']),
      snapshotVerdict: _text(snapshot['verdict']),
      snapshotCertified: _int(snapshot['charter_certified']),
      snapshotRegistered: _int(snapshot['registered_provider_count']),
      releaseState: _text(snapshot['release_state']),
      registryExpectedCount: _int(reconciliation['expected_provider_count']),
      approvalDecision: _text(approvalInner['decision']),
      approvalState: _text(approvalInner['approval_state']),
      executionAuthorized: approvalInner['execution_authorized'] == true,
      releaseBlocked: blockerInner['release_blocked'] == true,
      paymentWorkflowStatus: _text(billingHealth['state']),
      paymentWorkflowVerdict: _text(billingHealth['verdict']),
      registeredProviders: registered,
      selectedProviderVocabulary: _strings(paymentMethod['acceptance']),
      tokenizationVocabulary: _strings(tokenVault['acceptance']),
      webhooksVocabulary: _strings(paypal['required_fields']),
      idempotencyVocabulary: _strings(
        webhookReconciliation['required_acceptance'],
      ),
      refundVocabulary: _strings(invoices['acceptance']),
      taxVocabulary: _strings(billingAccount['acceptance']),
      regionsVocabulary: _strings(midtrans['required_fields']),
      readableSources: <String>[
        for (final path in sources)
          if (File(path).existsSync()) path,
      ],
    );
  }

  static Map<String, dynamic>? _read(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final value = jsonDecode(file.readAsStringSync());
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }

  static String _text(Object? value) => value is String ? value.trim() : '';

  static List<String> _strings(Object? value) => value is List
      ? <String>[
          for (final item in value)
            if (item is String) item,
        ]
      : const <String>[];

  static int _int(Object? value) => value is int ? value : 0;
}

/// The fail-closed payment connector expansion gate for step 118.38.
class Sprint118PaymentConnectorGate {
  const Sprint118PaymentConnectorGate();

  Sprint118PaymentConnectorReport evaluate() => evaluateWith(
    const Sprint118PaymentConnectorLoader().loadAnchor(),
    Sprint118PaymentConnectorContract.canonicalRecord,
  );

  Sprint118PaymentConnectorReport evaluateWith(
    Sprint118PaymentConnectorAnchor? anchor,
    Sprint118PaymentConnectorRecord record,
  ) {
    if (anchor == null) {
      return Sprint118PaymentConnectorReport(
        state: Sprint118PaymentConnectorState.blocked,
        verdict: 'SPRINT_118_PAYMENT_CONNECTOR_EXPANSION_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>[
          'committed_payment_connector_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_payment_connector_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    final frozen =
        anchor.charterMaxNewCertified == 0 &&
        anchor.charterCurrentlyCertified == 0;

    // (1) The 118.2 charter anchor must be a genuine complete charter.
    if (anchor.charterState !=
            Sprint118PaymentConnectorContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118PaymentConnectorContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint118PaymentConnectorContract.requiredSnapshotState ||
        anchor.snapshotVerdict !=
            Sprint118PaymentConnectorContract.requiredSnapshotVerdict) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (anchor.approvalDecision !=
        Sprint118PaymentConnectorContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The 118.12 billing & entitlement health review must be a genuine pass,
    // or the payment anchor is untrustworthy.
    if (anchor.paymentWorkflowStatus !=
            Sprint118PaymentConnectorContract.requiredPaymentWorkflowStatus ||
        anchor.paymentWorkflowVerdict !=
            Sprint118PaymentConnectorContract.requiredPaymentWorkflowVerdict) {
      blockers.add(
        'payment_workflow_not_validated:${anchor.paymentWorkflowStatus}:'
        '${anchor.paymentWorkflowVerdict}',
      );
    }

    // (5) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, and the charter.
    if (anchor.registeredProviders.length !=
            Sprint118PaymentConnectorContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint118PaymentConnectorContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint118PaymentConnectorContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint118PaymentConnectorContract.expectedProviderCount) {
      blockers.add(
        'registry_not_reconciled:icon=${anchor.registeredProviders.length}:'
        'reconciliation=${anchor.registryExpectedCount}:'
        'snapshot=${anchor.snapshotRegistered}:'
        'charter=${anchor.charterRegisteredProviders}',
      );
    }

    // (6) The release state must agree with the anchor.
    if (record.releaseState != anchor.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'record=${record.releaseState}',
      );
    }
    if (record.releaseState !=
        Sprint118PaymentConnectorContract.delayedReleaseState) {
      violations.add(
        'payment_connector_not_on_delayed_path:${record.releaseState}',
      );
    }

    final delayed =
        record.releaseState ==
        Sprint118PaymentConnectorContract.delayedReleaseState;

    // (7) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add('payment_connector_execution_authorized_on_delayed_path');
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add('payment_connector_release_not_blocked_on_delayed_path');
    }

    // (8) The expansion budget must stay frozen: no new certified connector and
    // no already-certified connector while the release is delayed.
    if (!frozen) {
      violations.add(
        'payment_connector_expansion_budget_not_frozen:max_new='
        '${anchor.charterMaxNewCertified}:'
        'currently=${anchor.charterCurrentlyCertified}',
      );
    }

    // (9) Every registered provider must appear exactly once, and each entry must
    // carry all eight canonical fields non-blank with every requirement grounded
    // by its committed witness vocabulary.
    final declared = <String, int>{};
    for (final entry in record.entries) {
      declared[entry.providerId] = (declared[entry.providerId] ?? 0) + 1;
    }
    for (final entry in record.entries) {
      final id = entry.providerId;
      if (!anchor.registeredProviders.contains(id)) {
        violations.add('payment_connector_provider_unknown:$id');
      }
      for (final field in Sprint118PaymentConnectorContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$id');
        }
      }
      for (final output in Sprint118PaymentConnectorContract.requiredOutputs) {
        final token = entry.outputFields[output] ?? '';
        final vocabulary = Sprint118PaymentConnectorContract.vocabularyFor(
          anchor,
          output,
        );
        final grounded =
            token == Sprint118PaymentConnectorContract.noReferenceState ||
            Sprint118PaymentConnectorContract.grounds(vocabulary, token);
        if (token.trim().isEmpty || !grounded) {
          violations.add('reference_state_invalid:$output:$id');
        }
        if (token == Sprint118PaymentConnectorContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$output:$id');
        }
      }
      // A connector is never certified without live provider verification.
      if (entry.certified) {
        violations.add(
          'payment_connector_certified_claimed_on_delayed_path:$id',
        );
      }
      // A provider is never selected without a certified connector.
      if (entry.selected) {
        violations.add(
          'payment_connector_selected_claimed_on_delayed_path:$id',
        );
      }
      // Tokenization is never verified without a live provider.
      if (entry.tokenizationVerified) {
        violations.add(
          'payment_connector_tokenization_verified_on_delayed_path:$id',
        );
      }
      // Webhooks are never verified without a live provider.
      if (entry.webhooksVerified) {
        violations.add(
          'payment_connector_webhooks_verified_on_delayed_path:$id',
        );
      }
      // Idempotency is never verified without a live provider.
      if (entry.idempotencyVerified) {
        violations.add(
          'payment_connector_idempotency_verified_on_delayed_path:$id',
        );
      }
      // A refund is never executed on the delayed path.
      if (entry.refundVerified) {
        violations.add('payment_connector_refund_verified_on_delayed_path:$id');
      }
      // A tax figure is never read live on the delayed path.
      if (entry.taxVerified) {
        violations.add('payment_connector_tax_verified_on_delayed_path:$id');
      }
      // Region availability is never verified live on the delayed path.
      if (entry.regionsVerified) {
        violations.add(
          'payment_connector_regions_verified_on_delayed_path:$id',
        );
      }
      // A provider is never released without an authorized release.
      if (entry.released) {
        violations.add('payment_connector_provider_released_claimed:$id');
      }
    }
    for (final id in declared.keys) {
      if (declared[id]! > 1) {
        violations.add('payment_connector_provider_duplicate:$id');
      }
    }
    for (final id in anchor.registeredProviders) {
      if (!declared.containsKey(id)) {
        violations.add('payment_connector_provider_missing:$id');
      }
    }

    // (10) Every committed evidence source must be readable.
    for (final source
        in Sprint118PaymentConnectorContract.witnessSources.toSet()) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('required_source_unreadable:$source');
      }
    }

    final allItems = <String>[...violations, ...blockers, ...openItems];
    final providers = record.providerIds;

    // An untrustworthy anchor short-circuits: if a committed witness is not a
    // genuine pass, the entry-level findings cannot be trusted either, so the
    // honest answer is `blocked`, not `fail`.
    if (blockers.isNotEmpty) {
      return Sprint118PaymentConnectorReport(
        state: Sprint118PaymentConnectorState.blocked,
        verdict: 'SPRINT_118_PAYMENT_CONNECTOR_EXPANSION_BLOCKED_UPSTREAM',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        certifiedProviders: record.certifiedProviders,
        selectedProviders: record.selectedProviders,
        certifiedCount: record.certifiedCount,
        selectedCount: record.selectedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint118PaymentConnectorReport(
        state: Sprint118PaymentConnectorState.fail,
        verdict: 'SPRINT_118_PAYMENT_CONNECTOR_EXPANSION_EVIDENCE_VIOLATION',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        certifiedProviders: record.certifiedProviders,
        selectedProviders: record.selectedProviders,
        certifiedCount: record.certifiedCount,
        selectedCount: record.selectedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    return Sprint118PaymentConnectorReport(
      state: Sprint118PaymentConnectorState.pass,
      verdict: 'PAYMENT_CONNECTOR_EXPANSION_VERIFIED_LOCAL',
      releaseState: record.releaseState,
      openItems: allItems,
      declaredProviders: providers,
      certifiedProviders: record.certifiedProviders,
      selectedProviders: record.selectedProviders,
      certifiedCount: record.certifiedCount,
      selectedCount: record.selectedCount,
      expansionBudgetFrozen: frozen,
    );
  }
}
