import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_expansion_acceptance_gate.dart';

/// A single acceptance record entry. Each test flips exactly the one thing it is
/// about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it.
Sprint118ExpansionAcceptanceEntry _entry({
  String providerId = 'stripe',
  String certification =
      Sprint118ExpansionAcceptanceContract.certificationToken,
  String contractTests =
      Sprint118ExpansionAcceptanceContract.contractTestsToken,
  String security = Sprint118ExpansionAcceptanceContract.securityToken,
  String privacy = Sprint118ExpansionAcceptanceContract.privacyToken,
  String accessibility =
      Sprint118ExpansionAcceptanceContract.accessibilityToken,
  String documentation =
      Sprint118ExpansionAcceptanceContract.documentationToken,
  String rollback = Sprint118ExpansionAcceptanceContract.rollbackToken,
  bool allowed = false,
  bool admitted = false,
  bool accepted = false,
  bool passed = false,
  bool evidenceComplete = false,
  bool certified = false,
  bool released = false,
}) {
  return Sprint118ExpansionAcceptanceEntry(
    providerId: providerId,
    certification: certification,
    contractTests: contractTests,
    security: security,
    privacy: privacy,
    accessibility: accessibility,
    documentation: documentation,
    rollback: rollback,
    allowed: allowed,
    admitted: admitted,
    accepted: accepted,
    passed: passed,
    evidenceComplete: evidenceComplete,
    certified: certified,
    released: released,
  );
}

Sprint118ExpansionAcceptanceRecord _record({
  String releaseState =
      Sprint118ExpansionAcceptanceContract.delayedReleaseState,
  List<Sprint118ExpansionAcceptanceEntry>? entries,
}) {
  return Sprint118ExpansionAcceptanceRecord(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118ExpansionAcceptanceContract.canonicalRecord.entries,
  );
}

/// The canonical entries with exactly one provider replaced, so a test can flip
/// a single entry without rebuilding the whole record.
List<Sprint118ExpansionAcceptanceEntry> _replacing(
  String providerId,
  Sprint118ExpansionAcceptanceEntry replacement,
) {
  return <Sprint118ExpansionAcceptanceEntry>[
    for (final e
        in Sprint118ExpansionAcceptanceContract.canonicalRecord.entries)
      if (e.providerId == providerId) replacement else e,
  ];
}

Sprint118ExpansionAcceptanceAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict =
      Sprint118ExpansionAcceptanceContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint118ExpansionAcceptanceContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict =
      Sprint118ExpansionAcceptanceContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered =
      Sprint118ExpansionAcceptanceContract.expectedProviderCount,
  String releaseState =
      Sprint118ExpansionAcceptanceContract.delayedReleaseState,
  int registryExpectedCount =
      Sprint118ExpansionAcceptanceContract.expectedProviderCount,
  int registryEvidenceProviderCount =
      Sprint118ExpansionAcceptanceContract.expectedProviderCount,
  int registryEvidenceExposed = 0,
  int registryEvidenceWithheld =
      Sprint118ExpansionAcceptanceContract.expectedProviderCount,
  int snapshotLockLockedCount =
      Sprint118ExpansionAcceptanceContract.expectedProviderCount,
  String approvalDecision =
      Sprint118ExpansionAcceptanceContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  List<String>? registeredProviders,
  List<String>? certificationVocabulary,
  List<String>? contractVocabulary,
  List<String>? securityVocabulary,
  List<String>? privacyVocabulary,
  List<String>? accessibilityVocabulary,
  List<String>? documentationVocabulary,
  List<String>? rollbackVocabulary,
  List<String>? readableSources,
}) {
  return Sprint118ExpansionAcceptanceAnchor(
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
        Sprint118ExpansionAcceptanceContract.canonicalProviders,
    certificationVocabulary:
        certificationVocabulary ?? const <String>['UNVERIFIED', 'CERTIFIED'],
    contractVocabulary:
        contractVocabulary ?? const <String>['manifest', 'auth', 'usage'],
    securityVocabulary:
        securityVocabulary ?? const <String>['oauth_tests', 'token_vault'],
    privacyVocabulary:
        privacyVocabulary ??
        const <String>['consent', 'default_collection_off'],
    accessibilityVocabulary:
        accessibilityVocabulary ??
        const <String>['keyboard_complete', 'screen_reader'],
    documentationVocabulary:
        documentationVocabulary ??
        const <String>['user_guides', 'release_notes'],
    rollbackVocabulary:
        rollbackVocabulary ?? const <String>['rb_internal', 'rb_alpha'],
    readableSources:
        readableSources ??
        Sprint118ExpansionAcceptanceContract.witnessSources.toSet().toList(),
  );
}

Sprint118ExpansionAcceptanceReport _run(
  Sprint118ExpansionAcceptanceRecord record, {
  Sprint118ExpansionAcceptanceAnchor? anchor,
}) {
  return const Sprint118ExpansionAcceptanceGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.42 Expansion Acceptance Gate', () {
    test(
      'the canonical field vocabulary is the seven objective dimensions',
      () {
        expect(Sprint118ExpansionAcceptanceContract.requiredFields, <String>[
          'certification',
          'contract_tests',
          'security',
          'privacy',
          'accessibility',
          'documentation',
          'rollback',
        ]);
      },
    );

    test('the canonical outputs are the seven objective dimensions', () {
      expect(Sprint118ExpansionAcceptanceContract.requiredOutputs, <String>[
        'certification',
        'contract_tests',
        'security',
        'privacy',
        'accessibility',
        'documentation',
        'rollback',
      ]);
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary = Sprint118ExpansionAcceptanceContract.stateVocabulary(
          <List<String>>[
            const <String>['UNVERIFIED', 'manifest'],
            const <String>['oauth_tests', 'consent'],
          ],
        );
        expect(vocabulary, contains('UNVERIFIED'));
        expect(vocabulary, contains('manifest'));
        expect(vocabulary, contains('oauth_tests'));
        expect(vocabulary, contains('consent'));
        expect(
          vocabulary,
          contains(Sprint118ExpansionAcceptanceContract.noReferenceState),
        );
        expect(
          Sprint118ExpansionAcceptanceContract.grounds(
            vocabulary,
            'UNVERIFIED',
          ),
          isTrue,
        );
        expect(
          Sprint118ExpansionAcceptanceContract.grounds(vocabulary, 'telepathy'),
          isFalse,
        );
      },
    );

    test(
      'a compound reference state is grounded only when every part is a witness value',
      () {
        final vocabulary = <String>['keyboard_complete', 'screen_reader'];
        expect(
          Sprint118ExpansionAcceptanceContract.grounds(
            vocabulary,
            'keyboard_complete',
          ),
          isTrue,
        );
        expect(
          Sprint118ExpansionAcceptanceContract.grounds(
            vocabulary,
            'screen_reader',
          ),
          isTrue,
        );
        expect(
          Sprint118ExpansionAcceptanceContract.grounds(
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
        final record = Sprint118ExpansionAcceptanceContract.canonicalRecord;
        expect(record.entries.length, 32);
        expect(
          record.providerIds.toSet(),
          Sprint118ExpansionAcceptanceContract.canonicalProviders.toSet(),
        );
        for (final entry in record.entries) {
          expect(entry.allowed, isFalse);
          expect(entry.admitted, isFalse);
          expect(entry.accepted, isFalse);
          expect(entry.passed, isFalse);
          expect(entry.evidenceComplete, isFalse);
          expect(entry.certified, isFalse);
          expect(entry.released, isFalse);
          for (final field
              in Sprint118ExpansionAcceptanceContract.requiredFields) {
            expect(
              (entry.requiredFields[field] ?? '').trim(),
              isNotEmpty,
              reason: '${entry.providerId}.$field must not be blank',
            );
          }
        }
      },
    );

    test('passes on the canonical record and claims no live acceptance', () {
      final report = _run(_record());
      expect(report.state, Sprint118ExpansionAcceptanceState.pass);
      expect(report.verdict, 'EXPANSION_ACCEPTANCE_GATE_VERIFIED_LOCAL');
      expect(report.recordVerified, isTrue);
      expect(report.declaredProviders.length, 32);
      expect(report.allowedProviders, isEmpty);
      expect(report.admittedProviders, isEmpty);
      expect(report.acceptedProviders, isEmpty);
      expect(report.passedProviders, isEmpty);
      expect(report.certifiedProviders, isEmpty);
      expect(report.releasedProviders, isEmpty);
      expect(report.expansionBudgetFrozen, isTrue);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118ExpansionAcceptanceGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118ExpansionAcceptanceState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_EXPANSION_ACCEPTANCE_EVIDENCE_UNREADABLE',
      );
      expect(report.recordVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_expansion_acceptance_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is not complete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE_LOCAL'),
      );
      expect(report.state, Sprint118ExpansionAcceptanceState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_EXPANSION_ACCEPTANCE_BLOCKED_UPSTREAM',
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
      expect(report.state, Sprint118ExpansionAcceptanceState.blocked);
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
      expect(report.state, Sprint118ExpansionAcceptanceState.blocked);
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
      expect(report.state, Sprint118ExpansionAcceptanceState.blocked);
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
        expect(report.state, Sprint118ExpansionAcceptanceState.blocked);
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
      expect(report.state, Sprint118ExpansionAcceptanceState.blocked);
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
      expect(report.state, Sprint118ExpansionAcceptanceState.blocked);
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
      expect(report.state, Sprint118ExpansionAcceptanceState.blocked);
      expect(
        report.blockers.any(
          (b) => b.startsWith('registry_visibility_exposed_on_delayed_path:'),
        ),
        isTrue,
      );
    });

    test('fails when a provider claims an allowed connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', allowed: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations,
        contains('expansion_acceptance_allowed_claimed_on_delayed_path:stripe'),
      );
      expect(report.allowedCount, 1);
    });

    test('fails when a provider claims an admitted connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'paypal',
            _entry(providerId: 'paypal', admitted: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations,
        contains(
          'expansion_acceptance_admitted_claimed_on_delayed_path:paypal',
        ),
      );
      expect(report.admittedCount, 1);
    });

    test('fails when a provider claims acceptance granted', () {
      final report = _run(
        _record(
          entries: _replacing(
            'midtrans',
            _entry(providerId: 'midtrans', accepted: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations,
        contains(
          'expansion_acceptance_accepted_claimed_on_delayed_path:midtrans',
        ),
      );
      expect(report.acceptedCount, 1);
    });

    test('fails when a provider claims a passed acceptance gate', () {
      final report = _run(
        _record(
          entries: _replacing(
            'saweria',
            _entry(providerId: 'saweria', passed: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations,
        contains('expansion_acceptance_passed_claimed_on_delayed_path:saweria'),
      );
      expect(report.passedCount, 1);
    });

    test('fails when a provider claims a complete evidence set', () {
      final report = _run(
        _record(
          entries: _replacing(
            'kofi',
            _entry(providerId: 'kofi', evidenceComplete: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations,
        contains(
          'expansion_acceptance_evidence_complete_claimed_on_delayed_path:kofi',
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
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations,
        contains(
          'expansion_acceptance_certified_claimed_on_delayed_path:openai',
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
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations,
        contains('expansion_acceptance_released_claimed:stripe'),
      );
      expect(report.releasedCount, 1);
    });

    test('fails when the expansion budget is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterMaxNewCertified: 1),
      );
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations.any(
          (v) =>
              v.startsWith('expansion_acceptance_expansion_budget_not_frozen:'),
        ),
        isTrue,
      );
      expect(report.expansionBudgetFrozen, isFalse);
    });

    test('fails when the snapshot certifies a connector', () {
      final report = _run(_record(), anchor: _anchor(snapshotCertified: 1));
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations,
        contains('expansion_acceptance_snapshot_certified_nonzero:1'),
      );
    });

    test('fails when a registered provider is missing', () {
      final entries = <Sprint118ExpansionAcceptanceEntry>[
        for (final e
            in Sprint118ExpansionAcceptanceContract.canonicalRecord.entries)
          if (e.providerId != 'kofi') e,
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations,
        contains('expansion_acceptance_provider_missing:kofi'),
      );
    });

    test('fails when an unknown provider is invented', () {
      final entries = <Sprint118ExpansionAcceptanceEntry>[
        ...Sprint118ExpansionAcceptanceContract.canonicalRecord.entries,
        _entry(providerId: 'telepathy'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations,
        contains('expansion_acceptance_provider_unknown:telepathy'),
      );
    });

    test('fails when a provider is duplicated', () {
      final entries = <Sprint118ExpansionAcceptanceEntry>[
        ...Sprint118ExpansionAcceptanceContract.canonicalRecord.entries,
        _entry(providerId: 'stripe'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations,
        contains('expansion_acceptance_provider_duplicate:stripe'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', certification: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(report.violations, contains('entry_blank_certification:stripe'));
    });

    test('fails when a reference state is not grounded by a witness', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', certification: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:certification:stripe'),
      );
    });

    test('records an open item when an output has no reference state', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(
              providerId: 'stripe',
              certification:
                  Sprint118ExpansionAcceptanceContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionAcceptanceState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:certification:stripe'),
      );
    });

    test('fails when the record is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations,
        contains('expansion_acceptance_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test('fails when the release state disagrees with the anchor', () {
      final report = _run(
        _record(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
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
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations,
        contains('expansion_acceptance_execution_authorized_on_delayed_path'),
      );
    });

    test('fails when the release is not blocked on the delayed path', () {
      final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations,
        contains('expansion_acceptance_release_not_blocked_on_delayed_path'),
      );
    });

    test('fails when a committed evidence source is unreadable', () {
      final report = _run(
        _record(),
        anchor: _anchor(readableSources: const <String>[]),
      );
      expect(report.state, Sprint118ExpansionAcceptanceState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('required_source_unreadable:'),
        ),
        isTrue,
      );
    });

    test('the canonical sources cover every output', () {
      expect(
        Sprint118ExpansionAcceptanceContract.canonicalSources.length,
        Sprint118ExpansionAcceptanceContract.requiredOutputs.length,
      );
      for (final output
          in Sprint118ExpansionAcceptanceContract.requiredOutputs) {
        expect(
          Sprint118ExpansionAcceptanceContract.sourceFor(output),
          isNotEmpty,
          reason: '$output must have a committed source',
        );
      }
    });

    test('the loader reads the committed witnesses', () {
      final anchor = const Sprint118ExpansionAcceptanceLoader().loadAnchor();
      expect(anchor, isNotNull);
      expect(anchor!.registeredProviders.length, 32);
      expect(anchor.charterVerdict, 'CHARTER_COMPLETE_LOCAL');
      expect(
        anchor.snapshotVerdict,
        'CERTIFIED_CONNECTOR_SNAPSHOT_AUTHORIZED_LOCAL',
      );
      expect(anchor.approvalDecision, 'delay');
      expect(anchor.releaseState, 'GA_AUTHORIZED');
      expect(anchor.registryEvidenceExposed, 1);
      expect(anchor.registryEvidenceWithheld, 31);
      expect(anchor.snapshotLockLockedCount, 32);
      expect(anchor.readableSources.length, 14);
      expect(anchor.certificationVocabulary, contains('UNVERIFIED'));
      expect(anchor.contractVocabulary, contains('manifest'));
      expect(anchor.securityVocabulary, contains('oauth_tests'));
      expect(anchor.privacyVocabulary, contains('consent'));
      expect(anchor.accessibilityVocabulary, contains('keyboard_complete'));
      expect(anchor.documentationVocabulary, contains('user_guides'));
      expect(anchor.rollbackVocabulary, contains('rb_internal'));
    });

    test('the gate passes end to end against the committed witnesses', () {
      final report = const Sprint118ExpansionAcceptanceGate().evaluate();
      expect(report.state, Sprint118ExpansionAcceptanceState.pass);
      expect(report.verdict, 'EXPANSION_ACCEPTANCE_GATE_AUTHORIZED_LOCAL');
      expect(report.allowedCount, 0);
      expect(report.admittedCount, 0);
      expect(report.acceptedCount, 0);
      expect(report.passedCount, 0);
      expect(report.certifiedCount, 1);
      expect(report.releasedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });
  });
}
