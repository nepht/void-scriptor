library;

import 'dart:convert';
import 'dart:io';

/// Fail-closed entry contract for Sprint 115.1.
///
/// The gate authorizes only the corrective local scope approved after Sprint
/// 114. It does not claim public release, live connector availability, billing
/// certification, hosted CI, hardware validation, or publication.

enum Sprint115EntryGateState { pass, fail, blocked }

class Sprint115EntryEvidence {
  Sprint115EntryEvidence({required this.status, required List<String> sources})
    : sources = List<String>.unmodifiable(sources);

  final String status;
  final List<String> sources;
}

class Sprint115EntryGateReport {
  Sprint115EntryGateReport({
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

  final Sprint115EntryGateState state;
  final String verdict;
  final List<String> missingEvidence;
  final List<String> invalidEvidence;
  final List<String> violations;
  final String activeScope;
  final bool fullScopeApproved;

  String get externalGates => 'DEFERRED-EXTERNAL';
  List<String> get deferredProviderFeasibility =>
      Sprint115EntryGateContract.deferredProviderFeasibility;

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

abstract final class Sprint115EntryGateContract {
  static const String canonicalStep = '115.1';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_115_entry_gate.json';

  static const List<String> requiredEvidence = <String>[
    'sprint_114_readiness',
    'approved_scope',
    'product_spec',
    'security_constraints',
    'privacy_constraints',
    'provider_feasibility',
  ];

  static const List<String> requiredSources = <String>[
    'docs/planning/v1.2/sprint_115_readiness_gate.json',
    'docs/planning/v1.2/sprint_115_entry_gate_product_spec.json',
    'docs/roadmap/ROADMAP_POLICY.json',
    'docs/planning/v1.2/sprint_114_security_privacy_maintenance.json',
  ];

  static const Set<String> verifiedLocalStatuses = <String>{
    'VERIFIED-LOCAL',
    'CORRECTIVE_SCOPE_APPROVED',
    'DEFERRED-EXTERNAL',
  };

  static const List<String> deferredProviderFeasibility = <String>[
    'live_provider_certification',
    'live_quota_and_cost_evidence',
    'public_billing_certification',
    'connector_availability_claims',
  ];
}

class Sprint115EntryGate {
  Sprint115EntryGateReport evaluate([
    Map<String, Sprint115EntryEvidence>? evidence,
  ]) {
    final records = evidence ?? _readLiveEvidence();
    final missing = <String>[];
    final invalid = <String>[];
    final violations = <String>[];

    for (final field in Sprint115EntryGateContract.requiredEvidence) {
      final record = records[field];
      if (record == null) {
        missing.add(field);
        continue;
      }
      if (record.status.trim().isEmpty) {
        invalid.add(field);
      } else if (!Sprint115EntryGateContract.verifiedLocalStatuses.contains(
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
              !Sprint115EntryGateContract.requiredEvidence.contains(field),
        )
        .toList(growable: false);
    invalid.addAll(unexpected);

    final scopeRecord = records['approved_scope'];
    final scope = scopeRecord?.status.trim() ?? '';
    final fullScopeApproved = scope == 'FULL_SCOPE_APPROVED';
    if (scopeRecord != null && fullScopeApproved) {
      violations.add('full_scope_not_approved_on_delayed_entry_gate');
    }

    final state = missing.isNotEmpty
        ? Sprint115EntryGateState.blocked
        : invalid.isNotEmpty || violations.isNotEmpty
        ? Sprint115EntryGateState.fail
        : Sprint115EntryGateState.pass;
    final verdict = state == Sprint115EntryGateState.pass
        ? 'CORRECTIVE_ENTRY_READY'
        : 'SPRINT_115_ENTRY_BLOCKED';

    return Sprint115EntryGateReport(
      state: state,
      verdict: verdict,
      missingEvidence: missing,
      invalidEvidence: invalid,
      violations: violations,
      activeScope: scope.isEmpty ? 'UNAVAILABLE' : scope,
      fullScopeApproved: fullScopeApproved,
    );
  }

  Map<String, Sprint115EntryEvidence> _readLiveEvidence() {
    final manifest = _readJsonObject(Sprint115EntryGateContract.manifestPath);
    if (manifest == null) {
      return <String, Sprint115EntryEvidence>{};
    }

    final rawEvidence = manifest['evidence'];
    if (rawEvidence is! Map) {
      return <String, Sprint115EntryEvidence>{};
    }

    final evidence = <String, Sprint115EntryEvidence>{};
    for (final field in Sprint115EntryGateContract.requiredEvidence) {
      final record = rawEvidence[field];
      if (record is! Map) continue;
      final rawSources = record['sources'];
      if (rawSources is! List) continue;
      evidence[field] = Sprint115EntryEvidence(
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
