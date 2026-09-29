import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_beta_cohort_consent_plan.dart';

const int _now = 1700000100000;
const int _base = _now - 604800000;
const String _manifestArtifact =
    'docs/planning/v1.2/sprint_116_beta_cohort_consent_plan.json';

void main() {
  group('116.49 Beta Cohort & Consent Plan', () {
    test('locks the seven required fields the canonical step demands', () {
      expect(Sprint116BetaCohortContract.requiredFields, <String>[
        'selection',
        'provider_coverage',
        'consent',
        'data_boundaries',
        'support',
        'withdrawal',
        'evidence',
      ]);
      expect(Sprint116BetaCohortContract.canonicalStep, '116.49');
      expect(Sprint116BetaCohortContract.externalGates, 'DEFERRED-EXTERNAL');
      expect(
        Sprint116BetaCohortContract.manifestPath,
        'docs/planning/v1.2/sprint_116_beta_cohort_consent_plan.json',
      );
      expect(Sprint116BetaCohortContract.supportedSources, <String>[
        'synthetic_local',
        'live',
        'local_run',
      ]);
      expect(Sprint116BetaCohortContract.evidencedSources, <String>[
        'live',
        'local_run',
      ]);
      expect(
        Sprint116BetaCohortContract.knownSelectionMethods,
        contains('invite_only'),
      );
      expect(Sprint116BetaCohortContract.knownCoverageStages, <String>[
        'committed',
        'planned',
        'deferred',
        'excluded',
      ]);
      expect(
        Sprint116BetaCohortContract.knownPurposes,
        contains('ai_inference'),
      );
      expect(
        Sprint116BetaCohortContract.knownDataCategories,
        contains('novel_text'),
      );
      expect(
        Sprint116BetaCohortContract.knownSupportChannels,
        contains('in_app'),
      );
      expect(
        Sprint116BetaCohortContract.knownWithdrawalMechanisms,
        contains('in_app_settings'),
      );
      expect(Sprint116BetaCohortContract.maxResponseSlaHours, 168);
      expect(Sprint116BetaCohortContract.minRetentionDays, 1);
      expect(Sprint116BetaCohortContract.maxRetentionDays, 3650);
      expect(Sprint116BetaCohortContract.maxWithdrawalDeadlineDays, 30);
      // The stages a provider must be ready on: consent and support have to
      // exist before anyone is enrolled, not after the first complaint.
      expect(Sprint116BetaCohortContract.betaPathStages, <String>[
        'committed',
        'planned',
      ]);
    });

    test('a complete beta plan certifies', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.coveredFields, <String>[
        'selection',
        'provider_coverage',
        'consent',
        'data_boundaries',
        'support',
        'withdrawal',
        'evidence',
      ]);
      final json = report.toJson();
      expect(json['canonical_step'], '116.49');
      expect(json['live_beta_execution'], isFalse);
      expect(json['no_fabricated_participants'], isTrue);
      expect(json['external_gates'], 'DEFERRED-EXTERNAL');
    });

    test('no reference clock is blocked, not passed', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(),
        asOfEpochMs: 0,
      );
      expect(report.state, Sprint116BetaPlanStatus.blocked);
      expect(report.invalidRecords, <String>['as_of_epoch_ms']);
    });

    final empties = <String, Sprint116BetaPlanControlSet Function()>{
      'selection': () => _controls(selection: <Sprint116BetaSelectionRecord>[]),
      'provider_coverage': () =>
          _controls(providerCoverage: <Sprint116BetaProviderCoverageRecord>[]),
      'consent': () => _controls(consent: <Sprint116BetaConsentRecord>[]),
      'data_boundaries': () =>
          _controls(dataBoundaries: <Sprint116BetaDataBoundaryRecord>[]),
      'support': () => _controls(support: <Sprint116BetaSupportRecord>[]),
      'withdrawal': () =>
          _controls(withdrawal: <Sprint116BetaWithdrawalRecord>[]),
      'evidence': () => _controls(evidence: <Sprint116BetaEvidenceRecord>[]),
    };
    empties.forEach((name, build) {
      test('an empty $name group is a gap rather than a pass', () {
        final report = Sprint116BetaCohortPlan().certify(
          controls: build(),
          asOfEpochMs: _now,
        );
        expect(report.state, Sprint116BetaPlanStatus.blocked);
        expect(report.invalidRecords, <String>[name]);
      });
    });

    test('a record without identity is rejected on identity', () {
      final selection = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          selection: <Sprint116BetaSelectionRecord>[_selection(cohortId: '')],
        ),
        asOfEpochMs: _now,
      );
      expect(selection.state, Sprint116BetaPlanStatus.fail);
      expect(selection.invalidRecords, contains('record_id:selection'));

      final withdrawal = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          withdrawal: <Sprint116BetaWithdrawalRecord>[
            _withdrawal(withdrawalId: ''),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(withdrawal.state, Sprint116BetaPlanStatus.fail);
      expect(withdrawal.invalidRecords, contains('record_id:withdrawal'));
    });

    test('an unknown source is a mock claim', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          selection: <Sprint116BetaSelectionRecord>[
            _selection(source: 'made_up'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('no_mock_values:cohort_alpha'));
    });

    test('a live claim without an evidence reference is a mock claim', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          selection: <Sprint116BetaSelectionRecord>[
            _selection(source: 'live', evidenceRef: null),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('no_mock_values:cohort_alpha'));
    });

    test('a live claim must cite an artifact registered as evidence', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          selection: <Sprint116BetaSelectionRecord>[
            _selection(
              source: 'live',
              evidenceRef: 'docs/evidence/ghost-that-does-not-exist.meta',
            ),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('evidence_register:selection:cohort_alpha'),
      );
    });

    test('enrolled participants from a synthetic fixture are fabricated', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          selection: <Sprint116BetaSelectionRecord>[
            _selection(enrolledCount: 12),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('fabricated_participants:cohort_alpha'),
      );
    });

    test('an enrolled cohort is believable only with registered evidence', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          selection: <Sprint116BetaSelectionRecord>[
            _selection(
              enrolledCount: 12,
              source: 'live',
              evidenceRef: _manifestArtifact,
            ),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.pass);
      expect(report.invalidRecords, isEmpty);
    });

    test('enrolment beyond the cohort target is rejected', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          selection: <Sprint116BetaSelectionRecord>[
            _selection(enrolledCount: 900),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('selection_enrolled:cohort_alpha'),
      );
    });

    test('a zero target is not a cohort', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          selection: <Sprint116BetaSelectionRecord>[_selection(targetSize: 0)],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('selection_target:cohort_alpha'));
    });

    test('a blank selection criterion is not a criterion', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          selection: <Sprint116BetaSelectionRecord>[
            _selection(criteria: <String>['power_users', '  ']),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('selection_criteria:cohort_alpha'),
      );
    });

    test('an unknown selection method cannot be audited', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          selection: <Sprint116BetaSelectionRecord>[
            _selection(selectionMethod: 'nepotism'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('selection_method:cohort_alpha'));
    });

    test('an unknown coverage stage cannot be audited', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          providerCoverage: <Sprint116BetaProviderCoverageRecord>[
            _coverage(stage: 'whenever'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('coverage_stage:openai'));
    });

    test('a deferred or excluded provider must say why', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          providerCoverage: <Sprint116BetaProviderCoverageRecord>[
            _coverage(stage: 'deferred', reason: ''),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('coverage_reason:openai'));
    });

    test('a provider row without a connector is not a coverage claim', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          providerCoverage: <Sprint116BetaProviderCoverageRecord>[
            _coverage(connectorId: ''),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('coverage_connector:openai'));
    });

    test('a beta-path provider without consent design is a gap', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          providerCoverage: <Sprint116BetaProviderCoverageRecord>[
            _coverage(),
            _coverage(
              providerId: 'gemini',
              connectorId: 'conn_gemini',
              stage: 'planned',
              consentRef: '',
            ),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('consent_coverage:gemini'));
    });

    test('consent for a cohort nobody selected is phantom consent', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          consent: <Sprint116BetaConsentRecord>[
            _consent(cohortId: 'cohort_ghost'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('consent_cohort:consent_openai'));
      // The real cohort is left without any consent design once consent is
      // pointed at a ghost, so both directions of the join have to fire.
      expect(report.invalidRecords, contains('cohort_consent:cohort_alpha'));
    });

    test('a selected cohort with no consent design is a gap', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          selection: <Sprint116BetaSelectionRecord>[
            _selection(cohortId: 'cohort_beta'),
            _selection(cohortId: 'cohort_alpha'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('cohort_consent:cohort_beta'));
    });

    test('bundled consent is not consent', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          consent: <Sprint116BetaConsentRecord>[_consent(explicitOptIn: false)],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('consent_explicit:consent_openai'),
      );
    });

    test('consent without a policy version cannot be withdrawn against', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          consent: <Sprint116BetaConsentRecord>[_consent(policyVersion: '')],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('consent_policy:consent_openai'));
    });

    test('an unknown purpose is not a purpose', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          consent: <Sprint116BetaConsentRecord>[
            _consent(purposes: <String>['astrology']),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('consent_purpose:consent_openai'));
    });

    test('consent granted in the future has not been granted', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          consent: <Sprint116BetaConsentRecord>[
            _consent(grantedAtEpochMs: _now + 60000),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('consent_timing:consent_openai'));
    });

    test('a named participant without evidence is fabricated', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          consent: <Sprint116BetaConsentRecord>[
            _consent(participantId: 'beta-user-001'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('fabricated_consent:consent_openai'),
      );
    });

    test('data leaving the device without encryption fails', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          dataBoundaries: <Sprint116BetaDataBoundaryRecord>[
            _boundary(encryptionInTransit: false),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('boundary_encryption:boundary_novel'),
      );
    });

    test('data leaving the device without a destination fails', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          dataBoundaries: <Sprint116BetaDataBoundaryRecord>[
            _boundary(destination: ''),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('boundary_destination:boundary_novel'),
      );
    });

    test('local-only data claiming a destination is a contradiction', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          dataBoundaries: <Sprint116BetaDataBoundaryRecord>[
            _boundary(
              boundaryId: 'boundary_project',
              category: 'project_metadata',
              leavesDevice: false,
              destination: 'sync.example.com',
              encryptionInTransit: false,
              retentionDays: 3650,
            ),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('boundary_local_destination:boundary_project'),
      );
    });

    test('retention beyond the cap fails', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          dataBoundaries: <Sprint116BetaDataBoundaryRecord>[
            _boundary(retentionDays: 99999),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('boundary_retention:boundary_novel'),
      );
    });

    test('device egress without consent coverage fails', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          dataBoundaries: <Sprint116BetaDataBoundaryRecord>[
            _boundary(),
            _boundaryLocal(),
            _boundary(
              boundaryId: 'boundary_tokens',
              category: 'connector_tokens',
              leavesDevice: true,
              destination: 'api.openai.com',
              encryptionInTransit: true,
              retentionDays: 30,
            ),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('boundary_consent:boundary_tokens'),
      );
    });

    test('an unknown data category cannot be bounded', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          dataBoundaries: <Sprint116BetaDataBoundaryRecord>[
            _boundary(category: 'schmategory'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('boundary_category:boundary_novel'),
      );
    });

    test('an unknown support channel cannot answer', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          support: <Sprint116BetaSupportRecord>[
            _support(channel: 'carrier_pigeon'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('support_channel:support_beta'));
    });

    test('a support SLA beyond the cap is not an SLA', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          support: <Sprint116BetaSupportRecord>[
            _support(responseSlaHours: 720),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('support_sla:support_beta'));
    });

    test('support without an escalation path dead-ends', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          support: <Sprint116BetaSupportRecord>[_support(escalationPath: '')],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('support_escalation:support_beta'),
      );
    });

    test('a beta-path provider without support coverage is a gap', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          support: <Sprint116BetaSupportRecord>[
            _support(scope: 'somebody_else'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('support_coverage:openai'));
    });

    test('an unknown withdrawal mechanism cannot execute', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          withdrawal: <Sprint116BetaWithdrawalRecord>[
            _withdrawal(mechanism: 'verbal_promise'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('withdrawal_mechanism:withdrawal_beta'),
      );
    });

    test('a withdrawal deadline beyond the cap is not a deadline', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          withdrawal: <Sprint116BetaWithdrawalRecord>[
            _withdrawal(deadlineDays: 90),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('withdrawal_deadline:withdrawal_beta'),
      );
    });

    test('withdrawal that deletes local project data is forbidden', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          withdrawal: <Sprint116BetaWithdrawalRecord>[
            _withdrawal(localProjectDataDeleted: true),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('withdrawal_local_data:withdrawal_beta'),
      );
    });

    test('withdrawal with a penalty is not withdrawal', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          withdrawal: <Sprint116BetaWithdrawalRecord>[
            _withdrawal(noPenalty: false),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('withdrawal_penalty:withdrawal_beta'),
      );
    });

    test('a data category with no withdrawal path is a gap', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          withdrawal: <Sprint116BetaWithdrawalRecord>[
            _withdrawal(coveredCategories: <String>['novel_text']),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(
        report.invalidRecords,
        contains('withdrawal_coverage:project_metadata'),
      );
    });

    test('an evidence row without a claim proves nothing', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          evidence: <Sprint116BetaEvidenceRecord>[_evidence(claim: '')],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('evidence_claim:ev_beta_plan'));
    });

    test('evidence recorded in the future cannot support this plan', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          evidence: <Sprint116BetaEvidenceRecord>[
            _evidence(recordedAtEpochMs: _now + 86400000),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BetaPlanStatus.fail);
      expect(report.invalidRecords, contains('evidence_time:ev_beta_plan'));
    });

    test('coverage mode reports the field nobody proved', () {
      final report = Sprint116BetaCohortPlan().certify(
        controls: _controls(
          support: <Sprint116BetaSupportRecord>[
            _support(channel: 'carrier_pigeon'),
          ],
        ),
        asOfEpochMs: _now,
        requireCoverage: true,
      );
      expect(report.invalidRecords, contains('area_coverage:support'));
    });

    test('the local manifest is UNVERIFIED and free of secrets', () {
      final report = Sprint116BetaCohortPlan().certify();
      expect(report.state, Sprint116BetaPlanStatus.pass);
      expect(report.invalidRecords, isEmpty);

      final raw = File(
        Sprint116BetaCohortContract.manifestPath,
      ).readAsStringSync();
      final manifest = jsonDecode(raw) as Map<String, dynamic>;
      expect(manifest['status'], 'UNVERIFIED');
      expect(manifest['live_beta_execution'], isFalse);
      expect(manifest['no_fabricated_participants'], isTrue);
      expect(manifest['certified_on'], '2026-09-29');
      expect(manifest['as_of_epoch_ms'], _now);
      expect(
        manifest['required_fields'],
        Sprint116BetaCohortContract.requiredFields,
      );

      // Keys and values are inspected, not raw prose: the limitations text
      // may say "no password stored" on purpose, and a substring scan would
      // flag that disclaimer as the very leak it denies.
      final vocabulary = <String>{
        ...Sprint116BetaCohortContract.requiredFields,
        ...Sprint116BetaCohortContract.supportedSources,
        ...Sprint116BetaCohortContract.knownSelectionMethods,
        ...Sprint116BetaCohortContract.knownCoverageStages,
        ...Sprint116BetaCohortContract.knownPurposes,
        ...Sprint116BetaCohortContract.knownDataCategories,
        ...Sprint116BetaCohortContract.knownSupportChannels,
        ...Sprint116BetaCohortContract.knownWithdrawalMechanisms,
        ...Sprint116BetaCohortContract.betaPathStages,
      };

      for (final secret in <String>[
        'api_key',
        'apikey',
        'access_token',
        'bearer',
        'client_secret',
        'password',
        'private_key',
      ]) {
        bool carriesSecret(Object? node) {
          if (node is Map) {
            for (final entry in node.entries) {
              if (entry.key.toString().toLowerCase().contains(secret)) {
                return true;
              }
              if (carriesSecret(entry.value)) return true;
            }
            return false;
          }
          if (node is List) return node.any(carriesSecret);
          final text = node.toString();
          if (vocabulary.contains(text)) return false;
          return text.toLowerCase().contains(secret);
        }

        expect(
          carriesSecret(manifest),
          isFalse,
          reason: 'manifest must not carry $secret',
        );
      }

      // Positive control: the exemption above is narrow, so a real value in
      // the same shape is still caught. Without this the scanner could be
      // weakened into silence and the assertions above become theatre.
      for (final secret in <String>['api_key', 'password']) {
        bool wouldBeCaught(Map<String, Object?> node) {
          bool walk(Object? value) {
            if (value is Map) {
              for (final entry in value.entries) {
                if (entry.key.toString().toLowerCase().contains(secret)) {
                  return true;
                }
                if (walk(entry.value)) return true;
              }
              return false;
            }
            if (value is List) return value.any(walk);
            final text = value.toString();
            if (vocabulary.contains(text)) return false;
            return text.toLowerCase().contains(secret);
          }

          return walk(node);
        }

        expect(
          wouldBeCaught(<String, Object?>{
            'consent': <Object?>[
              <String, Object?>{'policy_version': '$secret=not-a-real-value'},
            ],
          }),
          isTrue,
          reason: 'a real credential in a policy field must be caught',
        );
      }
    });
  });
}

// The default is the healthy plan for one provider. An explicitly passed
// empty list stays empty, so a caller can never assert "this field was not
// run" by accident of the helper filling it back in.
Sprint116BetaPlanControlSet _controls({
  List<Sprint116BetaSelectionRecord>? selection,
  List<Sprint116BetaProviderCoverageRecord>? providerCoverage,
  List<Sprint116BetaConsentRecord>? consent,
  List<Sprint116BetaDataBoundaryRecord>? dataBoundaries,
  List<Sprint116BetaSupportRecord>? support,
  List<Sprint116BetaWithdrawalRecord>? withdrawal,
  List<Sprint116BetaEvidenceRecord>? evidence,
}) {
  return Sprint116BetaPlanControlSet(
    selection: selection ?? <Sprint116BetaSelectionRecord>[_selection()],
    providerCoverage:
        providerCoverage ?? <Sprint116BetaProviderCoverageRecord>[_coverage()],
    consent: consent ?? <Sprint116BetaConsentRecord>[_consent()],
    dataBoundaries:
        dataBoundaries ??
        <Sprint116BetaDataBoundaryRecord>[_boundary(), _boundaryLocal()],
    support: support ?? <Sprint116BetaSupportRecord>[_support()],
    withdrawal: withdrawal ?? <Sprint116BetaWithdrawalRecord>[_withdrawal()],
    evidence: evidence ?? <Sprint116BetaEvidenceRecord>[_evidence()],
  );
}

Sprint116BetaSelectionRecord _selection({
  String cohortId = 'cohort_alpha',
  List<String> criteria = const <String>['power_users'],
  String selectionMethod = 'invite_only',
  int targetSize = 40,
  int enrolledCount = 0,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116BetaSelectionRecord(
    cohortId: cohortId,
    criteria: criteria,
    selectionMethod: selectionMethod,
    targetSize: targetSize,
    enrolledCount: enrolledCount,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116BetaProviderCoverageRecord _coverage({
  String providerId = 'openai',
  String connectorId = 'conn_openai',
  String stage = 'committed',
  String reason = '',
  String consentRef = 'consent_openai',
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116BetaProviderCoverageRecord(
    providerId: providerId,
    connectorId: connectorId,
    stage: stage,
    reason: reason,
    consentRef: consentRef,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116BetaConsentRecord _consent({
  String consentId = 'consent_openai',
  String cohortId = 'cohort_alpha',
  List<String> purposes = const <String>['ai_inference'],
  List<String> coveredCategories = const <String>['novel_text'],
  bool explicitOptIn = true,
  String policyVersion = 'beta-consent-1.0',
  String participantId = '',
  int? grantedAtEpochMs,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116BetaConsentRecord(
    consentId: consentId,
    cohortId: cohortId,
    purposes: purposes,
    coveredCategories: coveredCategories,
    explicitOptIn: explicitOptIn,
    policyVersion: policyVersion,
    participantId: participantId,
    grantedAtEpochMs: grantedAtEpochMs ?? _base,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116BetaDataBoundaryRecord _boundary({
  String boundaryId = 'boundary_novel',
  String category = 'novel_text',
  bool leavesDevice = true,
  String destination = 'api.openai.com',
  bool encryptionInTransit = true,
  int retentionDays = 90,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116BetaDataBoundaryRecord(
    boundaryId: boundaryId,
    category: category,
    leavesDevice: leavesDevice,
    destination: destination,
    encryptionInTransit: encryptionInTransit,
    retentionDays: retentionDays,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116BetaDataBoundaryRecord _boundaryLocal({
  String boundaryId = 'boundary_project',
  String category = 'project_metadata',
  int retentionDays = 3650,
}) {
  return Sprint116BetaDataBoundaryRecord(
    boundaryId: boundaryId,
    category: category,
    leavesDevice: false,
    destination: '',
    encryptionInTransit: false,
    retentionDays: retentionDays,
    source: 'synthetic_local',
    evidenceRef: null,
  );
}

Sprint116BetaSupportRecord _support({
  String supportId = 'support_beta',
  String channel = 'in_app',
  String scope = 'beta_global',
  int responseSlaHours = 48,
  String escalationPath = 'in_app_thread -> maintainer_inbox',
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116BetaSupportRecord(
    supportId: supportId,
    channel: channel,
    scope: scope,
    responseSlaHours: responseSlaHours,
    escalationPath: escalationPath,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116BetaWithdrawalRecord _withdrawal({
  String withdrawalId = 'withdrawal_beta',
  String mechanism = 'in_app_settings',
  int deadlineDays = 7,
  List<String> coveredCategories = const <String>[
    'novel_text',
    'project_metadata',
  ],
  bool localProjectDataDeleted = false,
  bool noPenalty = true,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116BetaWithdrawalRecord(
    withdrawalId: withdrawalId,
    mechanism: mechanism,
    deadlineDays: deadlineDays,
    coveredCategories: coveredCategories,
    localProjectDataDeleted: localProjectDataDeleted,
    noPenalty: noPenalty,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116BetaEvidenceRecord _evidence({
  String evidenceId = 'ev_beta_plan',
  String claim = 'beta plan recorded in the repository manifest',
  String artifact = _manifestArtifact,
  int? recordedAtEpochMs,
  String source = 'local_run',
  String? evidenceRef,
}) {
  return Sprint116BetaEvidenceRecord(
    evidenceId: evidenceId,
    claim: claim,
    artifact: artifact,
    recordedAtEpochMs: recordedAtEpochMs ?? _base,
    source: source,
    evidenceRef: evidenceRef ?? _manifestArtifact,
  );
}
