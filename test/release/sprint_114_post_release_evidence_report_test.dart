import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/post_release_evidence_report_v114.dart';

void main() {
  group('114.41 Post-Release Evidence Report', () {
    const sections = <String, PostReleaseEvidenceSection>{
      'release_state': PostReleaseEvidenceSection(
        status: PostReleaseEvidenceStatus.verifiedLocal,
        evidence: <String>[
          'docs/planning/v1.2/sprint_114_post_release_entry_gate.json',
        ],
        summary: 'Canonical path is DELAYED; no public GA is claimed.',
      ),
      'health': PostReleaseEvidenceSection(
        status: PostReleaseEvidenceStatus.deferredExternal,
        evidence: <String>[
          'docs/planning/v1.2/sprint_114_stable_release_health_gate.json',
        ],
        summary: 'Local contract is green; production health is not observed.',
      ),
      'incidents': PostReleaseEvidenceSection(
        status: PostReleaseEvidenceStatus.deferredExternal,
        evidence: <String>[
          'docs/planning/v1.2/sprint_114_incident_queue_intake.json',
        ],
        summary: 'No public incident channel is active.',
      ),
      'adoption_evidence': PostReleaseEvidenceSection(
        status: PostReleaseEvidenceStatus.deferredExternal,
        evidence: <String>[
          'docs/planning/v1.2/sprint_114_feedback_adoption_evidence_intake.json',
        ],
        summary: 'No external adoption dataset is available.',
      ),
      'limitations': PostReleaseEvidenceSection(
        status: PostReleaseEvidenceStatus.verifiedLocal,
        evidence: <String>[
          'docs/planning/v1.2/sprint_114_post_release_entry_gate.json',
        ],
        summary: 'Local reports cannot stand in for production evidence.',
      ),
      'fixes': PostReleaseEvidenceSection(
        status: PostReleaseEvidenceStatus.verifiedLocal,
        evidence: <String>[
          'docs/planning/v1.2/sprint_114_maintenance_release_scope.json',
        ],
        summary: 'Approved maintenance patch scope is empty.',
      ),
      'rollout': PostReleaseEvidenceSection(
        status: PostReleaseEvidenceStatus.deferredExternal,
        evidence: <String>[
          'docs/planning/v1.2/sprint_114_rollout_stage_verification.json',
        ],
        summary: 'Rollout remains not started.',
      ),
      'patch_decision': PostReleaseEvidenceSection(
        status: PostReleaseEvidenceStatus.verifiedLocal,
        evidence: <String>[
          'docs/planning/v1.2/sprint_114_maintenance_artifact_release_gate.json',
        ],
        summary: 'Maintenance disposition is NO_PATCH.',
      ),
    };

    test('declares the eight canonical sections in roadmap order', () {
      expect(PostReleaseEvidenceReportContract.canonicalStep, '114.41');
      expect(PostReleaseEvidenceReportContract.requiredSections, <String>[
        'release_state',
        'health',
        'incidents',
        'adoption_evidence',
        'limitations',
        'fixes',
        'rollout',
        'patch_decision',
      ]);
      expect(
        PostReleaseEvidenceReportContract.manifestPath,
        endsWith('sprint_114_post_release_evidence_report.json'),
      );
    });

    test('absent report is blocked and names every missing section', () {
      final report = PostReleaseEvidenceReportGate().evaluate(null);

      expect(report.state, PostReleaseEvidenceReportState.blocked);
      expect(
        report.missingSections,
        PostReleaseEvidenceReportContract.requiredSections,
      );
      expect(report.violations, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('complete delayed-path report passes without inventing live data', () {
      final report = PostReleaseEvidenceReportGate().evaluate(
        PostReleaseEvidenceReportDraft(
          releaseState: 'DELAYED',
          sections: sections,
        ),
      );

      expect(report.state, PostReleaseEvidenceReportState.pass);
      expect(report.releaseState, 'DELAYED');
      expect(report.missingSections, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing, duplicate, and unknown sections fail closed', () {
      final report = PostReleaseEvidenceReportGate().evaluate(
        PostReleaseEvidenceReportDraft(
          releaseState: 'DELAYED',
          sections: <String, PostReleaseEvidenceSection>{
            ...sections,
            'release_state': sections['release_state']!,
            'unknown': const PostReleaseEvidenceSection(
              status: PostReleaseEvidenceStatus.verifiedLocal,
              evidence: <String>['unknown.json'],
              summary: 'Unexpected section.',
            ),
          },
          sectionNames: <String>['release_state', 'release_state', 'unknown'],
        ),
      );

      expect(report.state, PostReleaseEvidenceReportState.fail);
      expect(
        report.violations,
        containsAll(<String>['duplicate_release_state', 'unknown_unknown']),
      );
    });

    test('blank summaries, evidence, and unsupported status fail', () {
      final report = PostReleaseEvidenceReportGate().evaluate(
        PostReleaseEvidenceReportDraft(
          releaseState: 'DELAYED',
          sections: <String, PostReleaseEvidenceSection>{
            'release_state': const PostReleaseEvidenceSection(
              status: PostReleaseEvidenceStatus.deferredExternal,
              evidence: <String>[' '],
              summary: ' ',
            ),
            'health': const PostReleaseEvidenceSection(
              status: PostReleaseEvidenceStatus.verifiedLocal,
              evidence: <String>['health.json'],
              summary: 'Production health invented.',
            ),
          },
        ),
      );

      expect(report.state, PostReleaseEvidenceReportState.blocked);
      expect(
        report.missingSections,
        containsAll(<String>['incidents', 'adoption_evidence', 'fixes']),
      );
      expect(
        report.violations,
        containsAll(<String>[
          'release_state_evidence_missing',
          'release_state_summary_missing',
          'release_state_deferred_external_requires_evidence',
          'delayed_release_cannot_verify_health',
        ]),
      );
    });

    test(
      'delayed report cannot present live health, incidents, or adoption',
      () {
        final report = PostReleaseEvidenceReportGate().evaluate(
          PostReleaseEvidenceReportDraft(
            releaseState: 'DELAYED',
            sections: <String, PostReleaseEvidenceSection>{
              ...sections,
              'health': const PostReleaseEvidenceSection(
                status: PostReleaseEvidenceStatus.verifiedLocal,
                evidence: <String>['fabricated-production-health.json'],
                summary: 'Production health is healthy.',
              ),
              'incidents': const PostReleaseEvidenceSection(
                status: PostReleaseEvidenceStatus.verifiedLocal,
                evidence: <String>['fabricated-incident.json'],
                summary: 'No production incidents occurred.',
              ),
              'adoption_evidence': const PostReleaseEvidenceSection(
                status: PostReleaseEvidenceStatus.verifiedLocal,
                evidence: <String>['fabricated-adoption.json'],
                summary: 'Adoption succeeded.',
              ),
            },
          ),
        );

        expect(report.state, PostReleaseEvidenceReportState.fail);
        expect(
          report.violations,
          containsAll(<String>[
            'delayed_release_cannot_verify_health',
            'delayed_release_cannot_verify_incidents',
            'delayed_release_cannot_verify_adoption_evidence',
          ]),
        );
      },
    );

    test('released report requires a local health and incident source', () {
      final released = <String, PostReleaseEvidenceSection>{
        for (final entry in sections.entries)
          entry.key: entry.key == 'release_state'
              ? const PostReleaseEvidenceSection(
                  status: PostReleaseEvidenceStatus.verifiedLocal,
                  evidence: <String>['published-release.json'],
                  summary: 'Release state is RELEASED.',
                )
              : entry.value,
        'health': const PostReleaseEvidenceSection(
          status: PostReleaseEvidenceStatus.verifiedLocal,
          evidence: <String>['production-health.json'],
          summary: 'Production health window is complete.',
        ),
        'incidents': const PostReleaseEvidenceSection(
          status: PostReleaseEvidenceStatus.verifiedLocal,
          evidence: <String>['production-incidents.json'],
          summary: 'Incident queue is complete for the observation window.',
        ),
        'adoption_evidence': const PostReleaseEvidenceSection(
          status: PostReleaseEvidenceStatus.verifiedLocal,
          evidence: <String>['consented-adoption.json'],
          summary: 'Consented adoption evidence is attached.',
        ),
      };

      final report = PostReleaseEvidenceReportGate().evaluate(
        PostReleaseEvidenceReportDraft(
          releaseState: 'RELEASED',
          sections: released,
        ),
      );

      expect(report.state, PostReleaseEvidenceReportState.pass);
    });

    test('patch decision cannot be silent or omitted', () {
      final report = PostReleaseEvidenceReportGate().evaluate(
        PostReleaseEvidenceReportDraft(
          releaseState: 'DELAYED',
          sections: <String, PostReleaseEvidenceSection>{
            ...sections,
            'patch_decision': sections['patch_decision']!.copyWith(
              summary: ' ',
            ),
          },
        ),
      );

      expect(report.state, PostReleaseEvidenceReportState.fail);
      expect(report.violations, contains('patch_decision_summary_missing'));
    });

    test(
      'manifest records the delayed report and external evidence boundary',
      () {
        final file = File(PostReleaseEvidenceReportContract.manifestPath);
        expect(file.existsSync(), isTrue);
        final manifest =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

        expect(manifest['canonical_step'], '114.41');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['release_state'], 'DELAYED');
        expect(
          manifest['required_sections'],
          PostReleaseEvidenceReportContract.requiredSections,
        );
        final report = manifest['report'] as Map<String, dynamic>;
        expect(
          report.keys.toSet(),
          PostReleaseEvidenceReportContract.requiredSections.toSet(),
        );
        for (final section
            in PostReleaseEvidenceReportContract.requiredSections) {
          final value = report[section] as Map<String, dynamic>;
          expect(value['status'], isA<String>());
          expect(value['evidence'], isA<List<dynamic>>());
          expect((value['summary'] as String).trim(), isNotEmpty);
        }
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        expect(manifest['limitations'], isNotEmpty);
      },
    );
  });
}
