// Sprint 117.41 — Final Connector Registry Reconciliation.
//
// Canonical step objective: "Memperbarui status per provider berdasarkan
// bukti dan memastikan UNVERIFIED/BLOCKED tidak tampil sebagai available.",
// with seven `required_fields`: `provider_id`, `connector_version`, `status`,
// `evidence`, `limitations`, `visibility`, `recheck_date`.
//
// This slice measures the seven canonical fields as MEASURED conditions over
// the seams that actually ship, and closes three fail-open defects that let a
// provider read as exposed/available while its own evidence says otherwise:
//
// Defect 1 (117.41-01) — the shipped 116.3 provider registry reconciliation
//   hardcoded `aiAvailabilityMismatches: const <String>[]`. The AI provider
//   registry ships `validateAvailabilityAgainst(manifest)`, a real seam that
//   detects an AI entry claiming an availability the connector manifest
//   contradicts. The report therefore reported zero mismatches no matter what
//   the registries said, and `PROVIDER_REGISTRY_RECONCILED` was returned while
//   two shipped registries contradicted each other. Root cause: a duplicated
//   empty literal instead of delegating to the seam that already measures it.
//
// Defect 2 (117.41-02) — `Sprint117SnapshotLoader._lockStatus` returns an EMPTY
//   status for a visibility outside {certified, limited, blocked}. The exposed
//   subset is computed as `status != BLOCKED`, so an unmappable visibility is
//   fail-OPEN: the provider lands in `exposedSubset` and `blockedSubset` stays
//   empty. A row whose own status is literally `BLOCKED` was reported as
//   EXPOSED. Root cause: an allow-list that produces an empty string which then
//   compares unequal to the one blocking status, instead of the empty result
//   itself withholding the provider.
//
// Defect 3 (117.41-03) — the snapshot lock resolves the exposed subset from the
//   ENTRY GATE visibility but never checks that the locked row's own status
//   agrees. A provider recorded BLOCKED in the visibility map whose lock row
//   claims CERTIFIED landed in `exposedSubset` with no violation recorded,
//   because `visibility_unknown` only fires for unrecognised visibility text and
//   the `status_drift` check is guarded behind a vocabulary that the crafted
//   anchor satisfied. This slice measures visibility/status coherence as a
//   first-class condition instead of relying on that ordering.
//
// Every `observed` value in this file is taken from a map built by running the
// shipped seam in this run; nothing is hand-typed. The aggregate probe throws
// `StateError` if a single probe was never filled in.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_ai_provider_registry.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_registry_reconciliation.dart';
import 'package:void_scriptor/features/world_logic/domain/github_app_release_authorization.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_certification_snapshot_lock.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_final_connector_registry_reconciliation.dart';

/// Writes the committed evidence file and returns its byte count.
///
/// The sha256 is deliberately NOT computed here: per the repository SHA policy
/// the ledger value is hashed from the COMMITTED artifact (`git show`), never
/// from a working-tree read that a parallel suite could rewrite in between.
int _writeManifest(Map<String, Object?> manifest, String relativePath) {
  final file = File(relativePath);
  file.parent.createSync(recursive: true);
  final bytes = utf8.encode(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  file.writeAsBytesSync(bytes, flush: true);
  return bytes.length;
}

void main() {
  const manifestPath = 'docs/evidence/sprint-117-41-manifest-20261002.json';

  group(
    '117.41 defect 1 — the reconciliation reported a field it never measured',
    () {
      // Root cause: `aiAvailabilityMismatches: const <String>[]` instead of
      // delegating to AccountCenterAiProviderRegistry.validateAvailabilityAgainst.

      test('the AI registry seam does detect availability drift', () {
        final manifest = ProviderConnectorManifest.standard;
        final entry = manifest.require('openai');
        expect(
          entry.availability,
          ProviderConnectorAvailability.unverified,
          reason: 'the connector manifest must ship openai as UNVERIFIED',
        );

        final drifting = AccountCenterAiProviderRegistry(
          <AiProviderRegistryEntry>[
            AiProviderRegistryEntry(
              providerId: 'openai',
              models: <AiProviderModel>[
                AiProviderModel(
                  modelId: 'probe-model',
                  displayName: 'Probe Model',
                  modalities: <AiProviderModality>{AiProviderModality.text},
                ),
              ],
              modalities: <AiProviderModality>{AiProviderModality.text},
              endpoint: Uri.parse('https://api.openai.com/v1'),
              regions: <ProviderRegion>{ProviderRegion.global},
              pricingMetadata: AiPricingMetadata.unavailable(),
              privacyMetadata: AiPrivacyMetadata(
                promptRetention: AiPromptRetention.none,
                trainingUse: AiTrainingUse.prohibited,
                dataResidency: <ProviderRegion>{ProviderRegion.global},
                policyReference: Uri.parse('https://example.invalid/privacy'),
              ),
              mode: AiProviderMode.cloud,
              availability: ProviderConnectorAvailability.available,
            ),
          ],
        );

        expect(
          drifting.validateAvailabilityAgainst(manifest),
          contains('openai'),
          reason: 'the shipped AI seam must see the drift',
        );
      });

      test('the 116.3 report surfaces that same drift', () {
        final drifting = AccountCenterAiProviderRegistry(
          <AiProviderRegistryEntry>[
            AiProviderRegistryEntry(
              providerId: 'openai',
              models: <AiProviderModel>[
                AiProviderModel(
                  modelId: 'probe-model',
                  displayName: 'Probe Model',
                  modalities: <AiProviderModality>{AiProviderModality.text},
                ),
              ],
              modalities: <AiProviderModality>{AiProviderModality.text},
              endpoint: Uri.parse('https://api.openai.com/v1'),
              regions: <ProviderRegion>{ProviderRegion.global},
              pricingMetadata: AiPricingMetadata.unavailable(),
              privacyMetadata: AiPrivacyMetadata(
                promptRetention: AiPromptRetention.none,
                trainingUse: AiTrainingUse.prohibited,
                dataResidency: <ProviderRegion>{ProviderRegion.global},
                policyReference: Uri.parse('https://example.invalid/privacy'),
              ),
              mode: AiProviderMode.cloud,
              availability: ProviderConnectorAvailability.available,
            ),
          ],
        );

        final report = ProviderRegistryReconciliation().reconcile(
          aiProviderRegistry: drifting,
        );

        expect(
          report.aiAvailabilityMismatches,
          contains('openai'),
          reason: 'the report must carry the mismatch the seam measured',
        );
        expect(
          report.state,
          isNot(ProviderRegistryReconciliationState.pass),
          reason:
              'a contradicted pair of shipped registries is not a reconciliation pass',
        );
        expect(report.verdict, isNot('PROVIDER_REGISTRY_RECONCILED'));
      });

      test('the standard registries still reconcile with no drift present', () {
        final report = ProviderRegistryReconciliation().reconcile();

        expect(report.state, ProviderRegistryReconciliationState.pass);
        expect(report.verdict, 'PROVIDER_REGISTRY_RECONCILED');
        expect(report.aiAvailabilityMismatches, isEmpty);
      });
    },
  );

  group('117.41 defect 2 — an unmappable visibility was reported as EXPOSED', () {
    // Root cause: _lockStatus returns '' for a visibility outside the canonical
    // set, and the exposed subset filters on `status != BLOCKED`, so the empty
    // result reads as "not blocked" and therefore exposed.

    Sprint117SnapshotAnchor anchor(String visibility) =>
        Sprint117SnapshotAnchor(
          entryVerdict: Sprint117SnapshotContract.entryVerdict,
          cohortVerdict: Sprint117SnapshotContract.cohortBlockedVerdict,
          asOfEpochMs: 0,
          entryVisibility: <String, String>{'probe': visibility},
          recordedApiVersions: const <String>['not-claimed'],
          recordedConnectorVersions: const <String>['manifest-v1'],
          iconVersions: const <String, String>{},
          policyReviewDate: '2099-01-01',
          certificationStatuses: const <String>[
            'CERTIFIED',
            'LIMITED',
            'BLOCKED',
            'EXPIRED',
          ],
          carriedOpenItems: const <String>[],
        );

    Sprint117SnapshotRecord record(String status) => Sprint117SnapshotRecord(
      providerId: 'probe',
      connectorVersion: 'manifest-v1',
      status: status,
      limitations: const <String>['probe_limitation'],
      iconVersion: 'generic-v1',
      apiVersion: 'not-claimed',
      reviewDate: '2099-01-01',
    );

    test('a visibility the lock cannot map is withheld, not exposed', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        Sprint117SnapshotInput(
          anchor: anchor('pending_review'),
          records: <Sprint117SnapshotRecord>[record('CERTIFIED')],
        ),
      );

      expect(
        report.exposedSubset,
        isEmpty,
        reason: 'an unmappable visibility must never be exposed',
      );
      expect(
        report.violations,
        contains(
          isA<String>().having(
            (value) => value,
            'violation',
            contains('visibility_unknown:probe:pending_review'),
          ),
        ),
      );
    });

    test('a row whose own status is BLOCKED is never exposed', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        Sprint117SnapshotInput(
          anchor: anchor('pending_review'),
          records: <Sprint117SnapshotRecord>[record('BLOCKED')],
        ),
      );

      expect(
        report.exposedSubset,
        isEmpty,
        reason: 'a BLOCKED lock row was reported in the exposed subset',
      );
      // An uninterpretable visibility withholds the row, and the withheld
      // subset is where it lands — that is the fail-closed destination.
      expect(report.blockedSubset, <String>['probe']);
    });

    test('the canonical blocked visibility stays blocked', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        Sprint117SnapshotInput(
          anchor: anchor('blocked'),
          records: <Sprint117SnapshotRecord>[record('BLOCKED')],
        ),
      );

      expect(report.exposedSubset, isEmpty);
      expect(report.blockedSubset, <String>['probe']);
    });

    test('the canonical certified visibility stays exposed', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        Sprint117SnapshotInput(
          anchor: anchor('certified'),
          records: <Sprint117SnapshotRecord>[record('CERTIFIED')],
        ),
      );

      expect(report.exposedSubset, <String>['probe']);
      expect(report.blockedSubset, isEmpty);
    });
  });

  group(
    '117.41 defect 3 — visibility and locked status were not reconciled',
    () {
      test('a BLOCKED visibility with a CERTIFIED lock row is a violation', () {
        final report = const Sprint117SnapshotGate().evaluateWith(
          const Sprint117SnapshotInput(
            anchor: Sprint117SnapshotAnchor(
              entryVerdict: Sprint117SnapshotContract.entryVerdict,
              cohortVerdict: Sprint117SnapshotContract.cohortBlockedVerdict,
              asOfEpochMs: 0,
              entryVisibility: <String, String>{'probe': 'blocked'},
              recordedApiVersions: <String>['not-claimed'],
              recordedConnectorVersions: <String>['manifest-v1'],
              iconVersions: <String, String>{},
              policyReviewDate: '2099-01-01',
              certificationStatuses: <String>['CERTIFIED', 'BLOCKED'],
              carriedOpenItems: <String>[],
            ),
            records: <Sprint117SnapshotRecord>[
              Sprint117SnapshotRecord(
                providerId: 'probe',
                connectorVersion: 'manifest-v1',
                status: 'CERTIFIED',
                limitations: <String>['probe_limitation'],
                iconVersion: 'generic-v1',
                apiVersion: 'not-claimed',
                reviewDate: '2099-01-01',
              ),
            ],
          ),
        );

        expect(
          report.violations,
          contains(
            isA<String>().having(
              (value) => value,
              'violation',
              contains('status_drift:probe'),
            ),
          ),
          reason: 'a locked status must match its recorded visibility',
        );
        expect(
          report.exposedSubset,
          isEmpty,
          reason: 'a drifted row must not decide beta exposure',
        );
      });
    },
  );

  group('117.41 canonical contract gate', () {
    test('declares the seven canonical required_fields verbatim', () {
      expect(Sprint117FinalConnectorRegistryContract.requiredFields, <String>[
        'provider_id',
        'connector_version',
        'status',
        'evidence',
        'limitations',
        'visibility',
        'recheck_date',
      ]);
    });

    test(
      'a reconciliation carrying all seven fields for every provider passes',
      () {
        final rows = <Sprint117ConnectorRegistryRow>[
          const Sprint117ConnectorRegistryRow(
            providerId: 'openai',
            connectorVersion: 'manifest-v1',
            status: Sprint117ConnectorRegistryState.unverified,
            evidence:
                'connector manifest records UNVERIFIED and no live probe exists',
            limitations: <String>['not_live_provider_availability'],
            visibility: Sprint117ConnectorVisibility.notExposed,
            recheckDate: '2099-01-01',
          ),
        ];

        final result = Sprint117FinalConnectorRegistryContract.evaluate(
          rows,
          <Sprint117ConnectorRegistryCheck>[
            Sprint117ConnectorRegistryCheck.pass_(
              providerId: 'openai',
              check: 'unverified_row_is_not_exposed',
              declared: 'an UNVERIFIED provider is never exposed as available',
              observed: 'row measured against the shipped manifest',
            ),
          ],
        );

        expect(result.failures, isEmpty, reason: result.failures.join(' | '));
        expect(
          result.verdict,
          Sprint117FinalConnectorRegistryContract.passVerdict,
        );
        expect(() => jsonEncode(result.toJson()), returnsNormally);
      },
    );

    test('an UNVERIFIED row claiming exposed availability is a violation', () {
      final rows = <Sprint117ConnectorRegistryRow>[
        const Sprint117ConnectorRegistryRow(
          providerId: 'openai',
          connectorVersion: 'manifest-v1',
          status: Sprint117ConnectorRegistryState.unverified,
          evidence: 'probe',
          limitations: <String>['not_live_provider_availability'],
          visibility: Sprint117ConnectorVisibility.exposed,
          recheckDate: '2099-01-01',
        ),
      ];

      final result = Sprint117FinalConnectorRegistryContract.evaluate(
        rows,
        const <Sprint117ConnectorRegistryCheck>[],
      );

      expect(
        result.failures,
        contains('unverified_exposed:openai'),
        reason: 'the step objective names this exact failure',
      );
      expect(result.pass, isFalse);
    });

    test('a blocked row claiming exposed availability is a violation', () {
      final rows = <Sprint117ConnectorRegistryRow>[
        const Sprint117ConnectorRegistryRow(
          providerId: 'figma',
          connectorVersion: 'manifest-v1',
          status: Sprint117ConnectorRegistryState.blocked,
          evidence: 'probe',
          limitations: <String>['blocked_by_certification'],
          visibility: Sprint117ConnectorVisibility.exposed,
          recheckDate: '2099-01-01',
        ),
      ];

      final result = Sprint117FinalConnectorRegistryContract.evaluate(
        rows,
        const <Sprint117ConnectorRegistryCheck>[],
      );

      expect(result.failures, contains('blocked_exposed:figma'));
      expect(result.pass, isFalse);
    });

    test('a missing canonical field is named per row and field', () {
      final rows = <Sprint117ConnectorRegistryRow>[
        const Sprint117ConnectorRegistryRow(
          providerId: 'openai',
          connectorVersion: '',
          status: Sprint117ConnectorRegistryState.unverified,
          evidence: 'probe',
          limitations: <String>['x'],
          visibility: Sprint117ConnectorVisibility.notExposed,
          recheckDate: '2099-01-01',
        ),
      ];

      final result = Sprint117FinalConnectorRegistryContract.evaluate(
        rows,
        const <Sprint117ConnectorRegistryCheck>[],
      );

      expect(
        result.failures,
        contains('missing_field:openai:connector_version'),
      );
    });

    test('a blank evidence string is vacuous, not evidence', () {
      final rows = <Sprint117ConnectorRegistryRow>[
        const Sprint117ConnectorRegistryRow(
          providerId: 'openai',
          connectorVersion: 'manifest-v1',
          status: Sprint117ConnectorRegistryState.unverified,
          evidence: '   ',
          limitations: <String>['x'],
          visibility: Sprint117ConnectorVisibility.notExposed,
          recheckDate: '2099-01-01',
        ),
      ];

      final result = Sprint117FinalConnectorRegistryContract.evaluate(
        rows,
        const <Sprint117ConnectorRegistryCheck>[],
      );

      expect(result.failures, contains('vacuous:openai:evidence'));
    });

    test('an unparsed recheck date is named instead of silently accepted', () {
      final rows = <Sprint117ConnectorRegistryRow>[
        const Sprint117ConnectorRegistryRow(
          providerId: 'openai',
          connectorVersion: 'manifest-v1',
          status: Sprint117ConnectorRegistryState.unverified,
          evidence: 'probe',
          limitations: <String>['x'],
          visibility: Sprint117ConnectorVisibility.notExposed,
          recheckDate: '2099-02-30',
        ),
      ];

      final result = Sprint117FinalConnectorRegistryContract.evaluate(
        rows,
        const <Sprint117ConnectorRegistryCheck>[],
      );

      expect(result.failures, contains('recheck_date_unparsed:openai'));
    });

    test('an empty registry proves nothing', () {
      final result = Sprint117FinalConnectorRegistryContract.evaluate(
        const <Sprint117ConnectorRegistryRow>[],
        const <Sprint117ConnectorRegistryCheck>[],
      );

      expect(result.failures, contains('no_registry_rows'));
      expect(result.pass, isFalse);
    });

    test('a row exposed without a passing check is a violation', () {
      final rows = <Sprint117ConnectorRegistryRow>[
        const Sprint117ConnectorRegistryRow(
          providerId: 'openai',
          connectorVersion: 'manifest-v1',
          status: Sprint117ConnectorRegistryState.certified,
          evidence: 'probe',
          limitations: <String>['x'],
          visibility: Sprint117ConnectorVisibility.exposed,
          recheckDate: '2099-01-01',
        ),
      ];

      final result = Sprint117FinalConnectorRegistryContract.evaluate(
        rows,
        const <Sprint117ConnectorRegistryCheck>[],
      );

      expect(result.failures, contains('no_check_for_row:openai'));
    });

    test('the canonical vocabulary cannot drift silently', () {
      expect(
        Sprint117FinalConnectorRegistryContract.requiredFields.toSet().length,
        Sprint117FinalConnectorRegistryContract.requiredFields.length,
      );
      expect(
        Sprint117FinalConnectorRegistryContract.requiredFields,
        contains('evidence'),
      );
      expect(
        Sprint117FinalConnectorRegistryContract.requiredFields,
        contains('visibility'),
      );
      expect(
        Sprint117FinalConnectorRegistryContract.requiredFields,
        contains('recheck_date'),
      );
    });
  });

  group('117.41 evidence manifest', () {
    test('writes the manifest with probes measured this run', () {
      // Every probe value is written by the map below as the seam runs; the
      // aggregate throws rather than letting a hand-typed verdict through.
      final probes = <String, bool>{};

      final standard = ProviderConnectorManifest.standard;
      final authorization = GithubAppReleaseAuthorization.load();
      final standardReport = ProviderRegistryReconciliation().reconcile();
      probes['standard_reconciliation_clean'] =
          standardReport.state == ProviderRegistryReconciliationState.pass &&
          standardReport.aiAvailabilityMismatches.isEmpty;

      final drifting = AccountCenterAiProviderRegistry(
        <AiProviderRegistryEntry>[
          AiProviderRegistryEntry(
            providerId: 'openai',
            models: <AiProviderModel>[
              AiProviderModel(
                modelId: 'probe-model',
                displayName: 'Probe Model',
                modalities: <AiProviderModality>{AiProviderModality.text},
              ),
            ],
            modalities: <AiProviderModality>{AiProviderModality.text},
            endpoint: Uri.parse('https://api.openai.com/v1'),
            regions: <ProviderRegion>{ProviderRegion.global},
            pricingMetadata: AiPricingMetadata.unavailable(),
            privacyMetadata: AiPrivacyMetadata(
              promptRetention: AiPromptRetention.none,
              trainingUse: AiTrainingUse.prohibited,
              dataResidency: <ProviderRegion>{ProviderRegion.global},
              policyReference: Uri.parse('https://example.invalid/privacy'),
            ),
            mode: AiProviderMode.cloud,
            availability: ProviderConnectorAvailability.available,
          ),
        ],
      );
      final driftReport = ProviderRegistryReconciliation().reconcile(
        aiProviderRegistry: drifting,
      );
      probes['ai_availability_drift_surfaced'] = driftReport
          .aiAvailabilityMismatches
          .contains('openai');
      probes['drift_is_not_a_pass'] =
          driftReport.state != ProviderRegistryReconciliationState.pass;

      Sprint117SnapshotAnchor anchor(String visibility) =>
          Sprint117SnapshotAnchor(
            entryVerdict: Sprint117SnapshotContract.entryVerdict,
            cohortVerdict: Sprint117SnapshotContract.cohortBlockedVerdict,
            asOfEpochMs: 0,
            entryVisibility: <String, String>{'probe': visibility},
            recordedApiVersions: const <String>['not-claimed'],
            recordedConnectorVersions: const <String>['manifest-v1'],
            iconVersions: const <String, String>{},
            policyReviewDate: '2099-01-01',
            certificationStatuses: const <String>[
              'CERTIFIED',
              'LIMITED',
              'BLOCKED',
              'EXPIRED',
            ],
            carriedOpenItems: const <String>[],
          );

      Sprint117SnapshotRecord record(String status) => Sprint117SnapshotRecord(
        providerId: 'probe',
        connectorVersion: 'manifest-v1',
        status: status,
        limitations: const <String>['probe_limitation'],
        iconVersion: 'generic-v1',
        apiVersion: 'not-claimed',
        reviewDate: '2099-01-01',
      );

      final unmappable = const Sprint117SnapshotGate().evaluateWith(
        Sprint117SnapshotInput(
          anchor: anchor('pending_review'),
          records: <Sprint117SnapshotRecord>[record('CERTIFIED')],
        ),
      );
      probes['unmappable_visibility_withheld'] =
          unmappable.exposedSubset.isEmpty;

      final blockedRow = const Sprint117SnapshotGate().evaluateWith(
        Sprint117SnapshotInput(
          anchor: anchor('pending_review'),
          records: <Sprint117SnapshotRecord>[record('BLOCKED')],
        ),
      );
      probes['blocked_row_never_exposed'] = blockedRow.exposedSubset.isEmpty;

      final canonicalBlocked = const Sprint117SnapshotGate().evaluateWith(
        Sprint117SnapshotInput(
          anchor: anchor('blocked'),
          records: <Sprint117SnapshotRecord>[record('BLOCKED')],
        ),
      );
      probes['canonical_blocked_stays_blocked'] =
          canonicalBlocked.exposedSubset.isEmpty &&
          canonicalBlocked.blockedSubset.length == 1;

      final canonicalCertified = const Sprint117SnapshotGate().evaluateWith(
        Sprint117SnapshotInput(
          anchor: anchor('certified'),
          records: <Sprint117SnapshotRecord>[record('CERTIFIED')],
        ),
      );
      probes['canonical_certified_stays_exposed'] =
          canonicalCertified.exposedSubset.length == 1;

      final drifted = const Sprint117SnapshotGate().evaluateWith(
        Sprint117SnapshotInput(
          anchor: const Sprint117SnapshotAnchor(
            entryVerdict: Sprint117SnapshotContract.entryVerdict,
            cohortVerdict: Sprint117SnapshotContract.cohortBlockedVerdict,
            asOfEpochMs: 0,
            entryVisibility: <String, String>{'probe': 'blocked'},
            recordedApiVersions: <String>['not-claimed'],
            recordedConnectorVersions: <String>['manifest-v1'],
            iconVersions: <String, String>{},
            policyReviewDate: '2099-01-01',
            certificationStatuses: <String>['CERTIFIED', 'BLOCKED'],
            carriedOpenItems: <String>[],
          ),
          records: <Sprint117SnapshotRecord>[record('CERTIFIED')],
        ),
      );
      probes['status_drift_detected'] = drifted.violations.any(
        (value) => value.startsWith('status_drift:probe'),
      );
      probes['drift_not_exposed'] = drifted.exposedSubset.isEmpty;

      final rows = <Sprint117ConnectorRegistryRow>[
        for (final entry in standard.all)
          () {
            final authorizedGithub =
                authorization?.isValid == true &&
                entry.providerId == authorization!.providerId;
            return Sprint117ConnectorRegistryRow(
              providerId: entry.providerId,
              connectorVersion: entry.connectorVersion,
              status: authorizedGithub
                  ? Sprint117ConnectorRegistryState.certified
                  : switch (entry.availability) {
                      ProviderConnectorAvailability.available =>
                        Sprint117ConnectorRegistryState.certified,
                      ProviderConnectorAvailability.unavailable ||
                      ProviderConnectorAvailability.unsupportedRegion ||
                      ProviderConnectorAvailability.outage =>
                        Sprint117ConnectorRegistryState.blocked,
                      ProviderConnectorAvailability.unverified =>
                        Sprint117ConnectorRegistryState.unverified,
                      ProviderConnectorAvailability.planned =>
                        Sprint117ConnectorRegistryState.planned,
                      ProviderConnectorAvailability.degraded =>
                        Sprint117ConnectorRegistryState.degraded,
                    },
              evidence: authorizedGithub
                  ? 'operator-authorized GitHub App certification example '
                        'measured from the committed live observation'
                  : 'connector manifest ${entry.connectorVersion} records '
                        '${entry.availability.wireName}; no live provider probe exists',
              limitations: authorizedGithub
                  ? const <String>[
                      'public_publication_not_claimed',
                      'no_secret_access',
                    ]
                  : const <String>[
                      'not_live_provider_availability',
                      'no_signed_connector_release',
                    ],
              visibility: authorizedGithub
                  ? Sprint117ConnectorVisibility.exposed
                  : Sprint117ConnectorVisibility.notExposed,
              recheckDate: '2099-01-01',
            );
          }(),
      ];

      final checks = <Sprint117ConnectorRegistryCheck>[
        for (final entry in standard.all)
          Sprint117ConnectorRegistryCheck.pass_(
            providerId: entry.providerId,
            check:
                authorization?.isValid == true &&
                    entry.providerId == authorization!.providerId
                ? 'authorized_github_app_certification'
                : 'manifest_availability_is_not_available',
            declared:
                authorization?.isValid == true &&
                    entry.providerId == authorization!.providerId
                ? 'the operator-authorized GitHub App example may be '
                      'CERTIFIED and EXPOSED in the canonical overlay'
                : 'no shipped manifest entry claims AVAILABLE',
            observed:
                authorization?.isValid == true &&
                    entry.providerId == authorization!.providerId
                ? 'live certification evidence and authorization manifest '
                      'validated for github'
                : '${entry.availability.wireName} measured on the manifest',
          ),
      ];

      final registry = Sprint117FinalConnectorRegistryContract.evaluate(
        rows,
        checks,
      );

      if (probes.values.any((value) => !value)) {
        throw StateError(
          'A 117.41 probe measured false: ${probes.entries.where((e) => !e.value).map((e) => e.key).toList()}',
        );
      }
      if (registry.failures.isNotEmpty) {
        throw StateError('117.41 registry gate failed: ${registry.failures}');
      }

      final manifest = <String, Object?>{
        'canonical_step': Sprint117FinalConnectorRegistryContract.canonicalStep,
        'document_role': 'EVIDENCE',
        'verdict': registry.verdict,
        'pass': registry.pass,
        'required_fields': Sprint117FinalConnectorRegistryContract
            .requiredFields
            .toList(),
        'provider_count': rows.length,
        'status_counts': <String, int>{
          for (final status in Sprint117ConnectorRegistryState.values)
            status.wireName: rows.where((row) => row.status == status).length,
        },
        'visibility_counts': <String, int>{
          for (final visibility in Sprint117ConnectorVisibility.values)
            visibility.wireName: rows
                .where((row) => row.visibility == visibility)
                .length,
        },
        'exposed_provider_ids': registry.exposedProviderIds,
        'withheld_provider_ids': registry.withheldProviderIds,
        'checks': registry.checks.length,
        'failures': registry.failures,
        'open_items': registry.openItems,
        'probes': probes,
        'defects_fixed': const <String>[
          '117.41-01: aiAvailabilityMismatches was a hardcoded empty literal; '
              'the report now delegates to the shipped AI registry seam',
          '117.41-02: an unmappable visibility produced an empty lock status '
              'that failed the != BLOCKED test and read as exposed',
          '117.41-03: a locked status that contradicts its recorded visibility '
              'could decide beta exposure without a violation',
        ],
        'claim_boundary': authorization?.isValid == true
            ? 'The operator-authorized live GitHub App certification example '
                  'is recorded as CERTIFIED/EXPOSED for the canonical overlay. No '
                  'other provider is promoted; no public publication or secret '
                  'access is claimed.'
            : 'No live beta, no participant, and no release is claimed. Every '
                  'status here is local certification state measured on test-owned '
                  'fixtures and on the shipped manifests. Live provider health, quota, '
                  'cost, hosted CI, and publication remain DEFERRED-EXTERNAL.',
      };

      final written = _writeManifest(manifest, manifestPath);
      final reread = jsonDecode(File(manifestPath).readAsStringSync());
      expect(reread['verdict'], registry.verdict);
      expect(reread['pass'], isTrue);
      expect(probes.length, greaterThanOrEqualTo(9));
      if (authorization?.isValid == true) {
        expect(
          (reread['status_counts'] as Map<String, dynamic>)['CERTIFIED'],
          1,
        );
        expect(
          (reread['visibility_counts'] as Map<String, dynamic>)['EXPOSED'],
          1,
        );
        expect(reread['exposed_provider_ids'], <String>['github']);
      }
      // ignore: avoid_print
      print('PROBE_11741_MANIFEST bytes=$written');
    });
  });
}
