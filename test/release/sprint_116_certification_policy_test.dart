import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_certification_policy.dart';

void main() {
  group('116.2 Certification Policy & Evidence Schema', () {
    test('declares the canonical certification schema boundaries', () {
      expect(Sprint116CertificationContract.canonicalStep, '116.2');
      expect(Sprint116CertificationContract.requiredFields, <String>[
        'provider_id',
        'connector_version',
        'status',
        'evidence',
        'reviewer',
        'reviewed_at',
        'expires_or_recheck_at',
        'limitations',
      ]);
      expect(
        Sprint116CertificationContract.manifestPath,
        'docs/planning/v1.2/sprint_116_certification_policy.json',
      );
      expect(
        Sprint116CertificationContract.validStatuses,
        containsAll(<String>['UNVERIFIED', 'CERTIFIED', 'LIMITED']),
      );
      expect(
        Sprint116CertificationContract.recertificationTriggers,
        contains('provider_api_change'),
      );
      expect(
        Sprint116CertificationContract.recertificationTriggers,
        contains('review_window_expired'),
      );
    });

    test('manifest binds required fields, statuses, and recertification', () {
      final manifest = _readManifest();

      expect(manifest['canonical_step'], '116.2');
      expect(manifest['title'], 'Certification Policy & Evidence Schema');
      expect(
        manifest['required_fields'],
        Sprint116CertificationContract.requiredFields,
      );
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['verdict'], 'CERTIFICATION_POLICY_READY');
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');

      final statuses = manifest['certification_statuses'] as List<dynamic>;
      expect(statuses, contains('UNVERIFIED'));
      expect(statuses, contains('CERTIFIED'));
      expect(statuses, contains('LIMITED'));
      expect(statuses, contains('BLOCKED'));
      expect(statuses, contains('EXPIRED'));

      final triggers = manifest['recertification_triggers'] as List<dynamic>;
      expect(
        triggers,
        containsAll(Sprint116CertificationContract.recertificationTriggers),
      );
    });

    test('fail-closed on missing evidence records blocks', () {
      final report = Sprint116CertificationPolicy().evaluate(
        const <Sprint116CertificationEvidence>[],
      );

      expect(report.state, Sprint116CertificationState.blocked);
      expect(report.missingFields, contains('evidence_records'));
      expect(report.verdict, 'CERTIFICATION_POLICY_INCOMPLETE');
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('live manifest evaluation passes schema gating', () {
      final report = Sprint116CertificationPolicy().evaluate();

      expect(report.state, Sprint116CertificationState.pass);
      expect(report.verdict, 'CERTIFICATION_POLICY_READY');
      expect(report.missingFields, isEmpty);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.certificationStatuses, isNotEmpty);
      expect(
        report.recertificationTriggers,
        containsAll(Sprint116CertificationContract.recertificationTriggers),
      );
    });

    test('missing required field names provider and field', () {
      final report = Sprint116CertificationPolicy().evaluate(
        <Sprint116CertificationEvidence>[
          Sprint116CertificationEvidence(
            providerId: 'test_provider',
            connectorVersion: '1.0.0',
            status: 'UNVERIFIED',
            evidence: const <String, Object?>{},
            reviewer: 'automation-governance',
            reviewedAt: '2026-09-27',
            expiresOrRecheckAt: '2027-03-27',
            limitations: const <String>['test_only'],
          ),
        ],
      );

      expect(report.state, Sprint116CertificationState.blocked);
      expect(
        report.missingFields,
        containsAll(<String>[
          'evidence:test_provider:api_verification',
          'evidence:test_provider:sdk_verification',
          'evidence:test_provider:auth_flow_test',
          'evidence:test_provider:quota_capability_test',
          'evidence:test_provider:error_handling_test',
          'evidence:test_provider:security_review',
          'evidence:test_provider:terms_compliance_check',
        ]),
      );
    });

    test('invalid certification status fails closed', () {
      final base = _syntheticEvidence(status: 'CERTIFIED');
      final invalid = Sprint116CertificationPolicy().evaluate(
        <Sprint116CertificationEvidence>[
          base,
          _syntheticEvidence(providerId: 'bad_status', status: 'TRUSTED'),
        ],
      );

      expect(invalid.state, Sprint116CertificationState.fail);
      expect(invalid.invalidFields, contains('status:bad_status'));
      expect(invalid.certificationStatuses, contains('CERTIFIED'));
    });

    test('certified-without-limitations and unverified-with-evidence fail', () {
      final violations = Sprint116CertificationPolicy()
          .evaluate(<Sprint116CertificationEvidence>[
            _syntheticEvidence(
              providerId: 'no_limits',
              status: 'CERTIFIED',
              limitations: const <String>[],
            ),
            _syntheticEvidence(
              providerId: 'unverified_evidence',
              status: 'UNVERIFIED',
            ),
          ]);

      expect(
        violations.state,
        anyOf([
          Sprint116CertificationState.fail,
          Sprint116CertificationState.blocked,
        ]),
      );
      expect(
        violations.violations,
        contains('certified_without_limitations:no_limits'),
      );
      expect(
        violations.violations,
        contains('unverified_with_evidence:unverified_evidence'),
      );
    });

    test('synthetic complete evidence record passes schema', () {
      final report = Sprint116CertificationPolicy().evaluate(
        <Sprint116CertificationEvidence>[
          _syntheticEvidence(
            status: 'CERTIFIED',
            evidence: _completeEvidence(),
          ),
        ],
      );

      expect(report.state, Sprint116CertificationState.pass);
      expect(report.certificationStatuses, contains('CERTIFIED'));
    });
  });
}

Map<String, dynamic> _readManifest() {
  return jsonDecode(
        File(Sprint116CertificationContract.manifestPath).readAsStringSync(),
      )
      as Map<String, dynamic>;
}

Sprint116CertificationEvidence _syntheticEvidence({
  required String status,
  String providerId = 'synthetic_provider',
  List<String> limitations = const <String>['synthetic_limitation'],
  Map<String, Object?> evidence = const <String, Object?>{
    'api_verification': true,
  },
}) {
  return Sprint116CertificationEvidence(
    providerId: providerId,
    connectorVersion: '1.0.0',
    status: status,
    evidence: <String, Object?>{
      for (final key in Sprint116CertificationContract.evidenceRequirements)
        key: evidence[key] ?? false,
    },
    reviewer: 'automation-governance',
    reviewedAt: '2026-09-27',
    expiresOrRecheckAt: '2027-03-27',
    limitations: List<String>.from(limitations),
  );
}

Map<String, Object?> _completeEvidence() {
  return <String, Object?>{
    for (final key in Sprint116CertificationContract.evidenceRequirements)
      key: true,
  };
}
