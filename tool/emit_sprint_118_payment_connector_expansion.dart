// Emit the 118.38 Payment Connector Expansion record from the gate's own report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_payment_connector_expansion.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_payment_connector_expansion.dart';

Map<String, Object?> _entry(Sprint118PaymentConnectorEntry entry) =>
    <String, Object?>{
      'provider_id': entry.providerId,
      'selected_provider': entry.selectedProvider,
      'tokenization': entry.tokenization,
      'webhooks': entry.webhooks,
      'idempotency': entry.idempotency,
      'refund': entry.refund,
      'tax': entry.tax,
      'regions': entry.regions,
      'certified': entry.certified,
      'selected': entry.selected,
      'tokenization_verified': entry.tokenizationVerified,
      'webhooks_verified': entry.webhooksVerified,
      'idempotency_verified': entry.idempotencyVerified,
      'refund_verified': entry.refundVerified,
      'tax_verified': entry.taxVerified,
      'regions_verified': entry.regionsVerified,
      'released': entry.released,
    };

void main() {
  const gate = Sprint118PaymentConnectorGate();
  final report = gate.evaluate();
  final anchor = const Sprint118PaymentConnectorLoader().loadAnchor();
  final record = Sprint118PaymentConnectorContract.canonicalRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118PaymentConnectorContract.canonicalStep,
    'title': Sprint118PaymentConnectorContract.title,
    'document_role': 'payment-connector-expansion-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'certification_verified': report.certificationVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_fields': Sprint118PaymentConnectorContract.requiredFields,
    'required_outputs': Sprint118PaymentConnectorContract.requiredOutputs,
    'expected_provider_count':
        Sprint118PaymentConnectorContract.expectedProviderCount,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint118PaymentConnectorContract.charterManifestPath,
      'snapshot': Sprint118PaymentConnectorContract.snapshotManifestPath,
      'approval_gate':
          Sprint118PaymentConnectorContract.approvalGateManifestPath,
      'icon_registry':
          Sprint118PaymentConnectorContract.iconRegistryManifestPath,
      'registry_reconciliation':
          Sprint118PaymentConnectorContract.registryReconciliationManifestPath,
      'billing_entitlement_health': Sprint118PaymentConnectorContract
          .billingEntitlementHealthManifestPath,
      'payment_method_abstraction': Sprint118PaymentConnectorContract
          .paymentMethodAbstractionManifestPath,
      'secure_token_secret_vault':
          Sprint118PaymentConnectorContract.secureTokenSecretVaultManifestPath,
      'paypal_billing_certification': Sprint118PaymentConnectorContract
          .paypalBillingCertificationManifestPath,
      'billing_entitlement_webhook_reconciliation':
          Sprint118PaymentConnectorContract
              .billingEntitlementWebhookReconciliationManifestPath,
      'invoices_receipts_billing_history': Sprint118PaymentConnectorContract
          .invoicesReceiptsBillingHistoryManifestPath,
      'billing_account_cost_summary': Sprint118PaymentConnectorContract
          .billingAccountCostSummaryManifestPath,
      'midtrans_billing_certification': Sprint118PaymentConnectorContract
          .midtransBillingCertificationManifestPath,
    },
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_max_new_certified': anchor?.charterMaxNewCertified,
    'charter_currently_certified': anchor?.charterCurrentlyCertified,
    'charter_registered_providers': anchor?.charterRegisteredProviders,
    'snapshot_state': anchor?.snapshotState,
    'snapshot_verdict': anchor?.snapshotVerdict,
    'snapshot_certified': anchor?.snapshotCertified,
    'snapshot_registered': anchor?.snapshotRegistered,
    'registry_expected_count': anchor?.registryExpectedCount,
    'approval_decision': anchor?.approvalDecision,
    'approval_state': anchor?.approvalState,
    'execution_authorized': anchor?.executionAuthorized,
    'release_blocked': anchor?.releaseBlocked,
    'payment_workflow_status': anchor?.paymentWorkflowStatus,
    'payment_workflow_verdict': anchor?.paymentWorkflowVerdict,
    'registered_provider_count': anchor?.registeredProviders.length,
    'readable_source_count': anchor?.readableSources.length,
    'selected_provider_vocabulary': anchor?.selectedProviderVocabulary,
    'tokenization_vocabulary': anchor?.tokenizationVocabulary,
    'webhooks_vocabulary': anchor?.webhooksVocabulary,
    'idempotency_vocabulary': anchor?.idempotencyVocabulary,
    'refund_vocabulary': anchor?.refundVocabulary,
    'tax_vocabulary': anchor?.taxVocabulary,
    'regions_vocabulary': anchor?.regionsVocabulary,
    'reference_state_vocabulary':
        Sprint118PaymentConnectorContract.stateVocabulary(<List<String>>[
          anchor?.selectedProviderVocabulary ?? const <String>[],
          anchor?.tokenizationVocabulary ?? const <String>[],
          anchor?.webhooksVocabulary ?? const <String>[],
          anchor?.idempotencyVocabulary ?? const <String>[],
          anchor?.refundVocabulary ?? const <String>[],
          anchor?.taxVocabulary ?? const <String>[],
          anchor?.regionsVocabulary ?? const <String>[],
        ]),
    'canonical_sources': Sprint118PaymentConnectorContract.canonicalSources,
    'declared_providers': report.declaredProviders,
    'declared_provider_count': report.declaredProviders.length,
    'certified_providers': report.certifiedProviders,
    'selected_providers': report.selectedProviders,
    'certified_count': report.certifiedCount,
    'selected_count': report.selectedCount,
    'entries': record.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Payment Connector Expansion over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 118.12 billing & entitlement health review, the committed 115.36 payment method abstraction, the committed 115.12 secure token & secret vault, the committed 116.37 PayPal billing certification, the committed 116.40 billing entitlement & webhook reconciliation, the committed 115.37 invoices/receipts/billing history, the committed 115.35 billing account & cost summary, and the committed 116.38 Midtrans billing certification. A pass does not select a payment connector, verify a live tokenization, deliver a live webhook, verify a live idempotency guarantee, execute a refund, read a live tax figure, verify a live region, access a credential, certify a connector, expose a provider, authorize a release, or publish.',
      'The certification review is written against GA_DELAYED. It enumerates all 32 registered providers exactly once, anchors each of the seven canonical outputs (selected_provider, tokenization, webhooks, idempotency, refund, tax, regions) to a committed witness vocabulary, claims no live certification, and keeps the expansion budget frozen at zero new certified connectors.',
      'A provider is never recorded as a certified payment connector without live provider verification and an authorized release: the gate refuses any entry that claims a certified connector, a selected provider, a live-verified tokenization, a live-verified webhook, a live-verified idempotency guarantee, an executed refund, a live tax read, a live region verification, or a released provider on the delayed path, and refuses any expansion budget that is not frozen.',
      'A registered provider set is never reviewed while drifting: the gate refuses a record that drops a registered provider, invents an unknown provider, or duplicates a provider, and refuses a record whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, and charter count do not all reconcile to 32.',
      'A reference state is never invented: each of the seven outputs is grounded by the committed witness vocabulary for that output, so a reference state cannot be recorded without a witness to ground it.',
      'Payment connector selection, live tokenization verification, live webhook delivery, live idempotency verification, refund execution, live tax reads, live region verification, credential access, connector certification, provider exposure, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'payment connector selection',
      'live tokenization verification',
      'live webhook delivery',
      'live idempotency verification',
      'refund execution',
      'live tax reads',
      'live region verification',
      'credential access',
      'connector certification evidence',
      'provider exposure authorization',
      'public release publication',
    ],
  };
  final target = File(Sprint118PaymentConnectorContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('declared_provider_count=${report.declaredProviders.length}');
  stdout.writeln('certified_count=${report.certifiedCount}');
  stdout.writeln('selected_count=${report.selectedCount}');
  stdout.writeln('written=${target.path}');
}
