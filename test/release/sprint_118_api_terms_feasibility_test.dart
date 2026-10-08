import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_api_terms_feasibility.dart';

/// A single feasibility-refresh entry. Each test flips exactly the one thing it
/// is about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it.
Sprint118ApiTermsFeasibilityEntry _entry({
  String providerId = 'openai',
  String primarySources =
      Sprint118ApiTermsFeasibilityContract.primarySourcesToken,
  String verificationDate =
      Sprint118ApiTermsFeasibilityContract.verificationDateToken,
  String apiVersion = Sprint118ApiTermsFeasibilityContract.apiVersionToken,
  String sdkVersion = Sprint118ApiTermsFeasibilityContract.sdkVersionToken,
  String deprecations = Sprint118ApiTermsFeasibilityContract.deprecationsToken,
  String authScopes = Sprint118ApiTermsFeasibilityContract.authScopesToken,
  String termsLimits = Sprint118ApiTermsFeasibilityContract.termsLimitsToken,
  bool refreshed = false,
  bool verified = false,
  bool deprecationsConfirmed = false,
  bool scopesGranted = false,
  bool termsAccepted = false,
  bool released = false,
}) {
  return Sprint118ApiTermsFeasibilityEntry(
    providerId: providerId,
    primarySources: primarySources,
    verificationDate: verificationDate,
    apiVersion: apiVersion,
    sdkVersion: sdkVersion,
    deprecations: deprecations,
    authScopes: authScopes,
    termsLimits: termsLimits,
    refreshed: refreshed,
    verified: verified,
    deprecationsConfirmed: deprecationsConfirmed,
    scopesGranted: scopesGranted,
    termsAccepted: termsAccepted,
    released: released,
  );
}

Sprint118ApiTermsFeasibilityRecord _record({
  String releaseState =
      Sprint118ApiTermsFeasibilityContract.delayedReleaseState,
  List<Sprint118ApiTermsFeasibilityEntry>? entries,
}) {
  return Sprint118ApiTermsFeasibilityRecord(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118ApiTermsFeasibilityContract.canonicalRecord.entries,
  );
}

/// The canonical entries with exactly one provider replaced, so a test can flip
/// a single entry without rebuilding the whole record.
List<Sprint118ApiTermsFeasibilityEntry> _replacing(
  String providerId,
  Sprint118ApiTermsFeasibilityEntry replacement,
) {
  return <Sprint118ApiTermsFeasibilityEntry>[
    for (final e
        in Sprint118ApiTermsFeasibilityContract.canonicalRecord.entries)
      if (e.providerId == providerId) replacement else e,
  ];
}

Sprint118ApiTermsFeasibilityAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict =
      Sprint118ApiTermsFeasibilityContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint118ApiTermsFeasibilityContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict =
      Sprint118ApiTermsFeasibilityContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered =
      Sprint118ApiTermsFeasibilityContract.expectedProviderCount,
  String releaseState =
      Sprint118ApiTermsFeasibilityContract.delayedReleaseState,
  int registryExpectedCount =
      Sprint118ApiTermsFeasibilityContract.expectedProviderCount,
  String approvalDecision =
      Sprint118ApiTermsFeasibilityContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  String apiSdkStatus =
      Sprint118ApiTermsFeasibilityContract.requiredApiSdkStatus,
  String apiSdkVerdict =
      Sprint118ApiTermsFeasibilityContract.requiredApiSdkVerdict,
  String apiSdkExternalGates = 'DEFERRED-EXTERNAL',
  List<String>? registeredProviders,
  List<String>? primarySourcesVocabulary,
  List<String>? verificationDateVocabulary,
  List<String>? apiVersionVocabulary,
  List<String>? sdkVersionVocabulary,
  List<String>? deprecationsVocabulary,
  List<String>? authScopesVocabulary,
  List<String>? termsLimitsVocabulary,
  List<String>? readableSources,
}) {
  return Sprint118ApiTermsFeasibilityAnchor(
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
    apiSdkStatus: apiSdkStatus,
    apiSdkVerdict: apiSdkVerdict,
    apiSdkExternalGates: apiSdkExternalGates,
    registeredProviders:
        registeredProviders ??
        Sprint118ApiTermsFeasibilityContract.canonicalProviders,
    primarySourcesVocabulary:
        primarySourcesVocabulary ?? const <String>['local-contract-fixture'],
    verificationDateVocabulary:
        verificationDateVocabulary ?? const <String>['2026-09-27'],
    apiVersionVocabulary: apiVersionVocabulary ?? const <String>['not-claimed'],
    sdkVersionVocabulary: sdkVersionVocabulary ?? const <String>['not-claimed'],
    deprecationsVocabulary:
        deprecationsVocabulary ??
        const <String>['live provider documentation review deferred'],
    authScopesVocabulary:
        authScopesVocabulary ??
        const <String>[
          'flow_type',
          'pkce_method',
          'state',
          'nonce',
          'scoped_consent',
          'callback',
          'token_rotation',
          'unlink',
          'secret_surface',
        ],
    termsLimitsVocabulary:
        termsLimitsVocabulary ??
        const <String>[
          'invalid_credentials',
          'expired',
          'revoked',
          'scope_denied',
          'rate_limited',
          'outage',
          'unsupported_region',
          'unsupported_plan',
        ],
    readableSources:
        readableSources ??
        Sprint118ApiTermsFeasibilityContract.witnessSources.toSet().toList(),
  );
}

Sprint118ApiTermsFeasibilityReport _run(
  Sprint118ApiTermsFeasibilityRecord record, {
  Sprint118ApiTermsFeasibilityAnchor? anchor,
}) {
  return const Sprint118ApiTermsFeasibilityGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.31 API, SDK & Terms Feasibility Refresh', () {
    test('the canonical field vocabulary is the eight objective fields', () {
      expect(Sprint118ApiTermsFeasibilityContract.requiredFields, <String>[
        'provider_id',
        'primary_sources',
        'verification_date',
        'api_version',
        'sdk_version',
        'deprecations',
        'auth_scopes',
        'terms_limits',
      ]);
    });

    test('the canonical outputs are the seven objective items', () {
      expect(Sprint118ApiTermsFeasibilityContract.requiredOutputs, <String>[
        'primary_sources',
        'verification_date',
        'api_version',
        'sdk_version',
        'deprecations',
        'auth_scopes',
        'terms_limits',
      ]);
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary = Sprint118ApiTermsFeasibilityContract.stateVocabulary(
          <List<String>>[
            const <String>['local-contract-fixture', 'not-claimed'],
            const <String>['scoped_consent'],
          ],
        );
        expect(vocabulary, contains('local-contract-fixture'));
        expect(vocabulary, contains('not-claimed'));
        expect(vocabulary, contains('scoped_consent'));
        expect(
          vocabulary,
          contains(Sprint118ApiTermsFeasibilityContract.noReferenceState),
        );
        // A token only grounds when the witness names it exactly, or when every
        // underscore-separated part is itself a witness-declared value.
        expect(
          Sprint118ApiTermsFeasibilityContract.grounds(
            vocabulary,
            'not-claimed',
          ),
          isTrue,
        );
        expect(
          Sprint118ApiTermsFeasibilityContract.grounds(vocabulary, 'telepathy'),
          isFalse,
        );
        expect(
          Sprint118ApiTermsFeasibilityContract.grounds(const <String>[
            'unsupported',
            'plan',
          ], 'unsupported_plan'),
          isTrue,
        );
        expect(
          Sprint118ApiTermsFeasibilityContract.grounds(const <String>[
            'unsupported',
          ], 'unsupported_plan'),
          isFalse,
        );
      },
    );

    test(
      'canonical record covers all 32 registered providers and claims nothing',
      () {
        final record = Sprint118ApiTermsFeasibilityContract.canonicalRecord;
        expect(record.entries.length, 32);
        expect(
          record.providerIds.toSet(),
          Sprint118ApiTermsFeasibilityContract.canonicalProviders.toSet(),
        );
        expect(record.refreshedProviders, isEmpty);
        expect(record.verifiedProviders, isEmpty);
        expect(record.refreshedCount, 0);
        expect(record.verifiedCount, 0);
        for (final entry in record.entries) {
          expect(entry.refreshed, isFalse);
          expect(entry.verified, isFalse);
          expect(entry.deprecationsConfirmed, isFalse);
          expect(entry.scopesGranted, isFalse);
          expect(entry.termsAccepted, isFalse);
          expect(entry.released, isFalse);
          for (final field
              in Sprint118ApiTermsFeasibilityContract.requiredFields) {
            expect(
              (entry.requiredFields[field] ?? '').trim(),
              isNotEmpty,
              reason: '${entry.providerId}.$field must not be blank',
            );
          }
        }
      },
    );

    test('passes on the canonical record and claims no live refresh', () {
      final report = _run(_record());
      expect(report.state, Sprint118ApiTermsFeasibilityState.pass);
      expect(report.verdict, 'API_TERMS_FEASIBILITY_VERIFIED_LOCAL');
      expect(report.feasibilityVerified, isTrue);
      expect(report.declaredProviders.length, 32);
      expect(report.refreshedProviders, isEmpty);
      expect(report.verifiedProviders, isEmpty);
      expect(report.refreshedCount, 0);
      expect(report.verifiedCount, 0);
      expect(report.expansionBudgetFrozen, isTrue);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118ApiTermsFeasibilityGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_API_TERMS_FEASIBILITY_EVIDENCE_UNREADABLE',
      );
      expect(report.feasibilityVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_api_terms_feasibility_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is incomplete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_API_TERMS_FEASIBILITY_BLOCKED_UPSTREAM',
      );
      expect(report.blockers, contains('charter_not_complete:SOMETHING_ELSE'));
    });

    test('blocks when the committed snapshot is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(snapshotVerdict: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.blocked);
      expect(report.blockers, contains('snapshot_not_frozen:SOMETHING_ELSE'));
    });

    test('blocks when the approval gate is not a delay', () {
      final report = _run(
        _record(),
        anchor: _anchor(approvalDecision: 'release'),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.blocked);
      expect(report.blockers, contains('approval_gate_not_delay:release'));
    });

    test('blocks when the API & SDK verification is not schema-ready', () {
      final report = _run(
        _record(),
        anchor: _anchor(apiSdkVerdict: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.blocked);
      expect(
        report.blockers,
        contains(
          'api_sdk_verification_not_schema_ready:VERIFIED-LOCAL:'
          'SOMETHING_ELSE:DEFERRED-EXTERNAL',
        ),
      );
    });

    test('blocks when the registered provider set does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(registryExpectedCount: 31),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.blocked);
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
      expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
      expect(
        report.violations,
        contains('release_state_mismatch:anchor=GA_DELAYED:record=GA_RELEASED'),
      );
    });

    test('fails when the refresh is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
      expect(
        report.violations,
        contains('api_terms_feasibility_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test('fails when refresh execution is authorized on the delayed path', () {
      final report = _run(
        _record(),
        anchor: _anchor(executionAuthorized: true),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
      expect(
        report.violations,
        contains('api_terms_execution_authorized_on_delayed_path'),
      );
    });

    test(
      'fails when the refresh release is not blocked on the delayed path',
      () {
        final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
        expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
        expect(
          report.violations,
          contains('api_terms_release_not_blocked_on_delayed_path'),
        );
      },
    );

    test('fails when the expansion budget is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterMaxNewCertified: 1),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
      expect(
        report.violations,
        contains('api_terms_expansion_budget_not_frozen:max_new=1:currently=0'),
      );
    });

    test('fails when a registered provider is missing', () {
      final report = _run(
        _record(
          entries: <Sprint118ApiTermsFeasibilityEntry>[
            for (final e
                in Sprint118ApiTermsFeasibilityContract.canonicalRecord.entries)
              if (e.providerId != 'openai') e,
          ],
        ),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
      expect(report.violations, contains('api_terms_provider_missing:openai'));
    });

    test('fails when a registered provider is duplicated', () {
      final report = _run(
        _record(
          entries: <Sprint118ApiTermsFeasibilityEntry>[
            ...Sprint118ApiTermsFeasibilityContract.canonicalRecord.entries,
            _entry(providerId: 'openai'),
          ],
        ),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
      expect(
        report.violations,
        contains('api_terms_provider_duplicate:openai'),
      );
    });

    test('fails when an unknown provider is invented', () {
      final report = _run(
        _record(
          entries: <Sprint118ApiTermsFeasibilityEntry>[
            ...Sprint118ApiTermsFeasibilityContract.canonicalRecord.entries,
            _entry(providerId: 'telepathy'),
          ],
        ),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
      expect(
        report.violations,
        contains('api_terms_provider_unknown:telepathy'),
      );
    });

    test('fails when a required entry field is blank', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', apiVersion: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
      expect(report.violations, contains('entry_blank_api_version:openai'));
    });

    test('fails when an output is not grounded by a witness', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', authScopes: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:auth_scopes:openai'),
      );
    });

    test('records an open item when an output is the no-reference marker', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(
              providerId: 'openai',
              termsLimits:
                  Sprint118ApiTermsFeasibilityContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:terms_limits:openai'),
      );
    });

    test('fails when an entry claims a live documentation refresh', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', refreshed: true),
          ),
        ),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
      expect(
        report.violations,
        contains('api_terms_refresh_claimed_on_delayed_path:openai'),
      );
      expect(report.refreshedProviders, contains('openai'));
    });

    test('fails when an entry claims a live verification', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', verified: true),
          ),
        ),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
      expect(
        report.violations,
        contains('api_terms_verification_claimed_on_delayed_path:openai'),
      );
      expect(report.verifiedProviders, contains('openai'));
    });

    test('fails when an entry claims a confirmed deprecation', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', deprecationsConfirmed: true),
          ),
        ),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
      expect(
        report.violations,
        contains('api_terms_deprecation_claimed_on_delayed_path:openai'),
      );
    });

    test('fails when an entry claims a granted auth scope', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', scopesGranted: true),
          ),
        ),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
      expect(
        report.violations,
        contains('api_terms_scope_grant_claimed_on_delayed_path:openai'),
      );
    });

    test('fails when an entry claims accepted terms', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', termsAccepted: true),
          ),
        ),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
      expect(
        report.violations,
        contains('api_terms_terms_accepted_on_delayed_path:openai'),
      );
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
      expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
      expect(
        report.violations,
        contains('api_terms_provider_released_claimed:openai'),
      );
    });

    test('fails when a required evidence source is unreadable', () {
      final report = _run(
        _record(),
        anchor: _anchor(
          readableSources: <String>[
            Sprint118ApiTermsFeasibilityContract.iconRegistryManifestPath,
          ],
        ),
      );
      expect(report.state, Sprint118ApiTermsFeasibilityState.fail);
      expect(
        report.violations,
        contains(
          'required_source_unreadable:'
          'docs/planning/v1.3/sprint_118_stability_expansion_charter.json',
        ),
      );
    });

    test('the loader reads the committed witnesses on disk', () {
      final anchor = const Sprint118ApiTermsFeasibilityLoader().loadAnchor();
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
      expect(anchor.apiSdkStatus, 'VERIFIED-LOCAL');
      expect(anchor.apiSdkVerdict, 'API_SDK_VERIFICATION_SCHEMA_READY');
      expect(anchor.apiSdkExternalGates, 'DEFERRED-EXTERNAL');
      expect(anchor.registeredProviders.length, 32);
      expect(
        anchor.primarySourcesVocabulary,
        contains('local-contract-fixture'),
      );
      expect(anchor.verificationDateVocabulary, contains('2026-09-27'));
      expect(anchor.apiVersionVocabulary, contains('not-claimed'));
      expect(anchor.sdkVersionVocabulary, contains('not-claimed'));
      expect(
        anchor.deprecationsVocabulary,
        contains('live provider documentation review deferred'),
      );
      expect(anchor.authScopesVocabulary, contains('scoped_consent'));
      expect(anchor.termsLimitsVocabulary, contains('unsupported_plan'));
      expect(anchor.readableSources.length, 8);
    });

    test('the gate evaluates the committed record to a pass', () {
      final report = const Sprint118ApiTermsFeasibilityGate().evaluate();
      expect(report.state, Sprint118ApiTermsFeasibilityState.pass);
      expect(report.verdict, 'API_TERMS_FEASIBILITY_VERIFIED_LOCAL');
      expect(report.releaseState, 'GA_DELAYED');
      expect(report.declaredProviders.length, 32);
      expect(report.refreshedProviders, isEmpty);
      expect(report.verifiedProviders, isEmpty);
    });
  });
}
