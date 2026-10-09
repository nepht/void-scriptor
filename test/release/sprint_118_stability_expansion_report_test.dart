import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_stability_expansion_report.dart';

/// A single stability & expansion report section. Each test flips exactly the
/// one thing it is about, so a test that flips nothing proves the pass path
/// exists and every other test proves one way the gate refuses to take it.
Sprint118StabilityExpansionSection _section({
  String section = 'health',
  String referenceState = Sprint118StabilityExpansionContract.healthToken,
  String summary = 'no live health verified on the delayed path',
  List<String>? evidence,
  bool reported = false,
  bool published = false,
  bool verified = false,
  bool complete = false,
  bool live = false,
  bool certified = false,
  bool released = false,
}) {
  return Sprint118StabilityExpansionSection(
    section: section,
    referenceState: referenceState,
    summary: summary,
    evidence: evidence ?? <String>[Sprint118StabilityExpansionContract.sourceFor(section)],
    reported: reported,
    published: published,
    verified: verified,
    complete: complete,
    live: live,
    certified: certified,
    released: released,
  );
}

Sprint118StabilityExpansionRecord _record({
  String releaseState = Sprint118StabilityExpansionContract.delayedReleaseState,
  List<Sprint118StabilityExpansionSection>? sections,
}) {
  return Sprint118StabilityExpansionRecord(
    releaseState: releaseState,
    sections:
        sections ?? Sprint118StabilityExpansionContract.canonicalRecord.sections,
  );
}

/// The canonical sections with exactly one section replaced, so a test can flip
/// a single section without rebuilding the whole record.
List<Sprint118StabilityExpansionSection> _replacing(
  String section,
  Sprint118StabilityExpansionSection replacement,
) {
  return <Sprint118StabilityExpansionSection>[
    for (final e in Sprint118StabilityExpansionContract.canonicalRecord.sections)
      if (e.section == section) replacement else e,
  ];
}

Sprint118StabilityExpansionAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict =
      Sprint118StabilityExpansionContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint118StabilityExpansionContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict =
      Sprint118StabilityExpansionContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered =
      Sprint118StabilityExpansionContract.expectedProviderCount,
  String releaseState =
      Sprint118StabilityExpansionContract.delayedReleaseState,
  int registryExpectedCount =
      Sprint118StabilityExpansionContract.expectedProviderCount,
  int registryEvidenceProviderCount =
      Sprint118StabilityExpansionContract.expectedProviderCount,
  int registryEvidenceExposed = 0,
  int registryEvidenceWithheld =
      Sprint118StabilityExpansionContract.expectedProviderCount,
  int snapshotLockLockedCount =
      Sprint118StabilityExpansionContract.expectedProviderCount,
  String approvalDecision =
      Sprint118StabilityExpansionContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  List<String>? registeredProviders,
  List<String>? releaseStateVocabulary,
  List<String>? healthVocabulary,
  List<String>? incidentsVocabulary,
  List<String>? fixesVocabulary,
  List<String>? patchVocabulary,
  List<String>? certifiedSubsetVocabulary,
  List<String>? expansionVocabulary,
  List<String>? limitationsVocabulary,
  List<String>? risksVocabulary,
  List<String>? readableSources,
}) {
  return Sprint118StabilityExpansionAnchor(
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
        Sprint118StabilityExpansionContract.canonicalProviders,
    releaseStateVocabulary:
        releaseStateVocabulary ?? const <String>['GA_DELAYED'],
    healthVocabulary:
        healthVocabulary ??
        const <String>[
          'signal',
          'baseline',
          'threshold',
          'source',
          'window',
          'limitations',
        ],
    incidentsVocabulary:
        incidentsVocabulary ?? const <String>['P0', 'P1', 'P2', 'P3'],
    fixesVocabulary:
        fixesVocabulary ??
        const <String>[
          'auth',
          'quota',
          'sync',
          'ai',
          'billing',
          'ui',
          'accessibility',
          'compatibility',
        ],
    patchVocabulary:
        patchVocabulary ??
        const <String>[
          'EMERGENCY_FIX',
          'MAINTENANCE_FIX',
          'DOCUMENTATION_FIX',
          'DEFER',
          'FLAG_OFF',
          'ROLLBACK',
        ],
    certifiedSubsetVocabulary:
        certifiedSubsetVocabulary ??
        const <String>['UNVERIFIED', 'CERTIFIED', 'LIMITED', 'BLOCKED', 'EXPIRED'],
    expansionVocabulary:
        expansionVocabulary ??
        const <String>[
          'user_value',
          'evidence_strength',
          'feasibility',
          'risk',
          'maintenance',
          'support_cost',
          'strategic_fit',
        ],
    limitationsVocabulary:
        limitationsVocabulary ??
        const <String>[
          'live_provider_certification',
          'public_release_readiness',
          'hosted_ci_validation',
          'publication',
        ],
    risksVocabulary:
        risksVocabulary ??
        const <String>[
          'item',
          'impact',
          'evidence',
          'reason_deferred',
          'owner',
          'target',
          'trigger',
        ],
    readableSources:
        readableSources ??
        Sprint118StabilityExpansionContract.witnessSources.toSet().toList(),
  );
}

Sprint118StabilityExpansionReport _run(
  Sprint118StabilityExpansionRecord record, {
  Sprint118StabilityExpansionAnchor? anchor,
}) {
  return const Sprint118StabilityExpansionGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.44 Stability & Expansion Report', () {
    test('the canonical sections are the nine objective sections', () {
      expect(
        Sprint118StabilityExpansionContract.requiredSections,
        <String>[
          'release_state',
          'health',
          'incidents',
          'fixes',
          'patch',
          'certified_subset',
          'expansion',
          'limitations',
          'risks',
        ],
      );
    });

    test('the canonical outputs are the nine objective sections', () {
      expect(
        Sprint118StabilityExpansionContract.requiredOutputs,
        Sprint118StabilityExpansionContract.requiredSections,
      );
      expect(
        Sprint118StabilityExpansionContract.requiredOutputs.length,
        Sprint118StabilityExpansionContract.expectedSectionCount,
      );
    });

    test('the reference-state vocabulary is derived from committed witnesses', () {
      final vocabulary = Sprint118StabilityExpansionContract.stateVocabulary(
        <List<String>>[
          const <String>['GA_DELAYED'],
          const <String>['baseline', 'threshold'],
          const <String>['P0', 'P1'],
        ],
      );
      expect(vocabulary, contains('GA_DELAYED'));
      expect(vocabulary, contains('baseline'));
      expect(vocabulary, contains('P0'));
      expect(
        vocabulary,
        contains(Sprint118StabilityExpansionContract.noReferenceState),
      );
      expect(
        Sprint118StabilityExpansionContract.grounds(vocabulary, 'GA_DELAYED'),
        isTrue,
      );
      expect(
        Sprint118StabilityExpansionContract.grounds(vocabulary, 'telepathy'),
        isFalse,
      );
    });

    test(
      'a compound reference state is grounded only when every part is a witness value',
      () {
        final vocabulary = <String>['live', 'provider', 'certification'];
        expect(
          Sprint118StabilityExpansionContract.grounds(
            vocabulary,
            'live_provider_certification',
          ),
          isTrue,
        );
        expect(
          Sprint118StabilityExpansionContract.grounds(
            vocabulary,
            'live_provider_telepathy',
          ),
          isFalse,
        );
      },
    );

    test('canonical record covers all nine sections and claims nothing', () {
      final record = Sprint118StabilityExpansionContract.canonicalRecord;
      expect(record.sections.length, 9);
      expect(
        record.sectionNames.toSet(),
        Sprint118StabilityExpansionContract.requiredSections.toSet(),
      );
      expect(
        record.releaseState,
        Sprint118StabilityExpansionContract.delayedReleaseState,
      );
      for (final section in record.sections) {
        expect(section.reported, isFalse);
        expect(section.published, isFalse);
        expect(section.verified, isFalse);
        expect(section.complete, isFalse);
        expect(section.live, isFalse);
        expect(section.certified, isFalse);
        expect(section.released, isFalse);
        for (final field
            in Sprint118StabilityExpansionContract.requiredFieldsForSection) {
          expect(
            (section.requiredFields[field] ?? '').trim(),
            isNotEmpty,
            reason: '${section.section}.$field must not be blank',
          );
        }
      }
    });

    test('passes on the canonical record and claims no live report', () {
      final report = _run(_record());
      expect(report.state, Sprint118StabilityExpansionState.pass);
      expect(report.verdict, 'STABILITY_EXPANSION_REPORT_VERIFIED_LOCAL');
      expect(report.reportVerified, isTrue);
      expect(report.declaredSections.length, 9);
      expect(report.reportedSections, isEmpty);
      expect(report.publishedSections, isEmpty);
      expect(report.verifiedSections, isEmpty);
      expect(report.completeSections, isEmpty);
      expect(report.liveSections, isEmpty);
      expect(report.certifiedSections, isEmpty);
      expect(report.releasedSections, isEmpty);
      expect(report.reportedCount, 0);
      expect(report.publishedCount, 0);
      expect(report.verifiedCount, 0);
      expect(report.completeCount, 0);
      expect(report.liveCount, 0);
      expect(report.certifiedCount, 0);
      expect(report.releasedCount, 0);
      expect(report.expansionBudgetFrozen, isTrue);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118StabilityExpansionGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118StabilityExpansionState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_STABILITY_EXPANSION_EVIDENCE_UNREADABLE',
      );
      expect(report.reportVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_stability_expansion_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is not complete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE_LOCAL'),
      );
      expect(report.state, Sprint118StabilityExpansionState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_STABILITY_EXPANSION_BLOCKED_UPSTREAM',
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
      expect(report.state, Sprint118StabilityExpansionState.blocked);
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
      expect(report.state, Sprint118StabilityExpansionState.blocked);
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
      expect(report.state, Sprint118StabilityExpansionState.blocked);
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
        expect(report.state, Sprint118StabilityExpansionState.blocked);
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
      expect(report.state, Sprint118StabilityExpansionState.blocked);
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
      expect(report.state, Sprint118StabilityExpansionState.blocked);
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
      expect(report.state, Sprint118StabilityExpansionState.blocked);
      expect(
        report.blockers.any(
          (b) => b.startsWith('registry_visibility_exposed_on_delayed_path:'),
        ),
        isTrue,
      );
    });

    test('fails when a section claims a live report', () {
      final report = _run(
        _record(
          sections: _replacing(
            'health',
            _section(section: 'health', reported: true),
          ),
        ),
      );
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations,
        contains('stability_expansion_reported_claimed_on_delayed_path:health'),
      );
      expect(report.reportedCount, 1);
    });

    test('fails when a section claims a published report', () {
      final report = _run(
        _record(
          sections: _replacing(
            'incidents',
            _section(section: 'incidents', published: true),
          ),
        ),
      );
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations,
        contains(
          'stability_expansion_published_claimed_on_delayed_path:incidents',
        ),
      );
      expect(report.publishedCount, 1);
    });

    test('fails when a section claims a verified report', () {
      final report = _run(
        _record(
          sections: _replacing(
            'fixes',
            _section(section: 'fixes', verified: true),
          ),
        ),
      );
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations,
        contains('stability_expansion_verified_claimed_on_delayed_path:fixes'),
      );
      expect(report.verifiedCount, 1);
    });

    test('fails when a section claims a complete report', () {
      final report = _run(
        _record(
          sections: _replacing(
            'patch',
            _section(section: 'patch', complete: true),
          ),
        ),
      );
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations,
        contains('stability_expansion_complete_claimed_on_delayed_path:patch'),
      );
      expect(report.completeCount, 1);
    });

    test('fails when a section claims live observed state', () {
      final report = _run(
        _record(
          sections: _replacing(
            'expansion',
            _section(section: 'expansion', live: true),
          ),
        ),
      );
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations,
        contains('stability_expansion_live_claimed_on_delayed_path:expansion'),
      );
      expect(report.liveCount, 1);
    });

    test('fails when a section claims a certified connector', () {
      final report = _run(
        _record(
          sections: _replacing(
            'certified_subset',
            _section(section: 'certified_subset', certified: true),
          ),
        ),
      );
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations,
        contains(
          'stability_expansion_certified_claimed_on_delayed_path:certified_subset',
        ),
      );
      expect(report.certifiedCount, 1);
    });

    test('fails when a section claims a released connector', () {
      final report = _run(
        _record(
          sections: _replacing(
            'release_state',
            _section(section: 'release_state', released: true),
          ),
        ),
      );
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations,
        contains('stability_expansion_released_claimed:release_state'),
      );
      expect(report.releasedCount, 1);
    });

    test('fails when the expansion budget is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterMaxNewCertified: 1),
      );
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith(
            'stability_expansion_expansion_budget_not_frozen:',
          ),
        ),
        isTrue,
      );
      expect(report.expansionBudgetFrozen, isFalse);
    });

    test('fails when the snapshot certifies a connector', () {
      final report = _run(_record(), anchor: _anchor(snapshotCertified: 1));
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations,
        contains('stability_expansion_snapshot_certified_nonzero:1'),
      );
    });

    test('fails when a required section is missing', () {
      final sections = <Sprint118StabilityExpansionSection>[
        for (final e
            in Sprint118StabilityExpansionContract.canonicalRecord.sections)
          if (e.section != 'risks') e,
      ];
      final report = _run(_record(sections: sections));
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations,
        contains('stability_expansion_section_missing:risks'),
      );
    });

    test('fails when an unknown section is invented', () {
      final sections = <Sprint118StabilityExpansionSection>[
        ...Sprint118StabilityExpansionContract.canonicalRecord.sections,
        _section(section: 'telepathy', referenceState: 'telepathy'),
      ];
      final report = _run(_record(sections: sections));
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations,
        contains('stability_expansion_section_unknown:telepathy'),
      );
    });

    test('fails when a section is duplicated', () {
      final sections = <Sprint118StabilityExpansionSection>[
        ...Sprint118StabilityExpansionContract.canonicalRecord.sections,
        _section(section: 'health'),
      ];
      final report = _run(_record(sections: sections));
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations,
        contains('stability_expansion_section_duplicate:health'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _record(
          sections: _replacing(
            'health',
            _section(section: 'health', summary: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(report.violations, contains('entry_blank_summary:health'));
    });

    test('fails when a section evidence list is empty', () {
      final report = _run(
        _record(
          sections: _replacing(
            'health',
            _section(section: 'health', evidence: const <String>[]),
          ),
        ),
      );
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations,
        contains('stability_expansion_section_evidence_missing:health'),
      );
    });

    test('fails when a reference state is not grounded by a witness', () {
      final report = _run(
        _record(
          sections: _replacing(
            'health',
            _section(section: 'health', referenceState: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:health'),
      );
    });

    test('records an open item when a section has no reference state', () {
      final report = _run(
        _record(
          sections: _replacing(
            'health',
            _section(
              section: 'health',
              referenceState:
                  Sprint118StabilityExpansionContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118StabilityExpansionState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:health'),
      );
    });

    test('fails when the record is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations,
        contains('stability_expansion_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test('fails when the release state disagrees with the anchor', () {
      final report = _run(
        _record(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118StabilityExpansionState.fail);
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
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations,
        contains('stability_expansion_execution_authorized_on_delayed_path'),
      );
    });

    test('fails when the release is not blocked on the delayed path', () {
      final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations,
        contains('stability_expansion_release_not_blocked_on_delayed_path'),
      );
    });

    test('fails when a committed evidence source is unreadable', () {
      final report = _run(
        _record(),
        anchor: _anchor(readableSources: const <String>[]),
      );
      expect(report.state, Sprint118StabilityExpansionState.fail);
      expect(
        report.violations.any((v) => v.startsWith('required_source_unreadable:')),
        isTrue,
      );
    });

    test('the canonical sources cover every output', () {
      expect(
        Sprint118StabilityExpansionContract.canonicalSources.length,
        Sprint118StabilityExpansionContract.requiredOutputs.length,
      );
      for (final output
          in Sprint118StabilityExpansionContract.requiredOutputs) {
        expect(
          Sprint118StabilityExpansionContract.sourceFor(output),
          isNotEmpty,
          reason: '$output must have a committed source',
        );
      }
    });

    test('the loader reads the committed witnesses', () {
      final anchor = const Sprint118StabilityExpansionLoader().loadAnchor();
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
      expect(anchor.readableSources.length, 14);
      expect(anchor.releaseStateVocabulary, contains('GA_DELAYED'));
      expect(anchor.healthVocabulary, contains('baseline'));
      expect(anchor.incidentsVocabulary, contains('P0'));
      expect(anchor.fixesVocabulary, contains('auth'));
      expect(anchor.patchVocabulary, contains('DEFER'));
      expect(anchor.certifiedSubsetVocabulary, contains('UNVERIFIED'));
      expect(anchor.expansionVocabulary, contains('risk'));
      expect(
        anchor.limitationsVocabulary,
        contains('live_provider_certification'),
      );
      expect(anchor.risksVocabulary, contains('impact'));
    });

    test('the gate passes end to end against the committed witnesses', () {
      final report = const Sprint118StabilityExpansionGate().evaluate();
      expect(report.state, Sprint118StabilityExpansionState.pass);
      expect(report.verdict, 'STABILITY_EXPANSION_REPORT_VERIFIED_LOCAL');
      expect(report.reportedCount, 0);
      expect(report.publishedCount, 0);
      expect(report.verifiedCount, 0);
      expect(report.completeCount, 0);
      expect(report.liveCount, 0);
      expect(report.certifiedCount, 0);
      expect(report.releasedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });
  });
}
