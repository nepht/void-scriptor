import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_ai_connector_expansion.dart';

/// A single AI connector expansion entry. Each test flips exactly the one thing
/// it is about, so a test that flips nothing proves the pass path exists and
/// every other test proves one way the gate refuses to take it.
Sprint118AiConnectorEntry _entry({
  String providerId = 'openai',
  String selectedProvider = Sprint118AiConnectorContract.selectedProviderToken,
  String models = Sprint118AiConnectorContract.modelsToken,
  String usage = Sprint118AiConnectorContract.usageToken,
  String cost = Sprint118AiConnectorContract.costToken,
  String privacyDestination =
      Sprint118AiConnectorContract.privacyDestinationToken,
  String cancellation = Sprint118AiConnectorContract.cancellationToken,
  String fallback = Sprint118AiConnectorContract.fallbackToken,
  bool certified = false,
  bool selected = false,
  bool modelsVerified = false,
  bool usageVerified = false,
  bool costVerified = false,
  bool privacyDestinationVerified = false,
  bool cancellationVerified = false,
  bool fallbackVerified = false,
  bool released = false,
}) {
  return Sprint118AiConnectorEntry(
    providerId: providerId,
    selectedProvider: selectedProvider,
    models: models,
    usage: usage,
    cost: cost,
    privacyDestination: privacyDestination,
    cancellation: cancellation,
    fallback: fallback,
    certified: certified,
    selected: selected,
    modelsVerified: modelsVerified,
    usageVerified: usageVerified,
    costVerified: costVerified,
    privacyDestinationVerified: privacyDestinationVerified,
    cancellationVerified: cancellationVerified,
    fallbackVerified: fallbackVerified,
    released: released,
  );
}

Sprint118AiConnectorRecord _record({
  String releaseState = Sprint118AiConnectorContract.delayedReleaseState,
  List<Sprint118AiConnectorEntry>? entries,
}) {
  return Sprint118AiConnectorRecord(
    releaseState: releaseState,
    entries: entries ?? Sprint118AiConnectorContract.canonicalRecord.entries,
  );
}

/// The canonical entries with exactly one provider replaced, so a test can flip
/// a single entry without rebuilding the whole record.
List<Sprint118AiConnectorEntry> _replacing(
  String providerId,
  Sprint118AiConnectorEntry replacement,
) {
  return <Sprint118AiConnectorEntry>[
    for (final e in Sprint118AiConnectorContract.canonicalRecord.entries)
      if (e.providerId == providerId) replacement else e,
  ];
}

Sprint118AiConnectorAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict = Sprint118AiConnectorContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint118AiConnectorContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict = Sprint118AiConnectorContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered = Sprint118AiConnectorContract.expectedProviderCount,
  String releaseState = Sprint118AiConnectorContract.delayedReleaseState,
  int registryExpectedCount =
      Sprint118AiConnectorContract.expectedProviderCount,
  String approvalDecision =
      Sprint118AiConnectorContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  String aiHealthState = Sprint118AiConnectorContract.requiredAiHealthState,
  String aiHealthVerdict = Sprint118AiConnectorContract.requiredAiHealthVerdict,
  List<String>? registeredProviders,
  List<String>? selectedProviderVocabulary,
  List<String>? modelsVocabulary,
  List<String>? usageVocabulary,
  List<String>? costVocabulary,
  List<String>? privacyDestinationVocabulary,
  List<String>? cancellationVocabulary,
  List<String>? fallbackVocabulary,
  List<String>? readableSources,
}) {
  return Sprint118AiConnectorAnchor(
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
    aiHealthState: aiHealthState,
    aiHealthVerdict: aiHealthVerdict,
    registeredProviders:
        registeredProviders ?? Sprint118AiConnectorContract.canonicalProviders,
    selectedProviderVocabulary:
        selectedProviderVocabulary ??
        const <String>[
          'connect',
          'model_select',
          'fallback',
          'timeout',
          'budget',
          'prefer_local',
          'health_test',
        ],
    modelsVocabulary:
        modelsVocabulary ??
        const <String>[
          'provider_id',
          'models',
          'modalities',
          'endpoint',
          'regions',
          'pricing_metadata',
          'privacy_metadata',
          'availability',
        ],
    usageVocabulary:
        usageVocabulary ??
        const <String>[
          'provider_id',
          'supported_modalities',
          'models',
          'auth',
          'cancellation',
          'usage_metadata',
          'cost_labels',
          'privacy',
          'errors',
          'limitations',
        ],
    costVocabulary:
        costVocabulary ??
        const <String>[
          'usage_units',
          'app_credit_separation',
          'provider_cost',
          'estimated_label',
          'currency',
          'freshness',
          'budget_alert',
        ],
    privacyDestinationVocabulary:
        privacyDestinationVocabulary ??
        const <String>[
          'provider_id',
          'routing_metadata',
          'models',
          'provider_fallback',
          'usage',
          'cost',
          'privacy_destination',
          'errors',
          'limitations',
        ],
    cancellationVocabulary:
        cancellationVocabulary ??
        const <String>[
          'provider_id',
          'models',
          'auth',
          'streaming',
          'cancellation',
          'usage_metadata',
          'cost_labels',
          'privacy',
          'errors',
          'limitations',
        ],
    fallbackVocabulary:
        fallbackVocabulary ??
        const <String>[
          'connect',
          'model_select',
          'fallback',
          'timeout',
          'budget',
          'prefer_local',
          'health_test',
        ],
    readableSources:
        readableSources ??
        Sprint118AiConnectorContract.witnessSources.toSet().toList(),
  );
}

Sprint118AiConnectorReport _run(
  Sprint118AiConnectorRecord record, {
  Sprint118AiConnectorAnchor? anchor,
}) {
  return const Sprint118AiConnectorGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.35 AI Connector Expansion', () {
    test('the canonical field vocabulary is the eight objective fields', () {
      expect(Sprint118AiConnectorContract.requiredFields, <String>[
        'provider_id',
        'selected_provider',
        'models',
        'usage',
        'cost',
        'privacy_destination',
        'cancellation',
        'fallback',
      ]);
    });

    test('the canonical outputs are the seven objective items', () {
      expect(Sprint118AiConnectorContract.requiredOutputs, <String>[
        'selected_provider',
        'models',
        'usage',
        'cost',
        'privacy_destination',
        'cancellation',
        'fallback',
      ]);
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary = Sprint118AiConnectorContract.stateVocabulary(
          <List<String>>[
            const <String>['models', 'usage_metadata'],
            const <String>['provider_cost', 'privacy_destination'],
          ],
        );
        expect(vocabulary, contains('models'));
        expect(vocabulary, contains('usage_metadata'));
        expect(vocabulary, contains('provider_cost'));
        expect(
          vocabulary,
          contains(Sprint118AiConnectorContract.noReferenceState),
        );
        expect(
          Sprint118AiConnectorContract.grounds(vocabulary, 'models'),
          isTrue,
        );
        expect(
          Sprint118AiConnectorContract.grounds(vocabulary, 'telepathy'),
          isFalse,
        );
      },
    );

    test(
      'canonical record covers all 32 registered providers and claims nothing',
      () {
        final record = Sprint118AiConnectorContract.canonicalRecord;
        expect(record.entries.length, 32);
        expect(
          record.providerIds.toSet(),
          Sprint118AiConnectorContract.canonicalProviders.toSet(),
        );
        for (final entry in record.entries) {
          expect(entry.certified, isFalse);
          expect(entry.selected, isFalse);
          expect(entry.modelsVerified, isFalse);
          expect(entry.usageVerified, isFalse);
          expect(entry.costVerified, isFalse);
          expect(entry.privacyDestinationVerified, isFalse);
          expect(entry.cancellationVerified, isFalse);
          expect(entry.fallbackVerified, isFalse);
          expect(entry.released, isFalse);
          for (final field in Sprint118AiConnectorContract.requiredFields) {
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
      expect(report.state, Sprint118AiConnectorState.pass);
      expect(report.verdict, 'AI_CONNECTOR_EXPANSION_VERIFIED_LOCAL');
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
      final report = const Sprint118AiConnectorGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118AiConnectorState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_AI_CONNECTOR_EXPANSION_EVIDENCE_UNREADABLE',
      );
      expect(report.certificationVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_ai_connector_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is not complete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE_LOCAL'),
      );
      expect(report.state, Sprint118AiConnectorState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_AI_CONNECTOR_EXPANSION_BLOCKED_UPSTREAM',
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
      expect(report.state, Sprint118AiConnectorState.blocked);
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
      expect(report.state, Sprint118AiConnectorState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('approval_gate_not_delay:')),
        isTrue,
      );
    });

    test('blocks when the committed AI provider health is not a pass', () {
      final report = _run(
        _record(),
        anchor: _anchor(aiHealthVerdict: 'AI_PROVIDER_HEALTH_DRIFT'),
      );
      expect(report.state, Sprint118AiConnectorState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('ai_health_not_verified:')),
        isTrue,
      );
    });

    test('blocks when the registered provider set does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(registryExpectedCount: 31),
      );
      expect(report.state, Sprint118AiConnectorState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('registry_not_reconciled:')),
        isTrue,
      );
    });

    test('fails when a provider claims a certified connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', certified: true),
          ),
        ),
      );
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations,
        contains('ai_connector_certified_claimed_on_delayed_path:openai'),
      );
      expect(report.certifiedCount, 1);
    });

    test('fails when a provider claims it was selected', () {
      final report = _run(
        _record(
          entries: _replacing(
            'gemini',
            _entry(providerId: 'gemini', selected: true),
          ),
        ),
      );
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations,
        contains('ai_connector_selected_claimed_on_delayed_path:gemini'),
      );
      expect(report.selectedCount, 1);
    });

    test('fails when a model catalog is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'anthropic',
            _entry(providerId: 'anthropic', modelsVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations,
        contains('ai_connector_models_verified_on_delayed_path:anthropic'),
      );
    });

    test('fails when a usage is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openrouter',
            _entry(providerId: 'openrouter', usageVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations,
        contains('ai_connector_usage_verified_on_delayed_path:openrouter'),
      );
    });

    test('fails when a cost is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'local_ai',
            _entry(providerId: 'local_ai', costVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations,
        contains('ai_connector_cost_verified_on_delayed_path:local_ai'),
      );
    });

    test('fails when a privacy destination is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'flux',
            _entry(providerId: 'flux', privacyDestinationVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations,
        contains(
          'ai_connector_privacy_destination_verified_on_delayed_path:flux',
        ),
      );
    });

    test('fails when a cancellation is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'google',
            _entry(providerId: 'google', cancellationVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations,
        contains('ai_connector_cancellation_verified_on_delayed_path:google'),
      );
    });

    test('fails when a fallback is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'microsoft',
            _entry(providerId: 'microsoft', fallbackVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations,
        contains('ai_connector_fallback_verified_on_delayed_path:microsoft'),
      );
    });

    test('fails when a provider is claimed released', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', released: true),
          ),
        ),
      );
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations,
        contains('ai_connector_provider_released_claimed:stripe'),
      );
    });

    test('fails when the expansion budget is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterMaxNewCertified: 1),
      );
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('ai_connector_expansion_budget_not_frozen:'),
        ),
        isTrue,
      );
      expect(report.expansionBudgetFrozen, isFalse);
    });

    test('fails when a registered provider is missing', () {
      final entries = <Sprint118AiConnectorEntry>[
        for (final e in Sprint118AiConnectorContract.canonicalRecord.entries)
          if (e.providerId != 'kofi') e,
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(report.violations, contains('ai_connector_provider_missing:kofi'));
    });

    test('fails when an unknown provider is invented', () {
      final entries = <Sprint118AiConnectorEntry>[
        ...Sprint118AiConnectorContract.canonicalRecord.entries,
        _entry(providerId: 'telepathy'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations,
        contains('ai_connector_provider_unknown:telepathy'),
      );
    });

    test('fails when a provider is duplicated', () {
      final entries = <Sprint118AiConnectorEntry>[
        ...Sprint118AiConnectorContract.canonicalRecord.entries,
        _entry(providerId: 'openai'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations,
        contains('ai_connector_provider_duplicate:openai'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', models: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(report.violations, contains('entry_blank_models:openai'));
    });

    test('fails when a reference state is not grounded by a witness', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', usage: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:usage:openai'),
      );
    });

    test('records an open item when a requirement has no reference state', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(
              providerId: 'openai',
              fallback: Sprint118AiConnectorContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118AiConnectorState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:fallback:openai'),
      );
    });

    test('fails when the record is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations,
        contains('ai_connector_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test('fails when the release state disagrees with the anchor', () {
      final report = _run(
        _record(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118AiConnectorState.fail);
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
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations,
        contains('ai_connector_execution_authorized_on_delayed_path'),
      );
    });

    test('fails when the release is not blocked on the delayed path', () {
      final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations,
        contains('ai_connector_release_not_blocked_on_delayed_path'),
      );
    });

    test('fails when a committed evidence source is unreadable', () {
      final report = _run(
        _record(),
        anchor: _anchor(readableSources: const <String>[]),
      );
      expect(report.state, Sprint118AiConnectorState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('required_source_unreadable:'),
        ),
        isTrue,
      );
    });

    test('the canonical sources cover every requirement', () {
      expect(
        Sprint118AiConnectorContract.canonicalSources.length,
        Sprint118AiConnectorContract.requiredOutputs.length,
      );
      for (final output in Sprint118AiConnectorContract.requiredOutputs) {
        expect(
          Sprint118AiConnectorContract.sourceFor(output),
          isNotEmpty,
          reason: '$output must have a committed source',
        );
      }
    });

    test('the loader reads the committed witnesses', () {
      final anchor = const Sprint118AiConnectorLoader().loadAnchor();
      expect(anchor, isNotNull);
      expect(anchor!.registeredProviders.length, 32);
      expect(anchor.charterVerdict, 'CHARTER_COMPLETE_LOCAL');
      expect(
        anchor.snapshotVerdict,
        'CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL',
      );
      expect(anchor.approvalDecision, 'delay');
      expect(anchor.aiHealthVerdict, 'AI_PROVIDER_HEALTH_VERIFIED_LOCAL');
      expect(anchor.readableSources.length, 12);
      expect(anchor.selectedProviderVocabulary, contains('connect'));
      expect(anchor.modelsVocabulary, contains('models'));
      expect(anchor.usageVocabulary, contains('usage_metadata'));
      expect(anchor.costVocabulary, contains('provider_cost'));
      expect(
        anchor.privacyDestinationVocabulary,
        contains('privacy_destination'),
      );
      expect(anchor.cancellationVocabulary, contains('cancellation'));
      expect(anchor.fallbackVocabulary, contains('fallback'));
    });

    test('the gate passes end to end against the committed witnesses', () {
      final report = const Sprint118AiConnectorGate().evaluate();
      expect(report.state, Sprint118AiConnectorState.pass);
      expect(report.verdict, 'AI_CONNECTOR_EXPANSION_VERIFIED_LOCAL');
      expect(report.certifiedCount, 0);
      expect(report.selectedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });
  });
}
