import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_brand_legal_readiness.dart';

/// A single brand & legal readiness entry. Each test flips exactly the one thing
/// it is about, so a test that flips nothing proves the pass path exists and
/// every other test proves one way the gate refuses to take it.
Sprint118BrandLegalEntry _entry({
  String providerId = 'openai',
  String assetSource = Sprint118BrandLegalContract.assetSourceToken,
  String permission = Sprint118BrandLegalContract.permissionToken,
  String trademarkRules = Sprint118BrandLegalContract.trademarkRulesToken,
  String attribution = Sprint118BrandLegalContract.attributionToken,
  String license = Sprint118BrandLegalContract.licenseToken,
  String listingConstraints =
      Sprint118BrandLegalContract.listingConstraintsToken,
  bool logoUseApproved = false,
  bool namingCleared = false,
  bool attributionPublished = false,
  bool licenseGranted = false,
  bool trademarkCleared = false,
  bool listingApproved = false,
  bool released = false,
}) {
  return Sprint118BrandLegalEntry(
    providerId: providerId,
    assetSource: assetSource,
    permission: permission,
    trademarkRules: trademarkRules,
    attribution: attribution,
    license: license,
    listingConstraints: listingConstraints,
    logoUseApproved: logoUseApproved,
    namingCleared: namingCleared,
    attributionPublished: attributionPublished,
    licenseGranted: licenseGranted,
    trademarkCleared: trademarkCleared,
    listingApproved: listingApproved,
    released: released,
  );
}

Sprint118BrandLegalRecord _record({
  String releaseState = Sprint118BrandLegalContract.delayedReleaseState,
  List<Sprint118BrandLegalEntry>? entries,
}) {
  return Sprint118BrandLegalRecord(
    releaseState: releaseState,
    entries: entries ?? Sprint118BrandLegalContract.canonicalRecord.entries,
  );
}

/// The canonical entries with exactly one provider replaced, so a test can flip
/// a single entry without rebuilding the whole record.
List<Sprint118BrandLegalEntry> _replacing(
  String providerId,
  Sprint118BrandLegalEntry replacement,
) {
  return <Sprint118BrandLegalEntry>[
    for (final e in Sprint118BrandLegalContract.canonicalRecord.entries)
      if (e.providerId == providerId) replacement else e,
  ];
}

Sprint118BrandLegalAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict = Sprint118BrandLegalContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint118BrandLegalContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict = Sprint118BrandLegalContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered = Sprint118BrandLegalContract.expectedProviderCount,
  String releaseState = Sprint118BrandLegalContract.delayedReleaseState,
  int registryExpectedCount = Sprint118BrandLegalContract.expectedProviderCount,
  String approvalDecision =
      Sprint118BrandLegalContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  String brandStatus = Sprint118BrandLegalContract.requiredBrandStatus,
  String brandVerdict = Sprint118BrandLegalContract.requiredBrandVerdict,
  String brandExternalGates = 'DEFERRED-EXTERNAL',
  List<String>? registeredProviders,
  List<String>? assetSourceVocabulary,
  List<String>? permissionVocabulary,
  List<String>? trademarkRulesVocabulary,
  List<String>? attributionVocabulary,
  List<String>? licenseVocabulary,
  List<String>? listingConstraintsVocabulary,
  List<String>? readableSources,
}) {
  return Sprint118BrandLegalAnchor(
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
    brandStatus: brandStatus,
    brandVerdict: brandVerdict,
    brandExternalGates: brandExternalGates,
    registeredProviders:
        registeredProviders ?? Sprint118BrandLegalContract.canonicalProviders,
    assetSourceVocabulary:
        assetSourceVocabulary ?? const <String>['synthetic fixture'],
    permissionVocabulary:
        permissionVocabulary ?? const <String>['not a production mark'],
    trademarkRulesVocabulary:
        trademarkRulesVocabulary ?? const <String>['trademark_notice'],
    attributionVocabulary:
        attributionVocabulary ??
        const <String>['synthetic attribution fixture'],
    licenseVocabulary:
        licenseVocabulary ?? const <String>['synthetic license fixture'],
    listingConstraintsVocabulary:
        listingConstraintsVocabulary ?? const <String>['DEFERRED-EXTERNAL'],
    readableSources:
        readableSources ??
        Sprint118BrandLegalContract.witnessSources.toSet().toList(),
  );
}

Sprint118BrandLegalReport _run(
  Sprint118BrandLegalRecord record, {
  Sprint118BrandLegalAnchor? anchor,
}) {
  return const Sprint118BrandLegalGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.32 Brand & Legal Readiness', () {
    test('the canonical field vocabulary is the seven objective fields', () {
      expect(Sprint118BrandLegalContract.requiredFields, <String>[
        'provider_id',
        'asset_source',
        'permission',
        'trademark_rules',
        'attribution',
        'license',
        'listing_constraints',
      ]);
    });

    test('the canonical outputs are the six objective items', () {
      expect(Sprint118BrandLegalContract.requiredOutputs, <String>[
        'asset_source',
        'permission',
        'trademark_rules',
        'attribution',
        'license',
        'listing_constraints',
      ]);
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary = Sprint118BrandLegalContract.stateVocabulary(
          <List<String>>[
            const <String>['synthetic fixture', 'trademark_notice'],
            const <String>['DEFERRED-EXTERNAL'],
          ],
        );
        expect(vocabulary, contains('synthetic fixture'));
        expect(vocabulary, contains('trademark_notice'));
        expect(vocabulary, contains('DEFERRED-EXTERNAL'));
        expect(
          vocabulary,
          contains(Sprint118BrandLegalContract.noReferenceState),
        );
        expect(
          Sprint118BrandLegalContract.grounds(vocabulary, 'trademark_notice'),
          isTrue,
        );
        expect(
          Sprint118BrandLegalContract.grounds(vocabulary, 'telepathy'),
          isFalse,
        );
      },
    );

    test(
      'canonical record covers all 32 registered providers and claims nothing',
      () {
        final record = Sprint118BrandLegalContract.canonicalRecord;
        expect(record.entries.length, 32);
        expect(
          record.providerIds.toSet(),
          Sprint118BrandLegalContract.canonicalProviders.toSet(),
        );
        for (final entry in record.entries) {
          expect(entry.logoUseApproved, isFalse);
          expect(entry.namingCleared, isFalse);
          expect(entry.attributionPublished, isFalse);
          expect(entry.licenseGranted, isFalse);
          expect(entry.trademarkCleared, isFalse);
          expect(entry.listingApproved, isFalse);
          expect(entry.released, isFalse);
          for (final field in Sprint118BrandLegalContract.requiredFields) {
            expect(
              (entry.requiredFields[field] ?? '').trim(),
              isNotEmpty,
              reason: '${entry.providerId}.$field must not be blank',
            );
          }
        }
      },
    );

    test('passes on the canonical record and claims no live readiness', () {
      final report = _run(_record());
      expect(report.state, Sprint118BrandLegalState.pass);
      expect(report.verdict, 'BRAND_LEGAL_READINESS_VERIFIED_LOCAL');
      expect(report.readinessVerified, isTrue);
      expect(report.declaredProviders.length, 32);
      expect(report.logoUseApprovedProviders, isEmpty);
      expect(report.listingApprovedProviders, isEmpty);
      expect(report.expansionBudgetFrozen, isTrue);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118BrandLegalGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118BrandLegalState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_BRAND_LEGAL_READINESS_EVIDENCE_UNREADABLE',
      );
      expect(report.readinessVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_brand_legal_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is incomplete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118BrandLegalState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_BRAND_LEGAL_READINESS_BLOCKED_UPSTREAM',
      );
      expect(report.blockers, contains('charter_not_complete:SOMETHING_ELSE'));
    });

    test('blocks when the committed snapshot is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(snapshotVerdict: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118BrandLegalState.blocked);
      expect(report.blockers, contains('snapshot_not_frozen:SOMETHING_ELSE'));
    });

    test('blocks when the approval gate is not a delay', () {
      final report = _run(
        _record(),
        anchor: _anchor(approvalDecision: 'release'),
      );
      expect(report.state, Sprint118BrandLegalState.blocked);
      expect(report.blockers, contains('approval_gate_not_delay:release'));
    });

    test('blocks when the brand certification is not schema-ready', () {
      final report = _run(
        _record(),
        anchor: _anchor(brandVerdict: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118BrandLegalState.blocked);
      expect(
        report.blockers,
        contains(
          'brand_certification_not_schema_ready:VERIFIED-LOCAL:'
          'SOMETHING_ELSE:DEFERRED-EXTERNAL',
        ),
      );
    });

    test('blocks when the registered provider set does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(registryExpectedCount: 31),
      );
      expect(report.state, Sprint118BrandLegalState.blocked);
      expect(
        report.blockers,
        contains(
          'registry_not_reconciled:icon=32:reconciliation=31:'
          'snapshot=32:charter=32',
        ),
      );
    });

    test('fails when the record release state disagrees with the anchor', () {
      final report = _run(
        _record(releaseState: 'GA_RELEASED'),
        anchor: _anchor(),
      );
      expect(report.state, Sprint118BrandLegalState.fail);
      expect(
        report.violations,
        contains('release_state_mismatch:anchor=GA_DELAYED:record=GA_RELEASED'),
      );
    });

    test('fails when the readiness is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118BrandLegalState.fail);
      expect(
        report.violations,
        contains('brand_legal_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test(
      'fails when readiness execution is authorized on the delayed path',
      () {
        final report = _run(
          _record(),
          anchor: _anchor(executionAuthorized: true),
        );
        expect(report.state, Sprint118BrandLegalState.fail);
        expect(
          report.violations,
          contains('brand_legal_execution_authorized_on_delayed_path'),
        );
      },
    );

    test(
      'fails when the readiness release is not blocked on the delayed path',
      () {
        final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
        expect(report.state, Sprint118BrandLegalState.fail);
        expect(
          report.violations,
          contains('brand_legal_release_not_blocked_on_delayed_path'),
        );
      },
    );

    test('fails when the expansion budget is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterMaxNewCertified: 1),
      );
      expect(report.state, Sprint118BrandLegalState.fail);
      expect(
        report.violations,
        contains(
          'brand_legal_expansion_budget_not_frozen:max_new=1:currently=0',
        ),
      );
    });

    test('fails when a registered provider is missing', () {
      final report = _run(
        _record(
          entries: <Sprint118BrandLegalEntry>[
            for (final e in Sprint118BrandLegalContract.canonicalRecord.entries)
              if (e.providerId != 'openai') e,
          ],
        ),
      );
      expect(report.state, Sprint118BrandLegalState.fail);
      expect(
        report.violations,
        contains('brand_legal_provider_missing:openai'),
      );
    });

    test('fails when a registered provider is duplicated', () {
      final report = _run(
        _record(
          entries: <Sprint118BrandLegalEntry>[
            ...Sprint118BrandLegalContract.canonicalRecord.entries,
            _entry(providerId: 'openai'),
          ],
        ),
      );
      expect(report.state, Sprint118BrandLegalState.fail);
      expect(
        report.violations,
        contains('brand_legal_provider_duplicate:openai'),
      );
    });

    test('fails when an unknown provider is invented', () {
      final report = _run(
        _record(
          entries: <Sprint118BrandLegalEntry>[
            ...Sprint118BrandLegalContract.canonicalRecord.entries,
            _entry(providerId: 'telepathy'),
          ],
        ),
      );
      expect(report.state, Sprint118BrandLegalState.fail);
      expect(
        report.violations,
        contains('brand_legal_provider_unknown:telepathy'),
      );
    });

    test('fails when a required entry field is blank', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', license: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118BrandLegalState.fail);
      expect(report.violations, contains('entry_blank_license:openai'));
    });

    test('fails when an output is not grounded by a witness', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', trademarkRules: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118BrandLegalState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:trademark_rules:openai'),
      );
    });

    test('records an open item when an output is the no-reference marker', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(
              providerId: 'openai',
              listingConstraints: Sprint118BrandLegalContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118BrandLegalState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:listing_constraints:openai'),
      );
    });

    test('fails when an entry claims a verified logo use', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', logoUseApproved: true),
          ),
        ),
      );
      expect(report.state, Sprint118BrandLegalState.fail);
      expect(
        report.violations,
        contains('brand_legal_logo_use_claimed_on_delayed_path:openai'),
      );
      expect(report.logoUseApprovedProviders, contains('openai'));
    });

    test('fails when an entry claims a cleared naming', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', namingCleared: true),
          ),
        ),
      );
      expect(report.state, Sprint118BrandLegalState.fail);
      expect(
        report.violations,
        contains('brand_legal_naming_cleared_on_delayed_path:openai'),
      );
    });

    test('fails when an entry claims published attribution', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', attributionPublished: true),
          ),
        ),
      );
      expect(report.state, Sprint118BrandLegalState.fail);
      expect(
        report.violations,
        contains('brand_legal_attribution_published_on_delayed_path:openai'),
      );
    });

    test('fails when an entry claims a granted license', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', licenseGranted: true),
          ),
        ),
      );
      expect(report.state, Sprint118BrandLegalState.fail);
      expect(
        report.violations,
        contains('brand_legal_license_granted_on_delayed_path:openai'),
      );
    });

    test('fails when an entry claims a cleared trademark', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', trademarkCleared: true),
          ),
        ),
      );
      expect(report.state, Sprint118BrandLegalState.fail);
      expect(
        report.violations,
        contains('brand_legal_trademark_cleared_on_delayed_path:openai'),
      );
    });

    test('fails when an entry claims an approved marketplace listing', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', listingApproved: true),
          ),
        ),
      );
      expect(report.state, Sprint118BrandLegalState.fail);
      expect(
        report.violations,
        contains('brand_legal_listing_approved_on_delayed_path:openai'),
      );
      expect(report.listingApprovedProviders, contains('openai'));
    });

    test('fails when an entry claims a released provider', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', released: true),
          ),
        ),
      );
      expect(report.state, Sprint118BrandLegalState.fail);
      expect(
        report.violations,
        contains('brand_legal_provider_released_claimed:openai'),
      );
    });

    test('fails when a required evidence source is unreadable', () {
      final report = _run(
        _record(),
        anchor: _anchor(
          readableSources: <String>[
            Sprint118BrandLegalContract.iconRegistryManifestPath,
          ],
        ),
      );
      expect(report.state, Sprint118BrandLegalState.fail);
      expect(
        report.violations,
        contains(
          'required_source_unreadable:'
          'docs/planning/v1.3/sprint_118_stability_expansion_charter.json',
        ),
      );
    });

    test('the loader reads the committed witnesses on disk', () {
      final anchor = const Sprint118BrandLegalLoader().loadAnchor();
      expect(anchor, isNotNull);
      expect(anchor!.charterState, 'pass');
      expect(anchor.charterVerdict, 'CHARTER_COMPLETE_LOCAL');
      expect(anchor.charterMaxNewCertified, 0);
      expect(anchor.charterCurrentlyCertified, 0);
      expect(anchor.charterRegisteredProviders, 32);
      expect(
        anchor.snapshotVerdict,
        'CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL',
      );
      expect(anchor.snapshotRegistered, 32);
      expect(anchor.registryExpectedCount, 32);
      expect(anchor.approvalDecision, 'delay');
      expect(anchor.approvalState, 'PENDING_CHOIRUDIN');
      expect(anchor.executionAuthorized, isFalse);
      expect(anchor.releaseBlocked, isTrue);
      expect(anchor.brandStatus, 'VERIFIED-LOCAL');
      expect(anchor.brandVerdict, 'BRAND_ICON_SCHEMA_READY');
      expect(anchor.brandExternalGates, 'DEFERRED-EXTERNAL');
      expect(anchor.registeredProviders.length, 32);
      expect(anchor.assetSourceVocabulary, contains('synthetic fixture'));
      expect(anchor.permissionVocabulary, contains('not a production mark'));
      expect(anchor.trademarkRulesVocabulary, contains('trademark_notice'));
      expect(
        anchor.attributionVocabulary,
        contains('synthetic attribution fixture'),
      );
      expect(anchor.licenseVocabulary, contains('synthetic license fixture'));
      expect(
        anchor.listingConstraintsVocabulary,
        contains('DEFERRED-EXTERNAL'),
      );
      expect(anchor.readableSources.length, 8);
    });

    test('the gate evaluates the committed record to a pass', () {
      final report = const Sprint118BrandLegalGate().evaluate();
      expect(report.state, Sprint118BrandLegalState.pass);
      expect(report.verdict, 'BRAND_LEGAL_READINESS_VERIFIED_LOCAL');
      expect(report.releaseState, 'GA_DELAYED');
      expect(report.declaredProviders.length, 32);
      expect(report.logoUseApprovedProviders, isEmpty);
      expect(report.listingApprovedProviders, isEmpty);
    });
  });
}
