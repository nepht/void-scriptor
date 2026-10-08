import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_versioned_connector_certification.dart';

/// A single versioned connector certification entry. Each test flips exactly
/// the one thing it is about, so a test that flips nothing proves the pass path
/// exists and every other test proves one way the gate refuses to take it.
Sprint118VersionedConnectorEntry _entry({
  String providerId = 'stripe',
  String connectorVersion =
      Sprint118VersionedCertificationContract.connectorVersionToken,
  String status = Sprint118VersionedCertificationContract.statusToken,
  String evidence = Sprint118VersionedCertificationContract.evidenceToken,
  String limitations = Sprint118VersionedCertificationContract.limitationsToken,
  String reviewer = Sprint118VersionedCertificationContract.reviewerToken,
  String recheckDate = Sprint118VersionedCertificationContract.recheckDateToken,
  String visibility = Sprint118VersionedCertificationContract.visibilityToken,
  bool certified = false,
  bool verified = false,
  bool reviewed = false,
  bool exposed = false,
  bool released = false,
  bool published = false,
}) {
  return Sprint118VersionedConnectorEntry(
    providerId: providerId,
    connectorVersion: connectorVersion,
    status: status,
    evidence: evidence,
    limitations: limitations,
    reviewer: reviewer,
    recheckDate: recheckDate,
    visibility: visibility,
    certified: certified,
    verified: verified,
    reviewed: reviewed,
    exposed: exposed,
    released: released,
    published: published,
  );
}

Sprint118VersionedCertificationRecord _record({
  String releaseState =
      Sprint118VersionedCertificationContract.delayedReleaseState,
  List<Sprint118VersionedConnectorEntry>? entries,
}) {
  return Sprint118VersionedCertificationRecord(
    releaseState: releaseState,
    entries:
        entries ??
        Sprint118VersionedCertificationContract.canonicalRecord.entries,
  );
}

/// The canonical entries with exactly one provider replaced, so a test can flip
/// a single entry without rebuilding the whole record.
List<Sprint118VersionedConnectorEntry> _replacing(
  String providerId,
  Sprint118VersionedConnectorEntry replacement,
) {
  return <Sprint118VersionedConnectorEntry>[
    for (final e
        in Sprint118VersionedCertificationContract.canonicalRecord.entries)
      if (e.providerId == providerId) replacement else e,
  ];
}

Sprint118VersionedCertificationAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict =
      Sprint118VersionedCertificationContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint118VersionedCertificationContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict =
      Sprint118VersionedCertificationContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered =
      Sprint118VersionedCertificationContract.expectedProviderCount,
  String releaseState =
      Sprint118VersionedCertificationContract.delayedReleaseState,
  int registryExpectedCount =
      Sprint118VersionedCertificationContract.expectedProviderCount,
  int registryEvidenceProviderCount =
      Sprint118VersionedCertificationContract.expectedProviderCount,
  int registryEvidenceExposed = 0,
  int registryEvidenceWithheld =
      Sprint118VersionedCertificationContract.expectedProviderCount,
  int snapshotLockLockedCount =
      Sprint118VersionedCertificationContract.expectedProviderCount,
  String approvalDecision =
      Sprint118VersionedCertificationContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  List<String>? registeredProviders,
  List<String>? connectorVersionVocabulary,
  List<String>? statusVocabulary,
  List<String>? evidenceVocabulary,
  List<String>? limitationsVocabulary,
  List<String>? reviewerVocabulary,
  List<String>? recheckDateVocabulary,
  List<String>? visibilityVocabulary,
  List<String>? readableSources,
}) {
  return Sprint118VersionedCertificationAnchor(
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
        Sprint118VersionedCertificationContract.canonicalProviders,
    connectorVersionVocabulary:
        connectorVersionVocabulary ?? const <String>['manifest-v1'],
    statusVocabulary:
        statusVocabulary ??
        const <String>[
          'UNVERIFIED',
          'CERTIFIED',
          'LIMITED',
          'BLOCKED',
          'EXPIRED',
        ],
    evidenceVocabulary:
        evidenceVocabulary ??
        const <String>[
          'provider_id',
          'connector_version',
          'status',
          'evidence',
          'limitations',
          'visibility',
          'recheck_date',
        ],
    limitationsVocabulary:
        limitationsVocabulary ??
        const <String>[
          'live_provider_certification',
          'public_release_readiness',
          'hosted_ci_validation',
          'publication',
        ],
    reviewerVocabulary:
        reviewerVocabulary ?? const <String>['automation-governance'],
    recheckDateVocabulary:
        recheckDateVocabulary ?? const <String>['2027-03-27'],
    visibilityVocabulary:
        visibilityVocabulary ?? const <String>['EXPOSED', 'WITHHELD'],
    readableSources:
        readableSources ??
        Sprint118VersionedCertificationContract.witnessSources.toSet().toList(),
  );
}

Sprint118VersionedCertificationReport _run(
  Sprint118VersionedCertificationRecord record, {
  Sprint118VersionedCertificationAnchor? anchor,
}) {
  return const Sprint118VersionedCertificationGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.39 Versioned Connector Certification', () {
    test('the canonical field vocabulary is the eight objective fields', () {
      expect(Sprint118VersionedCertificationContract.requiredFields, <String>[
        'provider_id',
        'connector_version',
        'status',
        'evidence',
        'limitations',
        'reviewer',
        'recheck_date',
        'visibility',
      ]);
    });

    test('the canonical outputs are the seven objective items', () {
      expect(Sprint118VersionedCertificationContract.requiredOutputs, <String>[
        'connector_version',
        'status',
        'evidence',
        'limitations',
        'reviewer',
        'recheck_date',
        'visibility',
      ]);
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary =
            Sprint118VersionedCertificationContract.stateVocabulary(
              <List<String>>[
                const <String>['manifest-v1'],
                const <String>['UNVERIFIED', 'CERTIFIED'],
              ],
            );
        expect(vocabulary, contains('manifest-v1'));
        expect(vocabulary, contains('UNVERIFIED'));
        expect(vocabulary, contains('CERTIFIED'));
        expect(
          vocabulary,
          contains(Sprint118VersionedCertificationContract.noReferenceState),
        );
        expect(
          Sprint118VersionedCertificationContract.grounds(
            vocabulary,
            'manifest-v1',
          ),
          isTrue,
        );
        expect(
          Sprint118VersionedCertificationContract.grounds(
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
        final vocabulary = <String>[
          'live_provider_certification',
          'public_release_readiness',
        ];
        expect(
          Sprint118VersionedCertificationContract.grounds(
            vocabulary,
            'live_provider_certification',
          ),
          isTrue,
        );
        expect(
          Sprint118VersionedCertificationContract.grounds(
            vocabulary,
            'live_telepathy',
          ),
          isFalse,
        );
      },
    );

    test(
      'canonical record covers all 32 registered providers and claims nothing',
      () {
        final record = Sprint118VersionedCertificationContract.canonicalRecord;
        expect(record.entries.length, 32);
        expect(
          record.providerIds.toSet(),
          Sprint118VersionedCertificationContract.canonicalProviders.toSet(),
        );
        for (final entry in record.entries) {
          expect(entry.certified, isFalse);
          expect(entry.verified, isFalse);
          expect(entry.reviewed, isFalse);
          expect(entry.exposed, isFalse);
          expect(entry.released, isFalse);
          expect(entry.published, isFalse);
          for (final field
              in Sprint118VersionedCertificationContract.requiredFields) {
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
      expect(report.state, Sprint118VersionedCertificationState.pass);
      expect(
        report.verdict,
        'VERSIONED_CONNECTOR_CERTIFICATION_VERIFIED_LOCAL',
      );
      expect(report.certificationVerified, isTrue);
      expect(report.declaredProviders.length, 32);
      expect(report.certifiedProviders, isEmpty);
      expect(report.exposedProviders, isEmpty);
      expect(report.releasedProviders, isEmpty);
      expect(report.expansionBudgetFrozen, isTrue);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118VersionedCertificationGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118VersionedCertificationState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_VERSIONED_CONNECTOR_CERTIFICATION_EVIDENCE_UNREADABLE',
      );
      expect(report.certificationVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_versioned_certification_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is not complete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE_LOCAL'),
      );
      expect(report.state, Sprint118VersionedCertificationState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_VERSIONED_CONNECTOR_CERTIFICATION_BLOCKED_UPSTREAM',
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
      expect(report.state, Sprint118VersionedCertificationState.blocked);
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
      expect(report.state, Sprint118VersionedCertificationState.blocked);
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
      expect(report.state, Sprint118VersionedCertificationState.blocked);
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
        expect(report.state, Sprint118VersionedCertificationState.blocked);
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
      expect(report.state, Sprint118VersionedCertificationState.blocked);
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
      expect(report.state, Sprint118VersionedCertificationState.blocked);
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
      expect(report.state, Sprint118VersionedCertificationState.blocked);
      expect(
        report.blockers.any(
          (b) => b.startsWith('registry_visibility_exposed_on_delayed_path:'),
        ),
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
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations,
        contains(
          'versioned_connector_certified_claimed_on_delayed_path:stripe',
        ),
      );
      expect(report.certifiedCount, 1);
    });

    test('fails when evidence is claimed verified live', () {
      final report = _run(
        _record(
          entries: _replacing(
            'paypal',
            _entry(providerId: 'paypal', verified: true),
          ),
        ),
      );
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations,
        contains(
          'versioned_connector_evidence_verified_on_delayed_path:paypal',
        ),
      );
    });

    test('fails when a live review is claimed', () {
      final report = _run(
        _record(
          entries: _replacing(
            'midtrans',
            _entry(providerId: 'midtrans', reviewed: true),
          ),
        ),
      );
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations,
        contains(
          'versioned_connector_reviewed_claimed_on_delayed_path:midtrans',
        ),
      );
    });

    test('fails when a provider is claimed exposed', () {
      final report = _run(
        _record(
          entries: _replacing(
            'saweria',
            _entry(providerId: 'saweria', exposed: true),
          ),
        ),
      );
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations,
        contains('versioned_connector_exposed_claimed_on_delayed_path:saweria'),
      );
      expect(report.exposedCount, 1);
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
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations,
        contains('versioned_connector_released_claimed:kofi'),
      );
      expect(report.releasedCount, 1);
    });

    test('fails when a provider is claimed published', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', published: true),
          ),
        ),
      );
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations,
        contains('versioned_connector_published_claimed:stripe'),
      );
    });

    test('fails when a status names a released connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', status: 'CERTIFIED'),
          ),
        ),
      );
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations,
        contains(
          'versioned_connector_status_certified_on_delayed_path:stripe:CERTIFIED',
        ),
      );
    });

    test('fails when a visibility exposes a connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', visibility: 'EXPOSED'),
          ),
        ),
      );
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations,
        contains(
          'versioned_connector_visibility_exposed_on_delayed_path:stripe',
        ),
      );
    });

    test('fails when the expansion budget is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterMaxNewCertified: 1),
      );
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations.any(
          (v) =>
              v.startsWith('versioned_connector_expansion_budget_not_frozen:'),
        ),
        isTrue,
      );
      expect(report.expansionBudgetFrozen, isFalse);
    });

    test('fails when the snapshot certifies a connector', () {
      final report = _run(_record(), anchor: _anchor(snapshotCertified: 1));
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations,
        contains('versioned_connector_snapshot_certified_nonzero:1'),
      );
    });

    test('fails when a registered provider is missing', () {
      final entries = <Sprint118VersionedConnectorEntry>[
        for (final e
            in Sprint118VersionedCertificationContract.canonicalRecord.entries)
          if (e.providerId != 'kofi') e,
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations,
        contains('versioned_connector_provider_missing:kofi'),
      );
    });

    test('fails when an unknown provider is invented', () {
      final entries = <Sprint118VersionedConnectorEntry>[
        ...Sprint118VersionedCertificationContract.canonicalRecord.entries,
        _entry(providerId: 'telepathy'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations,
        contains('versioned_connector_provider_unknown:telepathy'),
      );
    });

    test('fails when a provider is duplicated', () {
      final entries = <Sprint118VersionedConnectorEntry>[
        ...Sprint118VersionedCertificationContract.canonicalRecord.entries,
        _entry(providerId: 'stripe'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations,
        contains('versioned_connector_provider_duplicate:stripe'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', evidence: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(report.violations, contains('entry_blank_evidence:stripe'));
    });

    test('fails when a reference state is not grounded by a witness', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', evidence: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:evidence:stripe'),
      );
    });

    test('records an open item when a requirement has no reference state', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(
              providerId: 'stripe',
              evidence:
                  Sprint118VersionedCertificationContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118VersionedCertificationState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:evidence:stripe'),
      );
    });

    test('fails when the record is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations,
        contains('versioned_connector_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test('fails when the release state disagrees with the anchor', () {
      final report = _run(
        _record(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118VersionedCertificationState.fail);
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
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations,
        contains('versioned_connector_execution_authorized_on_delayed_path'),
      );
    });

    test('fails when the release is not blocked on the delayed path', () {
      final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations,
        contains('versioned_connector_release_not_blocked_on_delayed_path'),
      );
    });

    test('fails when a committed evidence source is unreadable', () {
      final report = _run(
        _record(),
        anchor: _anchor(readableSources: const <String>[]),
      );
      expect(report.state, Sprint118VersionedCertificationState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('required_source_unreadable:'),
        ),
        isTrue,
      );
    });

    test('the canonical sources cover every requirement', () {
      expect(
        Sprint118VersionedCertificationContract.canonicalSources.length,
        Sprint118VersionedCertificationContract.requiredOutputs.length,
      );
      for (final output
          in Sprint118VersionedCertificationContract.requiredOutputs) {
        expect(
          Sprint118VersionedCertificationContract.sourceFor(output),
          isNotEmpty,
          reason: '$output must have a committed source',
        );
      }
    });

    test('the loader reads the committed witnesses', () {
      final anchor = const Sprint118VersionedCertificationLoader().loadAnchor();
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
      expect(anchor.readableSources.length, 8);
      expect(anchor.connectorVersionVocabulary, contains('manifest-v1'));
      expect(anchor.statusVocabulary, contains('UNVERIFIED'));
      expect(anchor.evidenceVocabulary, contains('evidence'));
      expect(
        anchor.limitationsVocabulary,
        contains('live_provider_certification'),
      );
      expect(anchor.reviewerVocabulary, contains('automation-governance'));
      expect(anchor.recheckDateVocabulary, contains('2027-03-27'));
      expect(anchor.visibilityVocabulary, contains('WITHHELD'));
    });

    test('the gate passes end to end against the committed witnesses', () {
      final report = const Sprint118VersionedCertificationGate().evaluate();
      expect(report.state, Sprint118VersionedCertificationState.pass);
      expect(
        report.verdict,
        'VERSIONED_CONNECTOR_CERTIFICATION_VERIFIED_LOCAL',
      );
      expect(report.certifiedCount, 0);
      expect(report.exposedCount, 0);
      expect(report.releasedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });
  });
}
