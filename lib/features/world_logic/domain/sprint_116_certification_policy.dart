library;

import 'dart:convert';
import 'dart:io';

/// Fail-closed certification policy contract for Sprint 116.2.
///
/// The schema locks certification status, evidence requirements, expiry,
/// versioning, reviewer attribution, exceptions, and recertification
/// triggers. It does not claim live provider certification or public
/// release readiness.

enum Sprint116CertificationState { pass, fail, blocked }

class Sprint116CertificationEvidence {
  Sprint116CertificationEvidence({
    required this.providerId,
    required this.connectorVersion,
    required this.status,
    required this.evidence,
    required this.reviewer,
    required this.reviewedAt,
    required this.expiresOrRecheckAt,
    required this.limitations,
  });

  final String providerId;
  final String connectorVersion;
  final String status;
  final Map<String, Object?> evidence;
  final String reviewer;
  final String reviewedAt;
  final String expiresOrRecheckAt;
  final List<String> limitations;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'provider_id': providerId,
      'connector_version': connectorVersion,
      'status': status,
      'evidence': evidence,
      'reviewer': reviewer,
      'reviewed_at': reviewedAt,
      'expires_or_recheck_at': expiresOrRecheckAt,
      'limitations': List<String>.from(limitations),
    };
  }
}

class Sprint116CertificationReport {
  Sprint116CertificationReport({
    required this.state,
    required this.verdict,
    required List<String> missingFields,
    required List<String> invalidFields,
    required List<String> violations,
    required List<String> certificationStatuses,
    required List<String> recertificationTriggers,
  }) : missingFields = List<String>.unmodifiable(missingFields),
       invalidFields = List<String>.unmodifiable(invalidFields),
       violations = List<String>.unmodifiable(violations),
       certificationStatuses = List<String>.unmodifiable(certificationStatuses),
       recertificationTriggers = List<String>.unmodifiable(
         recertificationTriggers,
       );

  final Sprint116CertificationState state;
  final String verdict;
  final List<String> missingFields;
  final List<String> invalidFields;
  final List<String> violations;
  final List<String> certificationStatuses;
  final List<String> recertificationTriggers;

  String get externalGates => 'DEFERRED-EXTERNAL';

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'state': state.name,
      'verdict': verdict,
      'missing_fields': List<String>.from(missingFields),
      'invalid_fields': List<String>.from(invalidFields),
      'violations': List<String>.from(violations),
      'certification_statuses': List<String>.from(certificationStatuses),
      'recertification_triggers': List<String>.from(recertificationTriggers),
      'external_gates': externalGates,
    };
  }
}

abstract final class Sprint116CertificationContract {
  static const String canonicalStep = '116.2';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_certification_policy.json';

  static const List<String> requiredFields = <String>[
    'provider_id',
    'connector_version',
    'status',
    'evidence',
    'reviewer',
    'reviewed_at',
    'expires_or_recheck_at',
    'limitations',
  ];

  static const Set<String> validStatuses = <String>{
    'UNVERIFIED',
    'CERTIFIED',
    'LIMITED',
    'BLOCKED',
    'EXPIRED',
  };

  static const Set<String> recertificationTriggers = <String>{
    'provider_api_change',
    'connector_version_change',
    'security_incident',
    'terms_of_service_change',
    'quota_policy_change',
    'regional_availability_change',
    'review_window_expired',
    'manual_review_required',
  };

  static const List<String> evidenceRequirements = <String>[
    'api_verification',
    'sdk_verification',
    'auth_flow_test',
    'quota_capability_test',
    'error_handling_test',
    'security_review',
    'terms_compliance_check',
  ];

  static const String defaultCertificationStatus = 'UNVERIFIED';
}

class Sprint116CertificationPolicy {
  Sprint116CertificationReport evaluate([
    List<Sprint116CertificationEvidence>? evidence,
  ]) {
    final records = evidence ?? _readLiveEvidence();
    final missing = <String>[];
    final invalid = <String>[];
    final violations = <String>[];
    final statuses = <String>[];
    final triggers = <String>[];

    if (records.isEmpty) {
      missing.add('evidence_records');
      return Sprint116CertificationReport(
        state: Sprint116CertificationState.blocked,
        verdict: 'CERTIFICATION_POLICY_INCOMPLETE',
        missingFields: missing,
        invalidFields: invalid,
        violations: violations,
        certificationStatuses: statuses,
        recertificationTriggers: triggers,
      );
    }

    for (final record in records) {
      final providerId = record.providerId.trim();
      if (providerId.isEmpty) {
        missing.add('provider_id:${record.providerId}');
      }

      final version = record.connectorVersion.trim();
      if (version.isEmpty) {
        missing.add('connector_version:$providerId');
      }

      final status = record.status.trim();
      if (status.isEmpty) {
        missing.add('status:$providerId');
      } else if (!Sprint116CertificationContract.validStatuses.contains(
        status,
      )) {
        invalid.add('status:$providerId');
      } else {
        statuses.add(status);
      }

      if (record.reviewer.trim().isEmpty) {
        missing.add('reviewer:$providerId');
      }

      if (record.reviewedAt.trim().isEmpty) {
        missing.add('reviewed_at:$providerId');
      }

      if (record.expiresOrRecheckAt.trim().isEmpty) {
        missing.add('expires_or_recheck_at:$providerId');
      }

      if (record.limitations.isEmpty) {
        missing.add('limitations:$providerId');
      }

      final evidenceKeys = record.evidence.keys.toSet();
      for (final required
          in Sprint116CertificationContract.evidenceRequirements) {
        if (!evidenceKeys.contains(required)) {
          missing.add('evidence:$providerId:$required');
        }
      }

      if (status == 'CERTIFIED' && record.limitations.isEmpty) {
        violations.add('certified_without_limitations:$providerId');
      }

      if (status == 'UNVERIFIED' && record.evidence.isNotEmpty) {
        violations.add('unverified_with_evidence:$providerId');
      }
    }

    for (final trigger
        in Sprint116CertificationContract.recertificationTriggers) {
      triggers.add(trigger);
    }

    final state = missing.isNotEmpty
        ? Sprint116CertificationState.blocked
        : invalid.isNotEmpty || violations.isNotEmpty
        ? Sprint116CertificationState.fail
        : Sprint116CertificationState.pass;
    final verdict = state == Sprint116CertificationState.pass
        ? 'CERTIFICATION_POLICY_READY'
        : 'CERTIFICATION_POLICY_INCOMPLETE';

    return Sprint116CertificationReport(
      state: state,
      verdict: verdict,
      missingFields: missing,
      invalidFields: invalid,
      violations: violations,
      certificationStatuses: statuses,
      recertificationTriggers: triggers,
    );
  }

  List<Sprint116CertificationEvidence> _readLiveEvidence() {
    final manifest = _readJsonObject(
      Sprint116CertificationContract.manifestPath,
    );
    if (manifest == null) {
      return <Sprint116CertificationEvidence>[];
    }

    final rawEvidence = manifest['evidence_records'];
    if (rawEvidence is! List) {
      return <Sprint116CertificationEvidence>[];
    }

    final evidence = <Sprint116CertificationEvidence>[];
    for (final item in rawEvidence) {
      if (item is! Map) continue;
      final rawEvidenceMap = item['evidence'];
      if (rawEvidenceMap is! Map) continue;
      final rawLimitations = item['limitations'];
      if (rawLimitations is! List) continue;
      evidence.add(
        Sprint116CertificationEvidence(
          providerId: item['provider_id']?.toString() ?? '',
          connectorVersion: item['connector_version']?.toString() ?? '',
          status: item['status']?.toString() ?? '',
          evidence: rawEvidenceMap.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
          reviewer: item['reviewer']?.toString() ?? '',
          reviewedAt: item['reviewed_at']?.toString() ?? '',
          expiresOrRecheckAt: item['expires_or_recheck_at']?.toString() ?? '',
          limitations: rawLimitations
              .map((item) => item.toString())
              .toList(growable: false),
        ),
      );
    }
    return evidence;
  }

  Map<String, dynamic>? _readJsonObject(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
