import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_payment_connector_expansion.dart';

/// A single payment connector expansion entry. Each test flips exactly the one
/// thing it is about, so a test that flips nothing proves the pass path exists
/// and every other test proves one way the gate refuses to take it.
Sprint118PaymentConnectorEntry _entry({
  String providerId = 'stripe',
  String selectedProvider =
      Sprint118PaymentConnectorContract.selectedProviderToken,
  String tokenization = Sprint118PaymentConnectorContract.tokenizationToken,
  String webhooks = Sprint118PaymentConnectorContract.webhooksToken,
  String idempotency = Sprint118PaymentConnectorContract.idempotencyToken,
  String refund = Sprint118PaymentConnectorContract.refundToken,
  String tax = Sprint118PaymentConnectorContract.taxToken,
  String regions = Sprint118PaymentConnectorContract.regionsToken,
  bool certified = false,
  bool selected = false,
  bool tokenizationVerified = false,
  bool webhooksVerified = false,
  bool idempotencyVerified = false,
  bool refundVerified = false,
  bool taxVerified = false,
  bool regionsVerified = false,
  bool released = false,
}) {
  return Sprint118PaymentConnectorEntry(
    providerId: providerId,
    selectedProvider: selectedProvider,
    tokenization: tokenization,
    webhooks: webhooks,
    idempotency: idempotency,
    refund: refund,
    tax: tax,
    regions: regions,
    certified: certified,
    selected: selected,
    tokenizationVerified: tokenizationVerified,
    webhooksVerified: webhooksVerified,
    idempotencyVerified: idempotencyVerified,
    refundVerified: refundVerified,
    taxVerified: taxVerified,
    regionsVerified: regionsVerified,
    released: released,
  );
}

Sprint118PaymentConnectorRecord _record({
  String releaseState = Sprint118PaymentConnectorContract.delayedReleaseState,
  List<Sprint118PaymentConnectorEntry>? entries,
}) {
  return Sprint118PaymentConnectorRecord(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118PaymentConnectorContract.canonicalRecord.entries,
  );
}

/// The canonical entries with exactly one provider replaced, so a test can flip
/// a single entry without rebuilding the whole record.
List<Sprint118PaymentConnectorEntry> _replacing(
  String providerId,
  Sprint118PaymentConnectorEntry replacement,
) {
  return <Sprint118PaymentConnectorEntry>[
    for (final e in Sprint118PaymentConnectorContract.canonicalRecord.entries)
      if (e.providerId == providerId) replacement else e,
  ];
}

Sprint118PaymentConnectorAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict =
      Sprint118PaymentConnectorContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint118PaymentConnectorContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict =
      Sprint118PaymentConnectorContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered =
      Sprint118PaymentConnectorContract.expectedProviderCount,
  String releaseState = Sprint118PaymentConnectorContract.delayedReleaseState,
  int registryExpectedCount =
      Sprint118PaymentConnectorContract.expectedProviderCount,
  String approvalDecision =
      Sprint118PaymentConnectorContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  String paymentWorkflowStatus =
      Sprint118PaymentConnectorContract.requiredPaymentWorkflowStatus,
  String paymentWorkflowVerdict =
      Sprint118PaymentConnectorContract.requiredPaymentWorkflowVerdict,
  List<String>? registeredProviders,
  List<String>? selectedProviderVocabulary,
  List<String>? tokenizationVocabulary,
  List<String>? webhooksVocabulary,
  List<String>? idempotencyVocabulary,
  List<String>? refundVocabulary,
  List<String>? taxVocabulary,
  List<String>? regionsVocabulary,
  List<String>? readableSources,
}) {
  return Sprint118PaymentConnectorAnchor(
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterMaxNewCertified: charterMaxNewCertified,
    charterCurrentlyCertified: charterCurrentlyCertified,
    charterRegisteredProviders: charterRegisteredProviders,
    snapshotState: snapshotState,
    snapshotVerdict: snapshotVerdict,
    snapshotCertified: snapshotCertified,
    snapshotRegistered: snapshotRegistered,
    releaseState: releaseState,
    registryExpectedCount: registryExpectedCount,
    approvalDecision: approvalDecision,
    approvalState: approvalState,
    executionAuthorized: executionAuthorized,
    releaseBlocked: releaseBlocked,
    paymentWorkflowStatus: paymentWorkflowStatus,
    paymentWorkflowVerdict: paymentWorkflowVerdict,
    registeredProviders:
        registeredProviders ??
        Sprint118PaymentConnectorContract.canonicalProviders,
    selectedProviderVocabulary:
        selectedProviderVocabulary ??
        const <String>[
          'provider_token_only',
          'masked_details',
          'default_method',
          'replace_remove',
          'region_availability',
          'reauth',
        ],
    tokenizationVocabulary:
        tokenizationVocabulary ??
        const <String>[
          'os_secure_store',
          'no_plaintext',
          'masked_display',
          'reauth',
          'audit_redaction',
          'clipboard_timeout',
        ],
    webhooksVocabulary:
        webhooksVocabulary ??
        const <String>[
          'payment_subscription_flow',
          'redirects',
          'webhooks',
          'refunds',
          'region',
          'errors',
        ],
    idempotencyVocabulary:
        idempotencyVocabulary ??
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
    refundVocabulary:
        refundVocabulary ??
        const <String>[
          'invoice_list',
          'receipt',
          'payment_status',
          'tax_info',
          'download',
          'refund_path',
          'dispute_path',
        ],
    taxVocabulary:
        taxVocabulary ??
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
    regionsVocabulary:
        regionsVocabulary ??
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
        Sprint118PaymentConnectorContract.witnessSources.toSet().toList(),
  );
}

Sprint118PaymentConnectorReport _run(
  Sprint118PaymentConnectorRecord record, {
  Sprint118PaymentConnectorAnchor? anchor,
}) {
  return const Sprint118PaymentConnectorGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.38 Payment Connector Expansion', () {
    test('the canonical field vocabulary is the eight objective fields', () {
      expect(Sprint118PaymentConnectorContract.requiredFields, <String>[
        'provider_id',
        'selected_provider',
        'tokenization',
        'webhooks',
        'idempotency',
        'refund',
        'tax',
        'regions',
      ]);
    });

    test('the canonical outputs are the seven objective items', () {
      expect(Sprint118PaymentConnectorContract.requiredOutputs, <String>[
        'selected_provider',
        'tokenization',
        'webhooks',
        'idempotency',
        'refund',
        'tax',
        'regions',
      ]);
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary = Sprint118PaymentConnectorContract.stateVocabulary(
          <List<String>>[
            const <String>['provider_token_only', 'reauth'],
            const <String>['os_secure_store', 'no_plaintext'],
          ],
        );
        expect(vocabulary, contains('provider_token_only'));
        expect(vocabulary, contains('reauth'));
        expect(vocabulary, contains('os_secure_store'));
        expect(vocabulary, contains('no_plaintext'));
        expect(
          vocabulary,
          contains(Sprint118PaymentConnectorContract.noReferenceState),
        );
        expect(
          Sprint118PaymentConnectorContract.grounds(
            vocabulary,
            'provider_token_only',
          ),
          isTrue,
        );
        expect(
          Sprint118PaymentConnectorContract.grounds(vocabulary, 'telepathy'),
          isFalse,
        );
      },
    );

    test(
      'canonical record covers all 32 registered providers and claims nothing',
      () {
        final record = Sprint118PaymentConnectorContract.canonicalRecord;
        expect(record.entries.length, 32);
        expect(
          record.providerIds.toSet(),
          Sprint118PaymentConnectorContract.canonicalProviders.toSet(),
        );
        for (final entry in record.entries) {
          expect(entry.certified, isFalse);
          expect(entry.selected, isFalse);
          expect(entry.tokenizationVerified, isFalse);
          expect(entry.webhooksVerified, isFalse);
          expect(entry.idempotencyVerified, isFalse);
          expect(entry.refundVerified, isFalse);
          expect(entry.taxVerified, isFalse);
          expect(entry.regionsVerified, isFalse);
          expect(entry.released, isFalse);
          for (final field
              in Sprint118PaymentConnectorContract.requiredFields) {
            expect(
              (entry.requiredFields[field] ?? '').trim(),
              isNotEmpty,
              reason: '${entry.providerId}.$field must not be blank',
            );
          }
        }
      },
    );

    test('passes on the canonical record and claims no live certification', () {
      final report = _run(_record());
      expect(report.state, Sprint118PaymentConnectorState.pass);
      expect(report.verdict, 'PAYMENT_CONNECTOR_EXPANSION_VERIFIED_LOCAL');
      expect(report.certificationVerified, isTrue);
      expect(report.declaredProviders.length, 32);
      expect(report.certifiedProviders, isEmpty);
      expect(report.selectedProviders, isEmpty);
      expect(report.expansionBudgetFrozen, isTrue);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118PaymentConnectorGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118PaymentConnectorState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_PAYMENT_CONNECTOR_EXPANSION_EVIDENCE_UNREADABLE',
      );
      expect(report.certificationVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_payment_connector_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is not complete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE_LOCAL'),
      );
      expect(report.state, Sprint118PaymentConnectorState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_PAYMENT_CONNECTOR_EXPANSION_BLOCKED_UPSTREAM',
      );
      expect(
        report.blockers.any((b) => b.startsWith('charter_not_complete:')),
        isTrue,
      );
    });

    test('blocks when the committed snapshot is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(snapshotVerdict: 'CERTIFIED_CONNECTOR_SNAPSHOT_DRIFT'),
      );
      expect(report.state, Sprint118PaymentConnectorState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('snapshot_not_frozen:')),
        isTrue,
      );
    });

    test('blocks when the committed approval gate is not a delay', () {
      final report = _run(
        _record(),
        anchor: _anchor(approvalDecision: 'release'),
      );
      expect(report.state, Sprint118PaymentConnectorState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('approval_gate_not_delay:')),
        isTrue,
      );
    });

    test('blocks when the committed billing workflow is not a pass', () {
      final report = _run(
        _record(),
        anchor: _anchor(
          paymentWorkflowVerdict: 'BILLING_ENTITLEMENT_HEALTH_DRIFT',
        ),
      );
      expect(report.state, Sprint118PaymentConnectorState.blocked);
      expect(
        report.blockers.any(
          (b) => b.startsWith('payment_workflow_not_validated:'),
        ),
        isTrue,
      );
    });

    test('blocks when the registered provider set does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(registryExpectedCount: 31),
      );
      expect(report.state, Sprint118PaymentConnectorState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('registry_not_reconciled:')),
        isTrue,
      );
    });

    test('fails when a provider claims a certified connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', certified: true),
          ),
        ),
      );
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations,
        contains('payment_connector_certified_claimed_on_delayed_path:stripe'),
      );
      expect(report.certifiedCount, 1);
    });

    test('fails when a provider claims it was selected', () {
      final report = _run(
        _record(
          entries: _replacing(
            'paypal',
            _entry(providerId: 'paypal', selected: true),
          ),
        ),
      );
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations,
        contains('payment_connector_selected_claimed_on_delayed_path:paypal'),
      );
      expect(report.selectedCount, 1);
    });

    test('fails when a tokenization is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'midtrans',
            _entry(providerId: 'midtrans', tokenizationVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations,
        contains(
          'payment_connector_tokenization_verified_on_delayed_path:midtrans',
        ),
      );
    });

    test('fails when a webhook is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'saweria',
            _entry(providerId: 'saweria', webhooksVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations,
        contains('payment_connector_webhooks_verified_on_delayed_path:saweria'),
      );
    });

    test('fails when an idempotency guarantee is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'kofi',
            _entry(providerId: 'kofi', idempotencyVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations,
        contains('payment_connector_idempotency_verified_on_delayed_path:kofi'),
      );
    });

    test('fails when a refund is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', refundVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations,
        contains('payment_connector_refund_verified_on_delayed_path:stripe'),
      );
    });

    test('fails when a tax read is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'paypal',
            _entry(providerId: 'paypal', taxVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations,
        contains('payment_connector_tax_verified_on_delayed_path:paypal'),
      );
    });

    test('fails when a region is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'midtrans',
            _entry(providerId: 'midtrans', regionsVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations,
        contains('payment_connector_regions_verified_on_delayed_path:midtrans'),
      );
    });

    test('fails when a provider is claimed released', () {
      final report = _run(
        _record(
          entries: _replacing(
            'kofi',
            _entry(providerId: 'kofi', released: true),
          ),
        ),
      );
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations,
        contains('payment_connector_provider_released_claimed:kofi'),
      );
    });

    test('fails when the expansion budget is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterMaxNewCertified: 1),
      );
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('payment_connector_expansion_budget_not_frozen:'),
        ),
        isTrue,
      );
      expect(report.expansionBudgetFrozen, isFalse);
    });

    test('fails when a registered provider is missing', () {
      final entries = <Sprint118PaymentConnectorEntry>[
        for (final e
            in Sprint118PaymentConnectorContract.canonicalRecord.entries)
          if (e.providerId != 'kofi') e,
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations,
        contains('payment_connector_provider_missing:kofi'),
      );
    });

    test('fails when an unknown provider is invented', () {
      final entries = <Sprint118PaymentConnectorEntry>[
        ...Sprint118PaymentConnectorContract.canonicalRecord.entries,
        _entry(providerId: 'telepathy'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations,
        contains('payment_connector_provider_unknown:telepathy'),
      );
    });

    test('fails when a provider is duplicated', () {
      final entries = <Sprint118PaymentConnectorEntry>[
        ...Sprint118PaymentConnectorContract.canonicalRecord.entries,
        _entry(providerId: 'stripe'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations,
        contains('payment_connector_provider_duplicate:stripe'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', tokenization: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(report.violations, contains('entry_blank_tokenization:stripe'));
    });

    test('fails when a reference state is not grounded by a witness', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', tokenization: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:tokenization:stripe'),
      );
    });

    test('records an open item when a requirement has no reference state', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(
              providerId: 'stripe',
              tokenization: Sprint118PaymentConnectorContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PaymentConnectorState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:tokenization:stripe'),
      );
    });

    test('fails when the record is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations,
        contains('payment_connector_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test('fails when the release state disagrees with the anchor', () {
      final report = _run(
        _record(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when execution is authorized on the delayed path', () {
      final report = _run(
        _record(),
        anchor: _anchor(executionAuthorized: true),
      );
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations,
        contains('payment_connector_execution_authorized_on_delayed_path'),
      );
    });

    test('fails when the release is not blocked on the delayed path', () {
      final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations,
        contains('payment_connector_release_not_blocked_on_delayed_path'),
      );
    });

    test('fails when a committed evidence source is unreadable', () {
      final report = _run(
        _record(),
        anchor: _anchor(readableSources: const <String>[]),
      );
      expect(report.state, Sprint118PaymentConnectorState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('required_source_unreadable:'),
        ),
        isTrue,
      );
    });

    test('the canonical sources cover every requirement', () {
      expect(
        Sprint118PaymentConnectorContract.canonicalSources.length,
        Sprint118PaymentConnectorContract.requiredOutputs.length,
      );
      for (final output in Sprint118PaymentConnectorContract.requiredOutputs) {
        expect(
          Sprint118PaymentConnectorContract.sourceFor(output),
          isNotEmpty,
          reason: '$output must have a committed source',
        );
      }
    });

    test('the loader reads the committed witnesses', () {
      final anchor = const Sprint118PaymentConnectorLoader().loadAnchor();
      expect(anchor, isNotNull);
      expect(anchor!.registeredProviders.length, 32);
      expect(anchor.charterVerdict, 'CHARTER_COMPLETE_LOCAL');
      expect(
        anchor.snapshotVerdict,
        'CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL',
      );
      expect(anchor.approvalDecision, 'delay');
      expect(
        anchor.paymentWorkflowVerdict,
        'BILLING_ENTITLEMENT_HEALTH_VERIFIED_LOCAL',
      );
      expect(anchor.readableSources.length, 13);
      expect(
        anchor.selectedProviderVocabulary,
        contains('provider_token_only'),
      );
      expect(anchor.tokenizationVocabulary, contains('os_secure_store'));
      expect(anchor.webhooksVocabulary, contains('webhooks'));
      expect(anchor.idempotencyVocabulary, contains('idempotency'));
      expect(anchor.refundVocabulary, contains('refund_path'));
      expect(anchor.taxVocabulary, contains('tax'));
      expect(anchor.regionsVocabulary, contains('region'));
    });

    test('the gate passes end to end against the committed witnesses', () {
      final report = const Sprint118PaymentConnectorGate().evaluate();
      expect(report.state, Sprint118PaymentConnectorState.pass);
      expect(report.verdict, 'PAYMENT_CONNECTOR_EXPANSION_VERIFIED_LOCAL');
      expect(report.certifiedCount, 0);
      expect(report.selectedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });
  });
}
