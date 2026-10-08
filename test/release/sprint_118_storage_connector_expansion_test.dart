import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_storage_connector_expansion.dart';

/// A single storage connector expansion entry. Each test flips exactly the one
/// thing it is about, so a test that flips nothing proves the pass path exists
/// and every other test proves one way the gate refuses to take it.
Sprint118StorageConnectorEntry _entry({
  String providerId = 'google_drive',
  String selectedProvider =
      Sprint118StorageConnectorContract.selectedProviderToken,
  String storageContract =
      Sprint118StorageConnectorContract.storageContractToken,
  String quota = Sprint118StorageConnectorContract.quotaToken,
  String delta = Sprint118StorageConnectorContract.deltaToken,
  String conflict = Sprint118StorageConnectorContract.conflictToken,
  String backup = Sprint118StorageConnectorContract.backupToken,
  String restore = Sprint118StorageConnectorContract.restoreToken,
  bool certified = false,
  bool selected = false,
  bool quotaVerified = false,
  bool deltaVerified = false,
  bool conflictResolved = false,
  bool backupVerified = false,
  bool restoreVerified = false,
  bool released = false,
}) {
  return Sprint118StorageConnectorEntry(
    providerId: providerId,
    selectedProvider: selectedProvider,
    storageContract: storageContract,
    quota: quota,
    delta: delta,
    conflict: conflict,
    backup: backup,
    restore: restore,
    certified: certified,
    selected: selected,
    quotaVerified: quotaVerified,
    deltaVerified: deltaVerified,
    conflictResolved: conflictResolved,
    backupVerified: backupVerified,
    restoreVerified: restoreVerified,
    released: released,
  );
}

Sprint118StorageConnectorRecord _record({
  String releaseState = Sprint118StorageConnectorContract.delayedReleaseState,
  List<Sprint118StorageConnectorEntry>? entries,
}) {
  return Sprint118StorageConnectorRecord(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118StorageConnectorContract.canonicalRecord.entries,
  );
}

/// The canonical entries with exactly one provider replaced, so a test can flip
/// a single entry without rebuilding the whole record.
List<Sprint118StorageConnectorEntry> _replacing(
  String providerId,
  Sprint118StorageConnectorEntry replacement,
) {
  return <Sprint118StorageConnectorEntry>[
    for (final e in Sprint118StorageConnectorContract.canonicalRecord.entries)
      if (e.providerId == providerId) replacement else e,
  ];
}

Sprint118StorageConnectorAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict =
      Sprint118StorageConnectorContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint118StorageConnectorContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict =
      Sprint118StorageConnectorContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered =
      Sprint118StorageConnectorContract.expectedProviderCount,
  String releaseState = Sprint118StorageConnectorContract.delayedReleaseState,
  int registryExpectedCount =
      Sprint118StorageConnectorContract.expectedProviderCount,
  String approvalDecision =
      Sprint118StorageConnectorContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  String storageQuotaStatus =
      Sprint118StorageConnectorContract.requiredStorageQuotaStatus,
  String storageQuotaVerdict =
      Sprint118StorageConnectorContract.requiredStorageQuotaVerdict,
  List<String>? registeredProviders,
  List<String>? selectedProviderVocabulary,
  List<String>? storageContractVocabulary,
  List<String>? quotaVocabulary,
  List<String>? deltaVocabulary,
  List<String>? conflictVocabulary,
  List<String>? backupVocabulary,
  List<String>? restoreVocabulary,
  List<String>? readableSources,
}) {
  return Sprint118StorageConnectorAnchor(
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
    storageQuotaStatus: storageQuotaStatus,
    storageQuotaVerdict: storageQuotaVerdict,
    registeredProviders:
        registeredProviders ??
        Sprint118StorageConnectorContract.canonicalProviders,
    selectedProviderVocabulary:
        selectedProviderVocabulary ??
        const <String>[
          'display_units',
          'freshness',
          'local_separation',
          'partial_total',
          'raw_bytes',
          'unavailable',
          'provider_api_values',
        ],
    storageContractVocabulary:
        storageContractVocabulary ??
        const <String>[
          'account_id',
          'provider_id',
          'capabilities',
          'root_scope',
          'quota_support',
          'sync_support',
          'backup_support',
          'freshness',
        ],
    quotaVocabulary:
        quotaVocabulary ??
        const <String>[
          'raw_bytes',
          'provider_timestamp',
          'unit_metadata',
          'quota_unavailable',
          'stale_state',
          'refresh',
        ],
    deltaVocabulary:
        deltaVocabulary ??
        const <String>[
          'delta_sync',
          'pause_resume',
          'retry',
          'progress',
          'bandwidth_control',
          'explicit_transfer_consent',
        ],
    conflictVocabulary:
        conflictVocabulary ??
        const <String>[
          'conflict_detection',
          'version_preview',
          'keep_local',
          'keep_remote',
          'merge_when_supported',
          'history',
          'backup_before_resolution',
        ],
    backupVocabulary:
        backupVocabulary ??
        const <String>[
          'schedule',
          'retention',
          'encryption',
          'destination',
          'workspace_boundary',
          'verification',
          'restore_test',
        ],
    restoreVocabulary:
        restoreVocabulary ??
        const <String>[
          'schedule',
          'retention',
          'encryption',
          'destination',
          'workspace_boundary',
          'verification',
          'restore_test',
        ],
    readableSources:
        readableSources ??
        Sprint118StorageConnectorContract.witnessSources.toSet().toList(),
  );
}

Sprint118StorageConnectorReport _run(
  Sprint118StorageConnectorRecord record, {
  Sprint118StorageConnectorAnchor? anchor,
}) {
  return const Sprint118StorageConnectorGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.34 Storage Connector Expansion', () {
    test('the canonical field vocabulary is the eight objective fields', () {
      expect(Sprint118StorageConnectorContract.requiredFields, <String>[
        'provider_id',
        'selected_provider',
        'storage_contract',
        'quota',
        'delta',
        'conflict',
        'backup',
        'restore',
      ]);
    });

    test('the canonical outputs are the seven objective items', () {
      expect(Sprint118StorageConnectorContract.requiredOutputs, <String>[
        'selected_provider',
        'storage_contract',
        'quota',
        'delta',
        'conflict',
        'backup',
        'restore',
      ]);
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary = Sprint118StorageConnectorContract.stateVocabulary(
          <List<String>>[
            const <String>['raw_bytes', 'delta_sync'],
            const <String>['conflict_detection', 'retention'],
          ],
        );
        expect(vocabulary, contains('raw_bytes'));
        expect(vocabulary, contains('delta_sync'));
        expect(vocabulary, contains('conflict_detection'));
        expect(
          vocabulary,
          contains(Sprint118StorageConnectorContract.noReferenceState),
        );
        expect(
          Sprint118StorageConnectorContract.grounds(vocabulary, 'raw_bytes'),
          isTrue,
        );
        expect(
          Sprint118StorageConnectorContract.grounds(vocabulary, 'telepathy'),
          isFalse,
        );
      },
    );

    test(
      'canonical record covers all 32 registered providers and claims nothing',
      () {
        final record = Sprint118StorageConnectorContract.canonicalRecord;
        expect(record.entries.length, 32);
        expect(
          record.providerIds.toSet(),
          Sprint118StorageConnectorContract.canonicalProviders.toSet(),
        );
        for (final entry in record.entries) {
          expect(entry.certified, isFalse);
          expect(entry.selected, isFalse);
          expect(entry.quotaVerified, isFalse);
          expect(entry.deltaVerified, isFalse);
          expect(entry.conflictResolved, isFalse);
          expect(entry.backupVerified, isFalse);
          expect(entry.restoreVerified, isFalse);
          expect(entry.released, isFalse);
          for (final field
              in Sprint118StorageConnectorContract.requiredFields) {
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
      expect(report.state, Sprint118StorageConnectorState.pass);
      expect(report.verdict, 'STORAGE_CONNECTOR_EXPANSION_VERIFIED_LOCAL');
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
      final report = const Sprint118StorageConnectorGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118StorageConnectorState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_STORAGE_CONNECTOR_EXPANSION_EVIDENCE_UNREADABLE',
      );
      expect(report.certificationVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_storage_connector_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is not complete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE_LOCAL'),
      );
      expect(report.state, Sprint118StorageConnectorState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_STORAGE_CONNECTOR_EXPANSION_BLOCKED_UPSTREAM',
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
      expect(report.state, Sprint118StorageConnectorState.blocked);
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
      expect(report.state, Sprint118StorageConnectorState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('approval_gate_not_delay:')),
        isTrue,
      );
    });

    test(
      'blocks when the committed storage quota validation is not a pass',
      () {
        final report = _run(
          _record(),
          anchor: _anchor(storageQuotaVerdict: 'CLOUD_STORAGE_QUOTA_DRIFT'),
        );
        expect(report.state, Sprint118StorageConnectorState.blocked);
        expect(
          report.blockers.any(
            (b) => b.startsWith('storage_quota_not_validated:'),
          ),
          isTrue,
        );
      },
    );

    test('blocks when the registered provider set does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(registryExpectedCount: 31),
      );
      expect(report.state, Sprint118StorageConnectorState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('registry_not_reconciled:')),
        isTrue,
      );
    });

    test('fails when a provider claims a certified connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'google_drive',
            _entry(providerId: 'google_drive', certified: true),
          ),
        ),
      );
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations,
        contains(
          'storage_connector_certified_claimed_on_delayed_path:google_drive',
        ),
      );
      expect(report.certifiedCount, 1);
    });

    test('fails when a provider claims it was selected', () {
      final report = _run(
        _record(
          entries: _replacing(
            'dropbox',
            _entry(providerId: 'dropbox', selected: true),
          ),
        ),
      );
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations,
        contains('storage_connector_selected_claimed_on_delayed_path:dropbox'),
      );
      expect(report.selectedCount, 1);
    });

    test('fails when a quota is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'onedrive',
            _entry(providerId: 'onedrive', quotaVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations,
        contains('storage_connector_quota_verified_on_delayed_path:onedrive'),
      );
    });

    test('fails when a delta is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'mega',
            _entry(providerId: 'mega', deltaVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations,
        contains('storage_connector_delta_verified_on_delayed_path:mega'),
      );
    });

    test('fails when a conflict is claimed resolved', () {
      final report = _run(
        _record(
          entries: _replacing(
            'local_storage',
            _entry(providerId: 'local_storage', conflictResolved: true),
          ),
        ),
      );
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations,
        contains(
          'storage_connector_conflict_resolved_on_delayed_path:local_storage',
        ),
      );
    });

    test('fails when a backup is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'google',
            _entry(providerId: 'google', backupVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations,
        contains('storage_connector_backup_verified_on_delayed_path:google'),
      );
    });

    test('fails when a restore is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'microsoft',
            _entry(providerId: 'microsoft', restoreVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations,
        contains(
          'storage_connector_restore_verified_on_delayed_path:microsoft',
        ),
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
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations,
        contains('storage_connector_provider_released_claimed:stripe'),
      );
    });

    test('fails when the expansion budget is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterMaxNewCertified: 1),
      );
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('storage_connector_expansion_budget_not_frozen:'),
        ),
        isTrue,
      );
      expect(report.expansionBudgetFrozen, isFalse);
    });

    test('fails when a registered provider is missing', () {
      final entries = <Sprint118StorageConnectorEntry>[
        for (final e
            in Sprint118StorageConnectorContract.canonicalRecord.entries)
          if (e.providerId != 'kofi') e,
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations,
        contains('storage_connector_provider_missing:kofi'),
      );
    });

    test('fails when an unknown provider is invented', () {
      final entries = <Sprint118StorageConnectorEntry>[
        ...Sprint118StorageConnectorContract.canonicalRecord.entries,
        _entry(providerId: 'telepathy'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations,
        contains('storage_connector_provider_unknown:telepathy'),
      );
    });

    test('fails when a provider is duplicated', () {
      final entries = <Sprint118StorageConnectorEntry>[
        ...Sprint118StorageConnectorContract.canonicalRecord.entries,
        _entry(providerId: 'google_drive'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations,
        contains('storage_connector_provider_duplicate:google_drive'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _record(
          entries: _replacing(
            'google_drive',
            _entry(providerId: 'google_drive', storageContract: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations,
        contains('entry_blank_storage_contract:google_drive'),
      );
    });

    test('fails when a reference state is not grounded by a witness', () {
      final report = _run(
        _record(
          entries: _replacing(
            'google_drive',
            _entry(providerId: 'google_drive', delta: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:delta:google_drive'),
      );
    });

    test('records an open item when a requirement has no reference state', () {
      final report = _run(
        _record(
          entries: _replacing(
            'google_drive',
            _entry(
              providerId: 'google_drive',
              restore: Sprint118StorageConnectorContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118StorageConnectorState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:restore:google_drive'),
      );
    });

    test('fails when the record is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations,
        contains('storage_connector_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test('fails when the release state disagrees with the anchor', () {
      final report = _run(
        _record(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118StorageConnectorState.fail);
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
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations,
        contains('storage_connector_execution_authorized_on_delayed_path'),
      );
    });

    test('fails when the release is not blocked on the delayed path', () {
      final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations,
        contains('storage_connector_release_not_blocked_on_delayed_path'),
      );
    });

    test('fails when a committed evidence source is unreadable', () {
      final report = _run(
        _record(),
        anchor: _anchor(readableSources: const <String>[]),
      );
      expect(report.state, Sprint118StorageConnectorState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('required_source_unreadable:'),
        ),
        isTrue,
      );
    });

    test('the canonical sources cover every requirement', () {
      expect(
        Sprint118StorageConnectorContract.canonicalSources.length,
        Sprint118StorageConnectorContract.requiredOutputs.length,
      );
      for (final output in Sprint118StorageConnectorContract.requiredOutputs) {
        expect(
          Sprint118StorageConnectorContract.sourceFor(output),
          isNotEmpty,
          reason: '$output must have a committed source',
        );
      }
    });

    test('the loader reads the committed witnesses', () {
      final anchor = const Sprint118StorageConnectorLoader().loadAnchor();
      expect(anchor, isNotNull);
      expect(anchor!.registeredProviders.length, 32);
      expect(anchor.charterVerdict, 'CHARTER_COMPLETE_LOCAL');
      expect(
        anchor.snapshotVerdict,
        'CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL',
      );
      expect(anchor.approvalDecision, 'delay');
      expect(anchor.storageQuotaVerdict, 'CLOUD_STORAGE_QUOTA_VALIDATED_LOCAL');
      expect(anchor.readableSources.length, 11);
      expect(
        anchor.selectedProviderVocabulary,
        contains('provider_api_values'),
      );
      expect(anchor.storageContractVocabulary, contains('capabilities'));
      expect(anchor.quotaVocabulary, contains('raw_bytes'));
      expect(anchor.deltaVocabulary, contains('delta_sync'));
      expect(anchor.conflictVocabulary, contains('conflict_detection'));
      expect(anchor.backupVocabulary, contains('retention'));
      expect(anchor.restoreVocabulary, contains('restore_test'));
    });

    test('the gate passes end to end against the committed witnesses', () {
      final report = const Sprint118StorageConnectorGate().evaluate();
      expect(report.state, Sprint118StorageConnectorState.pass);
      expect(report.verdict, 'STORAGE_CONNECTOR_EXPANSION_VERIFIED_LOCAL');
      expect(report.certifiedCount, 0);
      expect(report.selectedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });
  });
}
