import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/maintenance_artifact_release_gate_v114.dart';

void main() {
  group('114.40 Maintenance Artifact & Release Gate', () {
    MaintenanceArtifactReleaseEvidence noPatchEvidence() {
      return const MaintenanceArtifactReleaseEvidence(
        disposition: MaintenanceArtifactReleaseDisposition.noPatch,
        evidence: <MaintenanceArtifactEvidenceItem>[
          MaintenanceArtifactEvidenceItem(
            key: 'approved_scope_or_no_patch',
            status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
            source:
                'docs/planning/v1.2/sprint_114_maintenance_release_scope.json',
          ),
          MaintenanceArtifactEvidenceItem(
            key: 'signed_artifact_if_needed',
            status: MaintenanceArtifactEvidenceStatus.notApplicable,
            source: 'NO_PATCH',
          ),
          MaintenanceArtifactEvidenceItem(
            key: 'test_results',
            status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
            source: 'current_slice_local_gates',
          ),
          MaintenanceArtifactEvidenceItem(
            key: 'upgrade_results',
            status: MaintenanceArtifactEvidenceStatus.notApplicable,
            source: 'NO_PATCH',
          ),
          MaintenanceArtifactEvidenceItem(
            key: 'rollback_results',
            status: MaintenanceArtifactEvidenceStatus.notApplicable,
            source: 'NO_PATCH',
          ),
          MaintenanceArtifactEvidenceItem(
            key: 'checksums',
            status: MaintenanceArtifactEvidenceStatus.notApplicable,
            source: 'NO_PATCH',
          ),
          MaintenanceArtifactEvidenceItem(
            key: 'release_notes',
            status: MaintenanceArtifactEvidenceStatus.notApplicable,
            source: 'NO_PATCH',
          ),
        ],
      );
    }

    test('declares the canonical evidence boundary', () {
      expect(MaintenanceArtifactReleaseContract.canonicalStep, '114.40');
      expect(MaintenanceArtifactReleaseContract.requiredEvidence, <String>[
        'approved_scope_or_no_patch',
        'signed_artifact_if_needed',
        'test_results',
        'upgrade_results',
        'rollback_results',
        'checksums',
        'release_notes',
      ]);
      expect(
        MaintenanceArtifactReleaseContract.deferredExternalChecks,
        containsAll(<String>[
          'public_release_signing',
          'hosted_ci_validation',
          'published_artifact_validation',
          'release_notes_publication',
          'publication',
        ]),
      );
    });

    test(
      'absent release evidence is blocked without inventing an artifact',
      () {
        final report = MaintenanceArtifactReleaseGate().evaluate(null);

        expect(report.state, MaintenanceArtifactReleaseState.blocked);
        expect(report.disposition, isNull);
        expect(
          report.missingEvidence,
          MaintenanceArtifactReleaseContract.requiredEvidence,
        );
        expect(report.violations, isEmpty);
        expect(report.toJson()['external_gates'], 'DEFERRED-EXTERNAL');
      },
    );

    test(
      'complete NO_PATCH evidence closes local scope without release claims',
      () {
        final report = MaintenanceArtifactReleaseGate().evaluate(
          noPatchEvidence(),
        );

        expect(report.state, MaintenanceArtifactReleaseState.pass);
        expect(
          report.disposition,
          MaintenanceArtifactReleaseDisposition.noPatch,
        );
        expect(report.missingEvidence, isEmpty);
        expect(report.violations, isEmpty);
        expect(report.artifactRequired, isFalse);
        expect(report.externalGates, 'DEFERRED-EXTERNAL');
      },
    );

    test(
      'NO_PATCH requires a verified 114.39 decision and local test evidence',
      () {
        final report = MaintenanceArtifactReleaseGate().evaluate(
          const MaintenanceArtifactReleaseEvidence(
            disposition: MaintenanceArtifactReleaseDisposition.noPatch,
            evidence: <MaintenanceArtifactEvidenceItem>[
              MaintenanceArtifactEvidenceItem(
                key: 'approved_scope_or_no_patch',
                status: MaintenanceArtifactEvidenceStatus.notApplicable,
                source: 'NO_PATCH',
              ),
              MaintenanceArtifactEvidenceItem(
                key: 'signed_artifact_if_needed',
                status: MaintenanceArtifactEvidenceStatus.notApplicable,
                source: 'NO_PATCH',
              ),
              MaintenanceArtifactEvidenceItem(
                key: 'test_results',
                status: MaintenanceArtifactEvidenceStatus.notApplicable,
                source: 'NO_PATCH',
              ),
              MaintenanceArtifactEvidenceItem(
                key: 'upgrade_results',
                status: MaintenanceArtifactEvidenceStatus.notApplicable,
                source: 'NO_PATCH',
              ),
              MaintenanceArtifactEvidenceItem(
                key: 'rollback_results',
                status: MaintenanceArtifactEvidenceStatus.notApplicable,
                source: 'NO_PATCH',
              ),
              MaintenanceArtifactEvidenceItem(
                key: 'checksums',
                status: MaintenanceArtifactEvidenceStatus.notApplicable,
                source: 'NO_PATCH',
              ),
              MaintenanceArtifactEvidenceItem(
                key: 'release_notes',
                status: MaintenanceArtifactEvidenceStatus.notApplicable,
                source: 'NO_PATCH',
              ),
            ],
          ),
        );

        expect(report.state, MaintenanceArtifactReleaseState.fail);
        expect(
          report.violations,
          containsAll(<String>[
            'approved_scope_or_no_patch_requires_verified_local_source',
            'test_results_requires_verified_local_source',
          ]),
        );
      },
    );

    test('NO_PATCH cannot claim an artifact or artifact-only validation', () {
      final evidence = noPatchEvidence();
      final report = MaintenanceArtifactReleaseGate().evaluate(
        MaintenanceArtifactReleaseEvidence(
          disposition: evidence.disposition,
          evidence: <MaintenanceArtifactEvidenceItem>[
            for (final item in evidence.evidence)
              if (item.key == 'signed_artifact_if_needed' ||
                  item.key == 'checksums')
                MaintenanceArtifactEvidenceItem(
                  key: item.key,
                  status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
                  source: 'unexpected_artifact_claim',
                )
              else
                item,
          ],
        ),
      );

      expect(report.state, MaintenanceArtifactReleaseState.fail);
      expect(report.violations, contains('no_patch_with_artifact_evidence'));
    });

    test('BUILD_1_2_1 requires every artifact gate verified locally', () {
      final report = MaintenanceArtifactReleaseGate().evaluate(
        const MaintenanceArtifactReleaseEvidence(
          disposition: MaintenanceArtifactReleaseDisposition.build121,
          evidence: <MaintenanceArtifactEvidenceItem>[
            MaintenanceArtifactEvidenceItem(
              key: 'approved_scope_or_no_patch',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source:
                  'docs/planning/v1.2/sprint_114_maintenance_release_scope.json',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'signed_artifact_if_needed',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'local_candidate_signature',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'test_results',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'current_slice_local_gates',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'upgrade_results',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'local_upgrade_drill',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'rollback_results',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'local_rollback_drill',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'checksums',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'docs/release/v1.2.1-checksums.txt',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'release_notes',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'docs/release/v1.2.1-release-notes.md',
            ),
          ],
        ),
      );

      expect(report.state, MaintenanceArtifactReleaseState.pass);
      expect(
        report.disposition,
        MaintenanceArtifactReleaseDisposition.build121,
      );
      expect(report.artifactRequired, isTrue);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing, duplicate, and unknown evidence fail closed', () {
      final report = MaintenanceArtifactReleaseGate().evaluate(
        const MaintenanceArtifactReleaseEvidence(
          disposition: MaintenanceArtifactReleaseDisposition.build121,
          evidence: <MaintenanceArtifactEvidenceItem>[
            MaintenanceArtifactEvidenceItem(
              key: 'approved_scope_or_no_patch',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'scope',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'approved_scope_or_no_patch',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'duplicate',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'unknown_evidence',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'unknown',
            ),
          ],
        ),
      );

      expect(report.state, MaintenanceArtifactReleaseState.blocked);
      expect(report.missingEvidence, isNotEmpty);
      expect(
        report.violations,
        containsAll(<String>[
          'evidence_1_duplicate_approved_scope_or_no_patch',
          'evidence_2_unknown_unknown_evidence',
        ]),
      );
    });

    test('failed or blocked artifact evidence cannot pass', () {
      final blocked = MaintenanceArtifactReleaseGate().evaluate(
        const MaintenanceArtifactReleaseEvidence(
          disposition: MaintenanceArtifactReleaseDisposition.build121,
          evidence: <MaintenanceArtifactEvidenceItem>[
            MaintenanceArtifactEvidenceItem(
              key: 'approved_scope_or_no_patch',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'scope',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'signed_artifact_if_needed',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'signature',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'test_results',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'tests',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'upgrade_results',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'upgrade',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'rollback_results',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'rollback',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'checksums',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'checksums',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'release_notes',
              status: MaintenanceArtifactEvidenceStatus.failed,
              source: 'release-notes',
            ),
          ],
        ),
      );

      expect(blocked.state, MaintenanceArtifactReleaseState.fail);
      expect(blocked.violations, contains('evidence_6_release_notes_failed'));
    });

    test('blank source and N/A under BUILD_1_2_1 are violations', () {
      final report = MaintenanceArtifactReleaseGate().evaluate(
        const MaintenanceArtifactReleaseEvidence(
          disposition: MaintenanceArtifactReleaseDisposition.build121,
          evidence: <MaintenanceArtifactEvidenceItem>[
            MaintenanceArtifactEvidenceItem(
              key: 'approved_scope_or_no_patch',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'scope',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'signed_artifact_if_needed',
              status: MaintenanceArtifactEvidenceStatus.notApplicable,
              source: ' ',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'test_results',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'tests',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'upgrade_results',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'upgrade',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'rollback_results',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'rollback',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'checksums',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'checksums',
            ),
            MaintenanceArtifactEvidenceItem(
              key: 'release_notes',
              status: MaintenanceArtifactEvidenceStatus.verifiedLocal,
              source: 'notes',
            ),
          ],
        ),
      );

      expect(report.state, MaintenanceArtifactReleaseState.fail);
      expect(
        report.violations,
        containsAll(<String>[
          'evidence_1_signed_artifact_if_needed_notApplicable',
          'evidence_1_signed_artifact_if_needed_missing_source',
        ]),
      );
    });

    test(
      'manifest records the live NO_PATCH decision and external boundary',
      () {
        final file = File(MaintenanceArtifactReleaseContract.manifestPath);
        expect(file.existsSync(), isTrue);
        final manifest =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

        expect(manifest['canonical_step'], '114.40');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['disposition'], 'NO_PATCH');
        expect(manifest['artifact_required'], isFalse);
        expect(manifest['artifact_path'], isNull);
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        final evidence = manifest['evidence'] as Map<String, dynamic>;
        expect(
          evidence.keys,
          containsAll(<String>['approved_scope_or_no_patch']),
        );
        expect(evidence['approved_scope_or_no_patch'], 'verified_local');
        expect(evidence['test_results'], 'verified_local');
        expect(
          evidence.values,
          containsAll(<String>['not_applicable_no_patch']),
        );
        expect(manifest['limitations'], isNotEmpty);
      },
    );
  });
}
