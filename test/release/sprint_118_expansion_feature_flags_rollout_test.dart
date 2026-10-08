import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_expansion_feature_flags_rollout.dart';

/// A single rollout record entry. Each test flips exactly the one thing it is
/// about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it.
Sprint118ExpansionFeatureFlagEntry _entry({
  String providerId = 'stripe',
  String flag = Sprint118ExpansionFeatureFlagContract.flagToken,
  String audience = Sprint118ExpansionFeatureFlagContract.audienceToken,
  String defaultState = Sprint118ExpansionFeatureFlagContract.defaultToken,
  String dependencies = Sprint118ExpansionFeatureFlagContract.dependenciesToken,
  String healthCriteria =
      Sprint118ExpansionFeatureFlagContract.healthCriteriaToken,
  String killSwitch = Sprint118ExpansionFeatureFlagContract.killSwitchToken,
  String rollback = Sprint118ExpansionFeatureFlagContract.rollbackToken,
  String support = Sprint118ExpansionFeatureFlagContract.supportToken,
  bool enabled = false,
  bool flipped = false,
  bool rolledOut = false,
  bool killSwitchDrilled = false,
  bool rollbackExecuted = false,
  bool supported = false,
  bool certified = false,
  bool released = false,
}) {
  return Sprint118ExpansionFeatureFlagEntry(
    providerId: providerId,
    flag: flag,
    audience: audience,
    defaultState: defaultState,
    dependencies: dependencies,
    healthCriteria: healthCriteria,
    killSwitch: killSwitch,
    rollback: rollback,
    support: support,
    enabled: enabled,
    flipped: flipped,
    rolledOut: rolledOut,
    killSwitchDrilled: killSwitchDrilled,
    rollbackExecuted: rollbackExecuted,
    supported: supported,
    certified: certified,
    released: released,
  );
}

Sprint118ExpansionFeatureFlagRecord _record({
  String releaseState =
      Sprint118ExpansionFeatureFlagContract.delayedReleaseState,
  List<Sprint118ExpansionFeatureFlagEntry>? entries,
}) {
  return Sprint118ExpansionFeatureFlagRecord(
    releaseState: releaseState,
    entries:
        entries ??
        Sprint118ExpansionFeatureFlagContract.canonicalRecord.entries,
  );
}

/// The canonical entries with exactly one provider replaced, so a test can flip
/// a single entry without rebuilding the whole record.
List<Sprint118ExpansionFeatureFlagEntry> _replacing(
  String providerId,
  Sprint118ExpansionFeatureFlagEntry replacement,
) {
  return <Sprint118ExpansionFeatureFlagEntry>[
    for (final e
        in Sprint118ExpansionFeatureFlagContract.canonicalRecord.entries)
      if (e.providerId == providerId) replacement else e,
  ];
}

Sprint118ExpansionFeatureFlagAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict =
      Sprint118ExpansionFeatureFlagContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint118ExpansionFeatureFlagContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict =
      Sprint118ExpansionFeatureFlagContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered =
      Sprint118ExpansionFeatureFlagContract.expectedProviderCount,
  String releaseState =
      Sprint118ExpansionFeatureFlagContract.delayedReleaseState,
  int registryExpectedCount =
      Sprint118ExpansionFeatureFlagContract.expectedProviderCount,
  int registryEvidenceProviderCount =
      Sprint118ExpansionFeatureFlagContract.expectedProviderCount,
  int registryEvidenceExposed = 0,
  int registryEvidenceWithheld =
      Sprint118ExpansionFeatureFlagContract.expectedProviderCount,
  int snapshotLockLockedCount =
      Sprint118ExpansionFeatureFlagContract.expectedProviderCount,
  String approvalDecision =
      Sprint118ExpansionFeatureFlagContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  List<String>? registeredProviders,
  List<String>? flagVocabulary,
  List<String>? audienceVocabulary,
  List<String>? defaultVocabulary,
  List<String>? dependencyVocabulary,
  List<String>? healthVocabulary,
  List<String>? killSwitchVocabulary,
  List<String>? rollbackVocabulary,
  List<String>? supportVocabulary,
  List<String>? readableSources,
}) {
  return Sprint118ExpansionFeatureFlagAnchor(
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
    registryEvidenceProviderCount: registryEvidenceProviderCount,
    registryEvidenceExposed: registryEvidenceExposed,
    registryEvidenceWithheld: registryEvidenceWithheld,
    snapshotLockLockedCount: snapshotLockLockedCount,
    approvalDecision: approvalDecision,
    approvalState: approvalState,
    executionAuthorized: executionAuthorized,
    releaseBlocked: releaseBlocked,
    registeredProviders:
        registeredProviders ??
        Sprint118ExpansionFeatureFlagContract.canonicalProviders,
    flagVocabulary:
        flagVocabulary ??
        const <String>[
          'beta.connectors.enabled',
          'connector.openai.enabled',
          'connector.gemini.enabled',
        ],
    audienceVocabulary:
        audienceVocabulary ??
        const <String>['stage_internal', 'stage_alpha', 'stage_waitlist'],
    defaultVocabulary: defaultVocabulary ?? const <String>['OFF'],
    dependencyVocabulary: dependencyVocabulary ?? const <String>['none'],
    healthVocabulary:
        healthVocabulary ??
        const <String>[
          'metric_error_rate',
          'metric_auth_success',
          'metric_crash_rate',
        ],
    killSwitchVocabulary:
        killSwitchVocabulary ?? const <String>['kill_openai', 'kill_gemini'],
    rollbackVocabulary:
        rollbackVocabulary ??
        const <String>['rb_internal', 'rb_alpha', 'rb_waitlist'],
    supportVocabulary:
        supportVocabulary ??
        const <String>['support-owner', 'Choirudin', 'nephthys'],
    readableSources:
        readableSources ??
        Sprint118ExpansionFeatureFlagContract.witnessSources.toSet().toList(),
  );
}

Sprint118ExpansionFeatureFlagReport _run(
  Sprint118ExpansionFeatureFlagRecord record, {
  Sprint118ExpansionFeatureFlagAnchor? anchor,
}) {
  return const Sprint118ExpansionFeatureFlagGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.41 Expansion Feature Flags & Rollout', () {
    test('the canonical field vocabulary is the eight objective fields', () {
      expect(Sprint118ExpansionFeatureFlagContract.requiredFields, <String>[
        'flag',
        'audience',
        'default',
        'dependencies',
        'health_criteria',
        'kill_switch',
        'rollback',
        'support',
      ]);
    });

    test('the canonical outputs are the eight objective outputs', () {
      expect(Sprint118ExpansionFeatureFlagContract.requiredOutputs, <String>[
        'flag',
        'audience',
        'default',
        'dependencies',
        'health_criteria',
        'kill_switch',
        'rollback',
        'support',
      ]);
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary =
            Sprint118ExpansionFeatureFlagContract.stateVocabulary(
              <List<String>>[
                const <String>['beta.connectors.enabled', 'stage_internal'],
                const <String>['OFF', 'metric_error_rate'],
              ],
            );
        expect(vocabulary, contains('beta.connectors.enabled'));
        expect(vocabulary, contains('stage_internal'));
        expect(vocabulary, contains('OFF'));
        expect(vocabulary, contains('metric_error_rate'));
        expect(
          vocabulary,
          contains(Sprint118ExpansionFeatureFlagContract.noReferenceState),
        );
        expect(
          Sprint118ExpansionFeatureFlagContract.grounds(
            vocabulary,
            'beta.connectors.enabled',
          ),
          isTrue,
        );
        expect(
          Sprint118ExpansionFeatureFlagContract.grounds(
            vocabulary,
            'telepathy',
          ),
          isFalse,
        );
      },
    );

    test(
      'a compound reference state is grounded only when every part is a witness value',
      () {
        final vocabulary = <String>['no_plaintext', 'os_secure_store'];
        expect(
          Sprint118ExpansionFeatureFlagContract.grounds(
            vocabulary,
            'no_plaintext',
          ),
          isTrue,
        );
        expect(
          Sprint118ExpansionFeatureFlagContract.grounds(
            vocabulary,
            'os_secure_store',
          ),
          isTrue,
        );
        expect(
          Sprint118ExpansionFeatureFlagContract.grounds(
            vocabulary,
            'no_telepathy',
          ),
          isFalse,
        );
      },
    );

    test(
      'canonical record covers all 32 registered providers and claims nothing',
      () {
        final record = Sprint118ExpansionFeatureFlagContract.canonicalRecord;
        expect(record.entries.length, 32);
        expect(
          record.providerIds.toSet(),
          Sprint118ExpansionFeatureFlagContract.canonicalProviders.toSet(),
        );
        for (final entry in record.entries) {
          expect(entry.enabled, isFalse);
          expect(entry.flipped, isFalse);
          expect(entry.rolledOut, isFalse);
          expect(entry.killSwitchDrilled, isFalse);
          expect(entry.rollbackExecuted, isFalse);
          expect(entry.supported, isFalse);
          expect(entry.certified, isFalse);
          expect(entry.released, isFalse);
          for (final field
              in Sprint118ExpansionFeatureFlagContract.requiredFields) {
            expect(
              (entry.requiredFields[field] ?? '').trim(),
              isNotEmpty,
              reason: '${entry.providerId}.$field must not be blank',
            );
          }
        }
      },
    );

    test('passes on the canonical record and claims no live rollout', () {
      final report = _run(_record());
      expect(report.state, Sprint118ExpansionFeatureFlagState.pass);
      expect(report.verdict, 'EXPANSION_FEATURE_FLAGS_ROLLOUT_VERIFIED_LOCAL');
      expect(report.recordVerified, isTrue);
      expect(report.declaredProviders.length, 32);
      expect(report.enabledProviders, isEmpty);
      expect(report.flippedProviders, isEmpty);
      expect(report.rolledOutProviders, isEmpty);
      expect(report.certifiedProviders, isEmpty);
      expect(report.releasedProviders, isEmpty);
      expect(report.expansionBudgetFrozen, isTrue);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118ExpansionFeatureFlagGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_FEATURE_FLAGS_ROLLOUT_EVIDENCE_UNREADABLE',
      );
      expect(report.recordVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_feature_flags_rollout_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is not complete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE_LOCAL'),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_FEATURE_FLAGS_ROLLOUT_BLOCKED_UPSTREAM',
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
      expect(report.state, Sprint118ExpansionFeatureFlagState.blocked);
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
      expect(report.state, Sprint118ExpansionFeatureFlagState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('approval_gate_not_delay:')),
        isTrue,
      );
    });

    test('blocks when the registered provider set does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(registryExpectedCount: 31),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('registry_not_reconciled:')),
        isTrue,
      );
    });

    test(
      'blocks when the registry evidence provider count does not reconcile',
      () {
        final report = _run(
          _record(),
          anchor: _anchor(registryEvidenceProviderCount: 31),
        );
        expect(report.state, Sprint118ExpansionFeatureFlagState.blocked);
        expect(
          report.blockers.any((b) => b.startsWith('registry_not_reconciled:')),
          isTrue,
        );
      },
    );

    test('blocks when the snapshot lock count does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(snapshotLockLockedCount: 31),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('registry_not_reconciled:')),
        isTrue,
      );
    });

    test('blocks when the registry visibility does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(registryEvidenceWithheld: 31),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.blocked);
      expect(
        report.blockers.any(
          (b) => b.startsWith('registry_visibility_not_reconciled:'),
        ),
        isTrue,
      );
    });

    test('blocks when the registry already exposes a connector', () {
      final report = _run(
        _record(),
        anchor: _anchor(
          registryEvidenceExposed: 1,
          registryEvidenceWithheld: 31,
        ),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.blocked);
      expect(
        report.blockers.any(
          (b) => b.startsWith('registry_visibility_exposed_on_delayed_path:'),
        ),
        isTrue,
      );
    });

    test('fails when a provider claims an enabled connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', enabled: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations,
        contains(
          'expansion_feature_flags_enabled_claimed_on_delayed_path:stripe',
        ),
      );
      expect(report.enabledCount, 1);
    });

    test('fails when a provider claims a flipped flag', () {
      final report = _run(
        _record(
          entries: _replacing(
            'paypal',
            _entry(providerId: 'paypal', flipped: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations,
        contains(
          'expansion_feature_flags_flipped_claimed_on_delayed_path:paypal',
        ),
      );
      expect(report.flippedCount, 1);
    });

    test('fails when a provider claims an advanced rollout', () {
      final report = _run(
        _record(
          entries: _replacing(
            'midtrans',
            _entry(providerId: 'midtrans', rolledOut: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations,
        contains(
          'expansion_feature_flags_rolled_out_claimed_on_delayed_path:midtrans',
        ),
      );
      expect(report.rolledOutCount, 1);
    });

    test('fails when a provider claims a drilled kill switch', () {
      final report = _run(
        _record(
          entries: _replacing(
            'saweria',
            _entry(providerId: 'saweria', killSwitchDrilled: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations,
        contains(
          'expansion_feature_flags_kill_switch_drilled_claimed_on_delayed_path:saweria',
        ),
      );
    });

    test('fails when a provider claims an executed rollback', () {
      final report = _run(
        _record(
          entries: _replacing(
            'kofi',
            _entry(providerId: 'kofi', rollbackExecuted: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations,
        contains(
          'expansion_feature_flags_rollback_executed_claimed_on_delayed_path:kofi',
        ),
      );
    });

    test('fails when a provider claims an active support escalation', () {
      final report = _run(
        _record(
          entries: _replacing(
            'google_drive',
            _entry(providerId: 'google_drive', supported: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations,
        contains(
          'expansion_feature_flags_supported_claimed_on_delayed_path:google_drive',
        ),
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
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations,
        contains(
          'expansion_feature_flags_certified_claimed_on_delayed_path:openai',
        ),
      );
      expect(report.certifiedCount, 1);
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
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations,
        contains('expansion_feature_flags_released_claimed:stripe'),
      );
      expect(report.releasedCount, 1);
    });

    test('fails when the expansion budget is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterMaxNewCertified: 1),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith(
            'expansion_feature_flags_expansion_budget_not_frozen:',
          ),
        ),
        isTrue,
      );
      expect(report.expansionBudgetFrozen, isFalse);
    });

    test('fails when the snapshot certifies a connector', () {
      final report = _run(_record(), anchor: _anchor(snapshotCertified: 1));
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations,
        contains('expansion_feature_flags_snapshot_certified_nonzero:1'),
      );
    });

    test('fails when a registered provider is missing', () {
      final entries = <Sprint118ExpansionFeatureFlagEntry>[
        for (final e
            in Sprint118ExpansionFeatureFlagContract.canonicalRecord.entries)
          if (e.providerId != 'kofi') e,
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations,
        contains('expansion_feature_flags_provider_missing:kofi'),
      );
    });

    test('fails when an unknown provider is invented', () {
      final entries = <Sprint118ExpansionFeatureFlagEntry>[
        ...Sprint118ExpansionFeatureFlagContract.canonicalRecord.entries,
        _entry(providerId: 'telepathy'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations,
        contains('expansion_feature_flags_provider_unknown:telepathy'),
      );
    });

    test('fails when a provider is duplicated', () {
      final entries = <Sprint118ExpansionFeatureFlagEntry>[
        ...Sprint118ExpansionFeatureFlagContract.canonicalRecord.entries,
        _entry(providerId: 'stripe'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations,
        contains('expansion_feature_flags_provider_duplicate:stripe'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', flag: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(report.violations, contains('entry_blank_flag:stripe'));
    });

    test('fails when a reference state is not grounded by a witness', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', flag: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:flag:stripe'),
      );
    });

    test('records an open item when an output has no reference state', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(
              providerId: 'stripe',
              flag: Sprint118ExpansionFeatureFlagContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:flag:stripe'),
      );
    });

    test('fails when the record is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations,
        contains('expansion_feature_flags_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test('fails when the release state disagrees with the anchor', () {
      final report = _run(
        _record(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
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
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations,
        contains(
          'expansion_feature_flags_execution_authorized_on_delayed_path',
        ),
      );
    });

    test('fails when the release is not blocked on the delayed path', () {
      final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations,
        contains('expansion_feature_flags_release_not_blocked_on_delayed_path'),
      );
    });

    test('fails when a committed evidence source is unreadable', () {
      final report = _run(
        _record(),
        anchor: _anchor(readableSources: const <String>[]),
      );
      expect(report.state, Sprint118ExpansionFeatureFlagState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('required_source_unreadable:'),
        ),
        isTrue,
      );
    });

    test('the canonical sources cover every output', () {
      expect(
        Sprint118ExpansionFeatureFlagContract.canonicalSources.length,
        Sprint118ExpansionFeatureFlagContract.requiredOutputs.length,
      );
      for (final output
          in Sprint118ExpansionFeatureFlagContract.requiredOutputs) {
        expect(
          Sprint118ExpansionFeatureFlagContract.sourceFor(output),
          isNotEmpty,
          reason: '$output must have a committed source',
        );
      }
    });

    test('the loader reads the committed witnesses', () {
      final anchor = const Sprint118ExpansionFeatureFlagLoader().loadAnchor();
      expect(anchor, isNotNull);
      expect(anchor!.registeredProviders.length, 32);
      expect(anchor.charterVerdict, 'CHARTER_COMPLETE_LOCAL');
      expect(
        anchor.snapshotVerdict,
        'CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL',
      );
      expect(anchor.approvalDecision, 'delay');
      expect(anchor.releaseState, 'GA_DELAYED');
      expect(anchor.registryEvidenceExposed, 0);
      expect(anchor.registryEvidenceWithheld, 32);
      expect(anchor.snapshotLockLockedCount, 32);
      expect(anchor.readableSources.length, 13);
      expect(anchor.flagVocabulary, contains('beta.connectors.enabled'));
      expect(anchor.audienceVocabulary, contains('stage_internal'));
      expect(anchor.defaultVocabulary, contains('OFF'));
      expect(anchor.dependencyVocabulary, contains('none'));
      expect(anchor.healthVocabulary, contains('metric_error_rate'));
      expect(anchor.killSwitchVocabulary, contains('kill_openai'));
      expect(anchor.rollbackVocabulary, contains('rb_internal'));
      expect(anchor.supportVocabulary, contains('support-owner'));
    });

    test('the gate passes end to end against the committed witnesses', () {
      final report = const Sprint118ExpansionFeatureFlagGate().evaluate();
      expect(report.state, Sprint118ExpansionFeatureFlagState.pass);
      expect(report.verdict, 'EXPANSION_FEATURE_FLAGS_ROLLOUT_VERIFIED_LOCAL');
      expect(report.enabledCount, 0);
      expect(report.flippedCount, 0);
      expect(report.rolledOutCount, 0);
      expect(report.certifiedCount, 0);
      expect(report.releasedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });
  });
}
