library;

import 'dart:convert';
import 'dart:io';

/// Fail-closed entry contract for Sprint 116.1.
///
/// The gate authorizes only the certification scope approved after Sprint
/// 115. It does not claim public release, live connector availability, billing
/// certification, hosted CI, hardware validation, or publication.

enum Sprint116EntryGateState { pass, fail, blocked }

class Sprint116EntryEvidence {
  Sprint116EntryEvidence({required this.status, required List<String> sources})
    : sources = List<String>.unmodifiable(sources);

  final String status;
  final List<String> sources;
}

class Sprint116EntryGateReport {
  Sprint116EntryGateReport({
    required this.state,
    required this.verdict,
    required List<String> missingEvidence,
    required List<String> invalidEvidence,
    required List<String> violations,
    required this.activeScope,
    required this.fullScopeApproved,
  }) : missingEvidence = List<String>.unmodifiable(missingEvidence),
       invalidEvidence = List<String>.unmodifiable(invalidEvidence),
       violations = List<String>.unmodifiable(violations);

  final Sprint116EntryGateState state;
  final String verdict;
  final List<String> missingEvidence;
  final List<String> invalidEvidence;
  final List<String> violations;
  final String activeScope;
  final bool fullScopeApproved;

  String get externalGates => 'DEFERRED-EXTERNAL';
  List<String> get deferredProviderFeasibility =>
      Sprint116EntryGateContract.deferredProviderFeasibility;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'state': state.name,
      'verdict': verdict,
      'missing_evidence': List<String>.from(missingEvidence),
      'invalid_evidence': List<String>.from(invalidEvidence),
      'violations': List<String>.from(violations),
      'active_scope': activeScope,
      'full_scope_approved': fullScopeApproved,
      'external_gates': externalGates,
    };
  }
}

abstract final class Sprint116EntryGateContract {
  static const String canonicalStep = '116.1';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_entry_gate.json';

  static const List<String> requiredEvidence = <String>[
    'sprint_115_acceptance',
    'provider_registry',
    'connector_manifests',
    'test_environment_plan',
    'security_plan',
    'brand_review_plan',
  ];

  static const List<String> requiredSources = <String>[
    'docs/planning/v1.2/sprint_115_alpha_acceptance.json',
    'docs/planning/v1.2/sprint_115_provider_icon_registry.json',
    'docs/planning/v1.2/sprint_115_provider_connector_manifest.json',
    'docs/planning/v1.2/sprint_115_automated_test_matrix.json',
    'docs/planning/v1.2/sprint_115_security_billing_verification.json',
    'docs/planning/v1.2/sprint_114_security_privacy_maintenance.json',
  ];

  static const Set<String> verifiedLocalStatuses = <String>{
    'VERIFIED-LOCAL',
    'CERTIFICATION_SCOPE_APPROVED',
    'DEFERRED-EXTERNAL',
  };

  static const List<String> deferredProviderFeasibility = <String>[
    'live_provider_certification',
    'live_quota_and_cost_evidence',
    'public_billing_certification',
    'connector_availability_claims',
  ];
}

class Sprint116EntryGate {
  Sprint116EntryGateReport evaluate([
    Map<String, Sprint116EntryEvidence>? evidence,
  ]) {
    final records = evidence ?? _readLiveEvidence();
    final missing = <String>[];
    final invalid = <String>[];
    final violations = <String>[];

    for (final field in Sprint116EntryGateContract.requiredEvidence) {
      final record = records[field];
      if (record == null) {
        missing.add(field);
        continue;
      }
      if (record.status.trim().isEmpty) {
        invalid.add(field);
      } else if (!Sprint116EntryGateContract.verifiedLocalStatuses.contains(
        record.status.trim(),
      )) {
        invalid.add(field);
      }
      if (record.sources.isEmpty ||
          record.sources.any((source) => source.trim().isEmpty) ||
          record.sources.any((source) => !File(source).existsSync())) {
        invalid.add(field);
      }
    }

    final unexpected = records.keys
        .where(
          (field) =>
              !Sprint116EntryGateContract.requiredEvidence.contains(field),
        )
        .toList(growable: false);
    invalid.addAll(unexpected);

    final scopeRecord = records['sprint_115_acceptance'];
    final scope = scopeRecord?.status.trim() ?? '';
    final fullScopeApproved = scope == 'FULL_SCOPE_APPROVED';
    if (scopeRecord != null && fullScopeApproved) {
      violations.add('full_scope_not_approved_on_certification_entry_gate');
    }

    final state = missing.isNotEmpty
        ? Sprint116EntryGateState.blocked
        : invalid.isNotEmpty || violations.isNotEmpty
        ? Sprint116EntryGateState.fail
        : Sprint116EntryGateState.pass;
    final verdict = state == Sprint116EntryGateState.pass
        ? 'CERTIFICATION_ENTRY_READY'
        : 'SPRINT_116_ENTRY_BLOCKED';

    return Sprint116EntryGateReport(
      state: state,
      verdict: verdict,
      missingEvidence: missing,
      invalidEvidence: invalid,
      violations: violations,
      activeScope: scope.isEmpty ? 'UNAVAILABLE' : scope,
      fullScopeApproved: fullScopeApproved,
    );
  }

  Map<String, Sprint116EntryEvidence> _readLiveEvidence() {
    final manifest = _readJsonObject(Sprint116EntryGateContract.manifestPath);
    if (manifest == null) {
      return <String, Sprint116EntryEvidence>{};
    }

    final rawEvidence = manifest['evidence'];
    if (rawEvidence is! Map) {
      return <String, Sprint116EntryEvidence>{};
    }

    final evidence = <String, Sprint116EntryEvidence>{};
    for (final field in Sprint116EntryGateContract.requiredEvidence) {
      final record = rawEvidence[field];
      if (record is! Map) continue;
      final rawSources = record['sources'];
      if (rawSources is! List) continue;
      evidence[field] = Sprint116EntryEvidence(
        status: record['status']?.toString() ?? '',
        sources: rawSources.map((source) => source.toString()).toList(),
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
