import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_documentation_support_update.dart';

/// A single documentation & support record entry. Each test flips exactly the
/// one thing it is about, so a test that flips nothing proves the pass path
/// exists and every other test proves one way the gate refuses to take it.
Sprint118DocumentationSupportEntry _entry({
  String providerId = 'stripe',
  String availabilityMatrix =
      Sprint118DocumentationSupportContract.availabilityToken,
  String setupGuides = Sprint118DocumentationSupportContract.setupGuidesToken,
  String permissions = Sprint118DocumentationSupportContract.permissionsToken,
  String limitations = Sprint118DocumentationSupportContract.limitationsToken,
  String quotaNotes = Sprint118DocumentationSupportContract.quotaNotesToken,
  String usageCostNotes =
      Sprint118DocumentationSupportContract.usageCostNotesToken,
  String recovery = Sprint118DocumentationSupportContract.recoveryToken,
  String knownIssues = Sprint118DocumentationSupportContract.knownIssuesToken,
  bool documented = false,
  bool published = false,
  bool updated = false,
  bool verified = false,
  bool complete = false,
  bool supported = false,
  bool certified = false,
  bool released = false,
}) {
  return Sprint118DocumentationSupportEntry(
    providerId: providerId,
    availabilityMatrix: availabilityMatrix,
    setupGuides: setupGuides,
    permissions: permissions,
    limitations: limitations,
    quotaNotes: quotaNotes,
    usageCostNotes: usageCostNotes,
    recovery: recovery,
    knownIssues: knownIssues,
    documented: documented,
    published: published,
    updated: updated,
    verified: verified,
    complete: complete,
    supported: supported,
    certified: certified,
    released: released,
  );
}

Sprint118DocumentationSupportRecord _record({
  String releaseState =
      Sprint118DocumentationSupportContract.delayedReleaseState,
  List<Sprint118DocumentationSupportEntry>? entries,
}) {
  return Sprint118DocumentationSupportRecord(
    releaseState: releaseState,
    entries:
        entries ??
        Sprint118DocumentationSupportContract.canonicalRecord.entries,
  );
}

/// The canonical entries with exactly one provider replaced, so a test can flip
/// a single entry without rebuilding the whole record.
List<Sprint118DocumentationSupportEntry> _replacing(
  String providerId,
  Sprint118DocumentationSupportEntry replacement,
) {
  return <Sprint118DocumentationSupportEntry>[
    for (final e
        in Sprint118DocumentationSupportContract.canonicalRecord.entries)
      if (e.providerId == providerId) replacement else e,
  ];
}

Sprint118DocumentationSupportAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict =
      Sprint118DocumentationSupportContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint118DocumentationSupportContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict =
      Sprint118DocumentationSupportContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered =
      Sprint118DocumentationSupportContract.expectedProviderCount,
  String releaseState =
      Sprint118DocumentationSupportContract.delayedReleaseState,
  int registryExpectedCount =
      Sprint118DocumentationSupportContract.expectedProviderCount,
  int registryEvidenceProviderCount =
      Sprint118DocumentationSupportContract.expectedProviderCount,
  int registryEvidenceExposed = 0,
  int registryEvidenceWithheld =
      Sprint118DocumentationSupportContract.expectedProviderCount,
  int snapshotLockLockedCount =
      Sprint118DocumentationSupportContract.expectedProviderCount,
  String approvalDecision =
      Sprint118DocumentationSupportContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  List<String>? registeredProviders,
  List<String>? availabilityVocabulary,
  List<String>? setupGuidesVocabulary,
  List<String>? permissionsVocabulary,
  List<String>? limitationsVocabulary,
  List<String>? quotaNotesVocabulary,
  List<String>? usageCostNotesVocabulary,
  List<String>? recoveryVocabulary,
  List<String>? knownIssuesVocabulary,
  List<String>? readableSources,
}) {
  return Sprint118DocumentationSupportAnchor(
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
        Sprint118DocumentationSupportContract.canonicalProviders,
    availabilityVocabulary:
        availabilityVocabulary ?? const <String>['available', 'unavailable'],
    setupGuidesVocabulary:
        setupGuidesVocabulary ?? const <String>['user_guides', 'release_notes'],
    permissionsVocabulary:
        permissionsVocabulary ??
        const <String>['explicit_workspace_permission'],
    limitationsVocabulary:
        limitationsVocabulary ?? const <String>['known_limits', 'known_issues'],
    quotaNotesVocabulary:
        quotaNotesVocabulary ?? const <String>['quota_unavailable'],
    usageCostNotesVocabulary:
        usageCostNotesVocabulary ?? const <String>['provider_cost'],
    recoveryVocabulary: recoveryVocabulary ?? const <String>['restore_success'],
    knownIssuesVocabulary:
        knownIssuesVocabulary ?? const <String>['known_issues'],
    readableSources:
        readableSources ??
        Sprint118DocumentationSupportContract.witnessSources.toSet().toList(),
  );
}

Sprint118DocumentationSupportReport _run(
  Sprint118DocumentationSupportRecord record, {
  Sprint118DocumentationSupportAnchor? anchor,
}) {
  return const Sprint118DocumentationSupportGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.43 Documentation & Support Update', () {
    test(
      'the canonical field vocabulary is the eight objective dimensions',
      () {
        expect(Sprint118DocumentationSupportContract.requiredFields, <String>[
          'availability_matrix',
          'setup_guides',
          'permissions',
          'limitations',
          'quota_notes',
          'usage_cost_notes',
          'recovery',
          'known_issues',
        ]);
      },
    );

    test('the canonical outputs are the eight objective dimensions', () {
      expect(Sprint118DocumentationSupportContract.requiredOutputs, <String>[
        'availability_matrix',
        'setup_guides',
        'permissions',
        'limitations',
        'quota_notes',
        'usage_cost_notes',
        'recovery',
        'known_issues',
      ]);
      expect(
        Sprint118DocumentationSupportContract.requiredOutputs.length,
        Sprint118DocumentationSupportContract.expectedOutputCount,
      );
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary =
            Sprint118DocumentationSupportContract.stateVocabulary(
              <List<String>>[
                const <String>['available', 'user_guides'],
                const <String>['provider_cost', 'restore_success'],
              ],
            );
        expect(vocabulary, contains('available'));
        expect(vocabulary, contains('user_guides'));
        expect(vocabulary, contains('provider_cost'));
        expect(vocabulary, contains('restore_success'));
        expect(
          vocabulary,
          contains(Sprint118DocumentationSupportContract.noReferenceState),
        );
        expect(
          Sprint118DocumentationSupportContract.grounds(
            vocabulary,
            'available',
          ),
          isTrue,
        );
        expect(
          Sprint118DocumentationSupportContract.grounds(
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
        final vocabulary = <String>['explicit', 'workspace', 'permission'];
        expect(
          Sprint118DocumentationSupportContract.grounds(
            vocabulary,
            'explicit_workspace_permission',
          ),
          isTrue,
        );
        expect(
          Sprint118DocumentationSupportContract.grounds(
            vocabulary,
            'explicit_workspace_telepathy',
          ),
          isFalse,
        );
      },
    );

    test(
      'canonical record covers all 32 registered providers and claims nothing',
      () {
        final record = Sprint118DocumentationSupportContract.canonicalRecord;
        expect(record.entries.length, 32);
        expect(
          record.providerIds.toSet(),
          Sprint118DocumentationSupportContract.canonicalProviders.toSet(),
        );
        for (final entry in record.entries) {
          expect(entry.documented, isFalse);
          expect(entry.published, isFalse);
          expect(entry.updated, isFalse);
          expect(entry.verified, isFalse);
          expect(entry.complete, isFalse);
          expect(entry.supported, isFalse);
          expect(entry.certified, isFalse);
          expect(entry.released, isFalse);
          for (final field
              in Sprint118DocumentationSupportContract.requiredFields) {
            expect(
              (entry.requiredFields[field] ?? '').trim(),
              isNotEmpty,
              reason: '${entry.providerId}.$field must not be blank',
            );
          }
        }
      },
    );

    test('passes on the canonical record and claims no live documentation', () {
      final report = _run(_record());
      expect(report.state, Sprint118DocumentationSupportState.pass);
      expect(report.verdict, 'DOCUMENTATION_SUPPORT_UPDATE_VERIFIED_LOCAL');
      expect(report.recordVerified, isTrue);
      expect(report.declaredProviders.length, 32);
      expect(report.documentedProviders, isEmpty);
      expect(report.publishedProviders, isEmpty);
      expect(report.updatedProviders, isEmpty);
      expect(report.verifiedProviders, isEmpty);
      expect(report.certifiedProviders, isEmpty);
      expect(report.releasedProviders, isEmpty);
      expect(report.documentedCount, 0);
      expect(report.publishedCount, 0);
      expect(report.updatedCount, 0);
      expect(report.verifiedCount, 0);
      expect(report.completeCount, 0);
      expect(report.supportedCount, 0);
      expect(report.certifiedCount, 0);
      expect(report.releasedCount, 0);
      expect(report.expansionBudgetFrozen, isTrue);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118DocumentationSupportGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118DocumentationSupportState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_DOCUMENTATION_SUPPORT_EVIDENCE_UNREADABLE',
      );
      expect(report.recordVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_documentation_support_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is not complete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE_LOCAL'),
      );
      expect(report.state, Sprint118DocumentationSupportState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_DOCUMENTATION_SUPPORT_BLOCKED_UPSTREAM',
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
      expect(report.state, Sprint118DocumentationSupportState.blocked);
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
      expect(report.state, Sprint118DocumentationSupportState.blocked);
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
      expect(report.state, Sprint118DocumentationSupportState.blocked);
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
        expect(report.state, Sprint118DocumentationSupportState.blocked);
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
      expect(report.state, Sprint118DocumentationSupportState.blocked);
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
      expect(report.state, Sprint118DocumentationSupportState.blocked);
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
      expect(report.state, Sprint118DocumentationSupportState.blocked);
      expect(
        report.blockers.any(
          (b) => b.startsWith('registry_visibility_exposed_on_delayed_path:'),
        ),
        isTrue,
      );
    });

    test('fails when a provider claims documented documentation', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', documented: true),
          ),
        ),
      );
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains(
          'documentation_support_documented_claimed_on_delayed_path:stripe',
        ),
      );
      expect(report.documentedCount, 1);
    });

    test('fails when a provider claims published documentation', () {
      final report = _run(
        _record(
          entries: _replacing(
            'paypal',
            _entry(providerId: 'paypal', published: true),
          ),
        ),
      );
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains(
          'documentation_support_published_claimed_on_delayed_path:paypal',
        ),
      );
      expect(report.publishedCount, 1);
    });

    test('fails when a provider claims updated documentation', () {
      final report = _run(
        _record(
          entries: _replacing(
            'midtrans',
            _entry(providerId: 'midtrans', updated: true),
          ),
        ),
      );
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains(
          'documentation_support_updated_claimed_on_delayed_path:midtrans',
        ),
      );
      expect(report.updatedCount, 1);
    });

    test('fails when a provider claims verified documentation', () {
      final report = _run(
        _record(
          entries: _replacing(
            'saweria',
            _entry(providerId: 'saweria', verified: true),
          ),
        ),
      );
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains(
          'documentation_support_verified_claimed_on_delayed_path:saweria',
        ),
      );
      expect(report.verifiedCount, 1);
    });

    test('fails when a provider claims a complete documentation set', () {
      final report = _run(
        _record(
          entries: _replacing(
            'kofi',
            _entry(providerId: 'kofi', complete: true),
          ),
        ),
      );
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains('documentation_support_complete_claimed_on_delayed_path:kofi'),
      );
      expect(report.completeCount, 1);
    });

    test('fails when a provider claims an active support escalation', () {
      final report = _run(
        _record(
          entries: _replacing(
            'github',
            _entry(providerId: 'github', supported: true),
          ),
        ),
      );
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains(
          'documentation_support_supported_claimed_on_delayed_path:github',
        ),
      );
      expect(report.supportedCount, 1);
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
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains(
          'documentation_support_certified_claimed_on_delayed_path:openai',
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
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains('documentation_support_released_claimed:stripe'),
      );
      expect(report.releasedCount, 1);
    });

    test('fails when the expansion budget is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterMaxNewCertified: 1),
      );
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith(
            'documentation_support_expansion_budget_not_frozen:',
          ),
        ),
        isTrue,
      );
      expect(report.expansionBudgetFrozen, isFalse);
    });

    test('fails when the snapshot certifies a connector', () {
      final report = _run(_record(), anchor: _anchor(snapshotCertified: 1));
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains('documentation_support_snapshot_certified_nonzero:1'),
      );
    });

    test('fails when a registered provider is missing', () {
      final entries = <Sprint118DocumentationSupportEntry>[
        for (final e
            in Sprint118DocumentationSupportContract.canonicalRecord.entries)
          if (e.providerId != 'kofi') e,
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains('documentation_support_provider_missing:kofi'),
      );
    });

    test('fails when an unknown provider is invented', () {
      final entries = <Sprint118DocumentationSupportEntry>[
        ...Sprint118DocumentationSupportContract.canonicalRecord.entries,
        _entry(providerId: 'telepathy'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains('documentation_support_provider_unknown:telepathy'),
      );
    });

    test('fails when a provider is duplicated', () {
      final entries = <Sprint118DocumentationSupportEntry>[
        ...Sprint118DocumentationSupportContract.canonicalRecord.entries,
        _entry(providerId: 'stripe'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains('documentation_support_provider_duplicate:stripe'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', availabilityMatrix: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains('entry_blank_availability_matrix:stripe'),
      );
    });

    test('fails when a reference state is not grounded by a witness', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', availabilityMatrix: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:availability_matrix:stripe'),
      );
    });

    test('records an open item when an output has no reference state', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(
              providerId: 'stripe',
              availabilityMatrix:
                  Sprint118DocumentationSupportContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118DocumentationSupportState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:availability_matrix:stripe'),
      );
    });

    test('fails when the record is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains('documentation_support_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test('fails when the release state disagrees with the anchor', () {
      final report = _run(
        _record(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118DocumentationSupportState.fail);
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
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains('documentation_support_execution_authorized_on_delayed_path'),
      );
    });

    test('fails when the release is not blocked on the delayed path', () {
      final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations,
        contains('documentation_support_release_not_blocked_on_delayed_path'),
      );
    });

    test('fails when a committed evidence source is unreadable', () {
      final report = _run(
        _record(),
        anchor: _anchor(readableSources: const <String>[]),
      );
      expect(report.state, Sprint118DocumentationSupportState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('required_source_unreadable:'),
        ),
        isTrue,
      );
    });

    test('the canonical sources cover every output', () {
      expect(
        Sprint118DocumentationSupportContract.canonicalSources.length,
        Sprint118DocumentationSupportContract.requiredOutputs.length,
      );
      for (final output
          in Sprint118DocumentationSupportContract.requiredOutputs) {
        expect(
          Sprint118DocumentationSupportContract.sourceFor(output),
          isNotEmpty,
          reason: '$output must have a committed source',
        );
      }
    });

    test('the loader reads the committed witnesses', () {
      final anchor = const Sprint118DocumentationSupportLoader().loadAnchor();
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
      expect(anchor.availabilityVocabulary, contains('available'));
      expect(anchor.setupGuidesVocabulary, contains('user_guides'));
      expect(
        anchor.permissionsVocabulary,
        contains('explicit_workspace_permission'),
      );
      expect(anchor.limitationsVocabulary, contains('known_limits'));
      expect(anchor.quotaNotesVocabulary, contains('quota_unavailable'));
      expect(anchor.usageCostNotesVocabulary, contains('provider_cost'));
      expect(anchor.recoveryVocabulary, contains('restore_success'));
      expect(anchor.knownIssuesVocabulary, contains('known_issues'));
    });

    test('the gate passes end to end against the committed witnesses', () {
      final report = const Sprint118DocumentationSupportGate().evaluate();
      expect(report.state, Sprint118DocumentationSupportState.pass);
      expect(report.verdict, 'DOCUMENTATION_SUPPORT_UPDATE_VERIFIED_LOCAL');
      expect(report.documentedCount, 0);
      expect(report.publishedCount, 0);
      expect(report.updatedCount, 0);
      expect(report.verifiedCount, 0);
      expect(report.certifiedCount, 0);
      expect(report.releasedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });
  });
}
