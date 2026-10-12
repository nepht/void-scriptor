/// Canonical step 118.46 -- Sprint Closure.
///
/// This gate closes the delayed corrective sprint locally from committed
/// evidence. It never turns a local record into a release, certification, or
/// live observation claim.
library;

import 'dart:convert';
import 'dart:io';

enum Sprint118ClosureState { pass, blocked, fail }

enum Sprint118ClosureDecision { closedLocalDeferredExternal, blocked }

enum Sprint118ClosureCriterionStatus { satisfied, deferredExternal, unmet }

class Sprint118ClosureCriterion {
  const Sprint118ClosureCriterion({
    required this.name,
    required this.status,
    required this.evidence,
    required this.detail,
  });

  final String name;
  final Sprint118ClosureCriterionStatus status;
  final List<String> evidence;
  final String detail;

  bool get satisfied => status == Sprint118ClosureCriterionStatus.satisfied;

  bool get deferred =>
      status == Sprint118ClosureCriterionStatus.deferredExternal;

  bool get unmet => status == Sprint118ClosureCriterionStatus.unmet;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'status': status.name,
    'evidence': List<String>.from(evidence),
    'detail': detail,
  };
}

class Sprint118ClosureEvidenceAnchor {
  Sprint118ClosureEvidenceAnchor({
    required this.entryState,
    required this.entryExecutionAllowed,
    required this.correctiveScopeApproved,
    required this.releaseState,
    required this.charterState,
    required this.snapshotState,
    required this.snapshotFrozen,
    required this.registeredProviderCount,
    required this.certifiedProviderCount,
    required this.incidentState,
    required this.liveIncidentExecuted,
    required this.disableState,
    required this.fixesState,
    required this.maintenanceState,
    required this.maintenanceDecision,
    required this.certificationState,
    required this.expansionAcceptanceState,
    required this.reportState,
    required this.reportVerified,
    required this.reportDeclaredSectionCount,
    required this.reportExpectedSectionCount,
    required this.readinessState,
    required this.readinessVerified,
    required this.readinessDecision,
    required this.allLedgerStepsResolved,
    required List<String> missingEvidence,
    required List<String> sourceViolations,
    required this.readableSourceCount,
    required this.ledgerPath,
  }) : missingEvidence = List<String>.unmodifiable(missingEvidence),
       sourceViolations = List<String>.unmodifiable(sourceViolations);

  final String entryState;
  final bool entryExecutionAllowed;
  final bool correctiveScopeApproved;
  final String releaseState;
  final String charterState;
  final String snapshotState;
  final bool snapshotFrozen;
  final int registeredProviderCount;
  final int certifiedProviderCount;
  final String incidentState;
  final bool liveIncidentExecuted;
  final String disableState;
  final String fixesState;
  final String maintenanceState;
  final String maintenanceDecision;
  final String certificationState;
  final String expansionAcceptanceState;
  final String reportState;
  final bool reportVerified;
  final int reportDeclaredSectionCount;
  final int reportExpectedSectionCount;
  final String readinessState;
  final bool readinessVerified;
  final String readinessDecision;
  final bool allLedgerStepsResolved;
  final List<String> missingEvidence;
  final List<String> sourceViolations;
  final int readableSourceCount;
  final String ledgerPath;

  bool get liveReleaseExecuted => false;
}

class Sprint118ClosureReport {
  Sprint118ClosureReport({
    required this.state,
    required this.decision,
    required this.verdict,
    required List<Sprint118ClosureCriterion> criteria,
    required List<String> missingEvidence,
    required List<String> violations,
    required List<String> openItems,
    required List<String> limitations,
    required this.releaseDecision,
    required this.releaseDecisionOwner,
    required this.summary,
    required this.anchor,
  }) : criteria = List<Sprint118ClosureCriterion>.unmodifiable(criteria),
       missingEvidence = List<String>.unmodifiable(missingEvidence),
       violations = List<String>.unmodifiable(violations),
       openItems = List<String>.unmodifiable(openItems),
       limitations = List<String>.unmodifiable(limitations);

  final Sprint118ClosureState state;
  final Sprint118ClosureDecision decision;
  final String verdict;
  final List<Sprint118ClosureCriterion> criteria;
  final List<String> missingEvidence;
  final List<String> violations;
  final List<String> openItems;
  final List<String> limitations;
  final String releaseDecision;
  final String releaseDecisionOwner;
  final String summary;
  final Sprint118ClosureEvidenceAnchor? anchor;

  int get satisfiedCount =>
      criteria.where((criterion) => criterion.satisfied).length;

  int get deferredCount =>
      criteria.where((criterion) => criterion.deferred).length;

  List<String> get unmetCriteria => <String>[
    for (final criterion in criteria)
      if (criterion.unmet) criterion.name,
  ];

  bool get isClosed =>
      decision == Sprint118ClosureDecision.closedLocalDeferredExternal;

  bool get liveReleaseExecuted => false;

  Map<String, Object?> toJson() => <String, Object?>{
    'state': state.name,
    'decision': decision.name,
    'verdict': verdict,
    'release_decision': releaseDecision,
    'release_decision_owner': releaseDecisionOwner,
    'live_release_executed': liveReleaseExecuted,
    'criteria': <Map<String, Object?>>[
      for (final criterion in criteria) criterion.toJson(),
    ],
    'satisfied_count': satisfiedCount,
    'deferred_count': deferredCount,
    'unmet_criteria': List<String>.from(unmetCriteria),
    'deferred_criteria': [
      for (final criterion in criteria)
        if (criterion.deferred) criterion.name,
    ],
    'missing_evidence': List<String>.from(missingEvidence),
    'violations': List<String>.from(violations),
    'external_gates': Sprint118ClosureContract.externalGates,
    'open_items': List<String>.from(openItems),
    'limitations': List<String>.from(limitations),
    'summary': summary,
  };
}

abstract final class Sprint118ClosureContract {
  static const String canonicalStep = '118.46';
  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_sprint_closure.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const String closedDecision = 'CLOSED_LOCAL_DEFERRED_EXTERNAL';

  static const List<String> criteriaNames = <String>[
    'entry_gate_passed',
    'release_state_confirmed',
    'critical_incidents_resolved_or_connectors_disabled',
    'maintenance_decision_recorded',
    'expansion_certification_evidence_recorded',
    'report_complete',
    'next_direction_decided',
  ];

  /// Every 118 step witness is read before the closure is judged. The
  /// readiness gate is stored under its own canonical filename because it is
  /// the 118.45 record even though its document title is Sprint 119.
  static const List<String> sourceManifests = <String>[
    'docs/planning/v1.3/sprint_118_entry_gate.json',
    'docs/planning/v1.3/sprint_118_stability_expansion_charter.json',
    'docs/planning/v1.3/sprint_118_certified_connector_snapshot.json',
    'docs/planning/v1.3/sprint_118_post_release_health_baseline.json',
    'docs/planning/v1.3/sprint_118_privacy_safe_observation.json',
    'docs/planning/v1.3/sprint_118_incident_support_intake.json',
    'docs/planning/v1.3/sprint_118_connection_health_review.json',
    'docs/planning/v1.3/sprint_118_oauth_reauth_health.json',
    'docs/planning/v1.3/sprint_118_quota_storage_health.json',
    'docs/planning/v1.3/sprint_118_sync_backup_recovery_health.json',
    'docs/planning/v1.3/sprint_118_ai_provider_health.json',
    'docs/planning/v1.3/sprint_118_billing_entitlement_health.json',
    'docs/planning/v1.3/sprint_118_provider_icon_brand_health.json',
    'docs/planning/v1.3/sprint_118_responsive_ui_health.json',
    'docs/planning/v1.3/sprint_118_accessibility_health.json',
    'docs/planning/v1.3/sprint_118_performance_resource_health.json',
    'docs/planning/v1.3/sprint_118_provider_outage_recovery_review.json',
    'docs/planning/v1.3/sprint_118_security_health_review.json',
    'docs/planning/v1.3/sprint_118_privacy_health_review.json',
    'docs/planning/v1.3/sprint_118_permission_boundary_health.json',
    'docs/planning/v1.3/sprint_118_feedback_adoption_evidence_log.json',
    'docs/planning/v1.3/sprint_118_issue_deduplication_root_cause.json',
    'docs/planning/v1.3/sprint_118_critical_incident_response.json',
    'docs/planning/v1.3/sprint_118_stability_fixes.json',
    'docs/planning/v1.3/sprint_118_connector_disable_safe_degradation.json',
    'docs/planning/v1.3/sprint_118_maintenance_regression_matrix.json',
    'docs/planning/v1.3/sprint_118_rollout_progression_decision.json',
    'docs/planning/v1.3/sprint_118_maintenance_release_gate.json',
    'docs/planning/v1.3/sprint_118_provider_expansion_evidence_inventory.json',
    'docs/planning/v1.3/sprint_118_expansion_prioritization.json',
    'docs/planning/v1.3/sprint_118_api_terms_feasibility.json',
    'docs/planning/v1.3/sprint_118_brand_legal_readiness.json',
    'docs/planning/v1.3/sprint_118_identity_connector_expansion.json',
    'docs/planning/v1.3/sprint_118_storage_connector_expansion.json',
    'docs/planning/v1.3/sprint_118_ai_connector_expansion.json',
    'docs/planning/v1.3/sprint_118_developer_connector_expansion.json',
    'docs/planning/v1.3/sprint_118_creative_connector_expansion.json',
    'docs/planning/v1.3/sprint_118_payment_connector_expansion.json',
    'docs/planning/v1.3/sprint_118_versioned_connector_certification.json',
    'docs/planning/v1.3/sprint_118_expansion_contract_e2e.json',
    'docs/planning/v1.3/sprint_118_expansion_feature_flags_rollout.json',
    'docs/planning/v1.3/sprint_118_expansion_acceptance_gate.json',
    'docs/planning/v1.3/sprint_118_documentation_support_update.json',
    'docs/planning/v1.3/sprint_118_stability_expansion_report.json',
    'docs/planning/v1.3/sprint_119_readiness_gate.json',
  ];
}

abstract final class Sprint118SprintClosure {
  static List<Sprint118ClosureCriterion> deriveCriteria(
    Sprint118ClosureEvidenceAnchor anchor,
  ) {
    final entry =
        anchor.entryState == 'pass' &&
        anchor.entryExecutionAllowed &&
        anchor.correctiveScopeApproved;
    final release =
        anchor.releaseState == 'GA_DELAYED' &&
        anchor.charterState == 'pass' &&
        anchor.reportState == 'pass' &&
        anchor.readinessState == 'pass';
    final incidents =
        anchor.incidentState == 'pass' &&
        anchor.disableState == 'pass' &&
        !anchor.liveIncidentExecuted;
    final maintenance =
        anchor.fixesState == 'pass' &&
        anchor.maintenanceState == 'pass' &&
        const <String>[
          'NO_PATCH',
          'BUILD_1_3_1',
          'EMERGENCY_RELEASE_ALREADY_ISSUED',
        ].contains(anchor.maintenanceDecision);
    final expansion =
        anchor.snapshotState == 'pass' &&
        anchor.snapshotFrozen &&
        anchor.certificationState == 'pass' &&
        anchor.expansionAcceptanceState == 'pass' &&
        anchor.registeredProviderCount == 32 &&
        anchor.certifiedProviderCount == 0;
    final report =
        anchor.reportState == 'pass' &&
        anchor.reportVerified &&
        anchor.reportDeclaredSectionCount ==
            anchor.reportExpectedSectionCount &&
        anchor.reportExpectedSectionCount == 9;
    final direction =
        anchor.readinessState == 'pass' &&
        anchor.readinessVerified &&
        anchor.readinessDecision == 'CORRECTIVE_STABILIZATION' &&
        anchor.allLedgerStepsResolved;

    return <Sprint118ClosureCriterion>[
      Sprint118ClosureCriterion(
        name: Sprint118ClosureContract.criteriaNames[0],
        status: entry
            ? Sprint118ClosureCriterionStatus.satisfied
            : Sprint118ClosureCriterionStatus.unmet,
        evidence: const <String>[
          'docs/planning/v1.3/sprint_118_entry_gate.json',
          'docs/planning/v1.3/sprint_118_stability_expansion_charter.json',
        ],
        detail: entry
            ? 'Entry is pass, corrective scope is approved, and local execution is allowed.'
            : 'Entry evidence does not authorize the approved corrective scope.',
      ),
      Sprint118ClosureCriterion(
        name: Sprint118ClosureContract.criteriaNames[1],
        status: release
            ? Sprint118ClosureCriterionStatus.satisfied
            : Sprint118ClosureCriterionStatus.unmet,
        evidence: const <String>[
          'docs/planning/v1.3/sprint_118_entry_gate.json',
          'docs/planning/v1.3/sprint_118_stability_expansion_charter.json',
          'docs/planning/v1.3/sprint_118_stability_expansion_report.json',
          'docs/planning/v1.3/sprint_119_readiness_gate.json',
        ],
        detail: release
            ? 'The committed witnesses agree on GA_DELAYED; no live release is inferred.'
            : 'Release-state witnesses disagree or are not locally passing.',
      ),
      Sprint118ClosureCriterion(
        name: Sprint118ClosureContract.criteriaNames[2],
        status: incidents
            ? Sprint118ClosureCriterionStatus.satisfied
            : Sprint118ClosureCriterionStatus.unmet,
        evidence: const <String>[
          'docs/planning/v1.3/sprint_118_incident_support_intake.json',
          'docs/planning/v1.3/sprint_118_critical_incident_response.json',
          'docs/planning/v1.3/sprint_118_connector_disable_safe_degradation.json',
        ],
        detail: incidents
            ? 'No live incident was executed; response and safe-degradation plans are locally verified.'
            : 'Incident evidence is incomplete or claims a live incident.',
      ),
      Sprint118ClosureCriterion(
        name: Sprint118ClosureContract.criteriaNames[3],
        status: maintenance
            ? Sprint118ClosureCriterionStatus.satisfied
            : Sprint118ClosureCriterionStatus.unmet,
        evidence: const <String>[
          'docs/planning/v1.3/sprint_118_stability_fixes.json',
          'docs/planning/v1.3/sprint_118_maintenance_regression_matrix.json',
          'docs/planning/v1.3/sprint_118_maintenance_release_gate.json',
        ],
        detail: maintenance
            ? 'Maintenance decision is recorded as ${anchor.maintenanceDecision}.'
            : 'Maintenance evidence has no recognized decision.',
      ),
      Sprint118ClosureCriterion(
        name: Sprint118ClosureContract.criteriaNames[4],
        status: expansion
            ? Sprint118ClosureCriterionStatus.satisfied
            : Sprint118ClosureCriterionStatus.unmet,
        evidence: const <String>[
          'docs/planning/v1.3/sprint_118_certified_connector_snapshot.json',
          'docs/planning/v1.3/sprint_118_versioned_connector_certification.json',
          'docs/planning/v1.3/sprint_118_expansion_acceptance_gate.json',
        ],
        detail: expansion
            ? 'Certification evidence is recorded for 32 registered providers; 0 are certified on GA_DELAYED.'
            : 'Certification evidence is incomplete or provider counts drift.',
      ),
      Sprint118ClosureCriterion(
        name: Sprint118ClosureContract.criteriaNames[5],
        status: report
            ? Sprint118ClosureCriterionStatus.satisfied
            : Sprint118ClosureCriterionStatus.unmet,
        evidence: const <String>[
          'docs/planning/v1.3/sprint_118_stability_expansion_report.json',
        ],
        detail: report
            ? 'The stability and expansion record declares all nine canonical sections.'
            : 'The report is missing, incomplete, or not verified locally.',
      ),
      Sprint118ClosureCriterion(
        name: Sprint118ClosureContract.criteriaNames[6],
        status: direction
            ? Sprint118ClosureCriterionStatus.satisfied
            : Sprint118ClosureCriterionStatus.unmet,
        evidence: const <String>[
          'docs/planning/v1.3/sprint_119_readiness_gate.json',
          Sprint118ClosureContract.ledgerPath,
        ],
        detail: direction
            ? 'Next direction is CORRECTIVE_STABILIZATION and all prior 118 steps are resolved.'
            : 'The next direction or a prior 118 step is unresolved.',
      ),
    ];
  }

  static Sprint118ClosureReport evaluate({
    required Sprint118ClosureEvidenceAnchor anchor,
    String releaseDecision = 'DELAY',
    String releaseDecisionOwner = 'PENDING_OPERATOR',
  }) {
    final criteria = deriveCriteria(anchor);
    final violations = <String>[...anchor.sourceViolations];
    if (!anchor.allLedgerStepsResolved &&
        !violations.contains('prior_sprint_steps_unresolved')) {
      violations.add('prior_sprint_steps_unresolved');
    }
    final blocked =
        anchor.missingEvidence.isNotEmpty ||
        violations.isNotEmpty ||
        criteria.any((criterion) => criterion.unmet);
    return Sprint118ClosureReport(
      state: blocked
          ? Sprint118ClosureState.blocked
          : Sprint118ClosureState.pass,
      decision: blocked
          ? Sprint118ClosureDecision.blocked
          : Sprint118ClosureDecision.closedLocalDeferredExternal,
      verdict: blocked
          ? 'SPRINT_118_CLOSURE_BLOCKED_UNMET_DEFINITION_OF_DONE'
          : 'SPRINT_118_CLOSED_LOCAL_DEFERRED_EXTERNAL',
      criteria: criteria,
      missingEvidence: anchor.missingEvidence,
      violations: violations,
      openItems: const <String>[],
      limitations: const <String>[
        'No public release, publication, push, or live GA observation is claimed.',
        'Connector certification and external provider visibility remain deferred until an authorized release.',
        'Sprint 119 execution remains gated by its own entry contract and operator authorization.',
      ],
      releaseDecision: releaseDecision,
      releaseDecisionOwner: releaseDecisionOwner,
      summary: blocked
          ? 'Sprint 118 cannot close locally until every required evidence anchor and prior step is resolved.'
          : 'Sprint 118 is closed locally on the GA_DELAYED path; external release and certification gates remain deferred.',
      anchor: anchor,
    );
  }
}

class Sprint118SprintClosureGate {
  const Sprint118SprintClosureGate();

  Sprint118ClosureReport evaluate() {
    final anchor = const Sprint118ClosureLoader().load();
    if (anchor == null) {
      final missing = <String>[...Sprint118ClosureContract.sourceManifests];
      final fallback = Sprint118ClosureEvidenceAnchor(
        entryState: 'unreadable',
        entryExecutionAllowed: false,
        correctiveScopeApproved: false,
        releaseState: 'UNKNOWN',
        charterState: 'unreadable',
        snapshotState: 'unreadable',
        snapshotFrozen: false,
        registeredProviderCount: 0,
        certifiedProviderCount: 0,
        incidentState: 'unreadable',
        liveIncidentExecuted: false,
        disableState: 'unreadable',
        fixesState: 'unreadable',
        maintenanceState: 'unreadable',
        maintenanceDecision: '',
        certificationState: 'unreadable',
        expansionAcceptanceState: 'unreadable',
        reportState: 'unreadable',
        reportVerified: false,
        reportDeclaredSectionCount: 0,
        reportExpectedSectionCount: 0,
        readinessState: 'unreadable',
        readinessVerified: false,
        readinessDecision: '',
        allLedgerStepsResolved: false,
        missingEvidence: missing,
        sourceViolations: const <String>[],
        readableSourceCount: 0,
        ledgerPath: Sprint118ClosureContract.ledgerPath,
      );
      return Sprint118SprintClosure.evaluate(anchor: fallback);
    }
    return Sprint118SprintClosure.evaluate(anchor: anchor);
  }
}

class Sprint118ClosureLoader {
  const Sprint118ClosureLoader();

  Sprint118ClosureEvidenceAnchor? load() {
    final documents = <String, Map<String, dynamic>>{};
    final missing = <String>[];
    for (final path in Sprint118ClosureContract.sourceManifests) {
      final object = _readJsonObject(path);
      if (object == null) {
        missing.add(path);
      } else {
        documents[path] = object;
      }
    }
    final ledger = File(Sprint118ClosureContract.ledgerPath);
    final statuses = ledger.existsSync()
        ? _readLedgerStatuses(ledger)
        : <String, String>{};
    if (!ledger.existsSync()) missing.add(Sprint118ClosureContract.ledgerPath);
    final unresolved = <String>[];
    for (var step = 1; step <= 45; step++) {
      final id = '118.$step';
      final status = statuses[id];
      if (status == null) {
        unresolved.add('$id:missing');
      } else if (!_resolved(status)) {
        unresolved.add('$id:$status');
      }
    }
    // Sprint 119 may carry an authorized readiness overlay, but that overlay
    // must not rewrite the historical Sprint 118 closure handoff. The
    // committed 118.46 manifest is the frozen source for that handoff.
    final closureManifest = _readJsonObject(
      Sprint118ClosureContract.manifestPath,
    );
    if (closureManifest == null) {
      missing.add(Sprint118ClosureContract.manifestPath);
    }
    final sourceViolations = <String>[];
    for (final entry in documents.entries) {
      final violations = entry.value['violations'];
      if (violations is List) {
        for (final violation in violations) {
          final text = '$violation'.trim();
          if (text.isNotEmpty) sourceViolations.add('${entry.key}:$text');
        }
      }
      final blockers = entry.value['blockers'];
      if (blockers is List) {
        for (final blocker in blockers) {
          final text = '$blocker'.trim();
          if (text.isNotEmpty) {
            sourceViolations.add('${entry.key}:blocker:$text');
          }
        }
      }
    }
    if (unresolved.isNotEmpty) sourceViolations.addAll(unresolved);
    if (closureManifest == null ||
        documents.length != Sprint118ClosureContract.sourceManifests.length ||
        missing.isNotEmpty) {
      return null;
    }

    Map<String, dynamic> doc(String path) => documents[path]!;
    final entry = doc('docs/planning/v1.3/sprint_118_entry_gate.json');
    final charter = doc(
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json',
    );
    final snapshot = doc(
      'docs/planning/v1.3/sprint_118_certified_connector_snapshot.json',
    );
    final incident = doc(
      'docs/planning/v1.3/sprint_118_incident_support_intake.json',
    );
    final disable = doc(
      'docs/planning/v1.3/sprint_118_connector_disable_safe_degradation.json',
    );
    final fixes = doc('docs/planning/v1.3/sprint_118_stability_fixes.json');
    final maintenance = doc(
      'docs/planning/v1.3/sprint_118_maintenance_release_gate.json',
    );
    final certification = doc(
      'docs/planning/v1.3/sprint_118_versioned_connector_certification.json',
    );
    final expansion = doc(
      'docs/planning/v1.3/sprint_118_expansion_acceptance_gate.json',
    );
    final report = doc(
      'docs/planning/v1.3/sprint_118_stability_expansion_report.json',
    );
    final readiness = doc('docs/planning/v1.3/sprint_119_readiness_gate.json');
    final closureEvidenceAnchor = closureManifest['evidence_anchor'];
    final closureNextDirection = closureEvidenceAnchor is Map
        ? closureEvidenceAnchor['next_direction']
        : null;
    final historicalReadinessState = closureNextDirection is Map
        ? _text(closureNextDirection['state'])
        : '';
    final historicalReadinessVerified = closureNextDirection is Map
        ? closureNextDirection['verified'] == true
        : false;
    final historicalReadinessDecision = closureNextDirection is Map
        ? _text(closureNextDirection['decision'])
        : '';
    final declaredSections = report['declared_sections'];

    return Sprint118ClosureEvidenceAnchor(
      entryState: _text(entry['state']),
      entryExecutionAllowed: entry['execution_allowed'] == true,
      correctiveScopeApproved: entry['corrective_scope_approved'] == true,
      releaseState: _text(entry['release_state']),
      charterState: _text(charter['state']),
      snapshotState: _text(snapshot['state']),
      snapshotFrozen: snapshot['snapshot_frozen'] == true,
      registeredProviderCount: _int(snapshot['registered_provider_count']),
      certifiedProviderCount: _int(snapshot['evidence_certified']),
      incidentState: _text(incident['state']),
      liveIncidentExecuted: incident['live_incident_executed'] == true,
      disableState: _text(disable['state']),
      fixesState: _text(fixes['state']),
      maintenanceState: _text(maintenance['state']),
      maintenanceDecision: _text(maintenance['selected_decision']),
      certificationState: _text(certification['state']),
      expansionAcceptanceState: _text(expansion['state']),
      reportState: _text(report['state']),
      reportVerified: report['report_verified'] == true,
      reportDeclaredSectionCount: declaredSections is List
          ? declaredSections.length
          : 0,
      reportExpectedSectionCount: _int(report['expected_section_count']),
      readinessState: historicalReadinessState.isNotEmpty
          ? historicalReadinessState
          : _text(readiness['state']),
      readinessVerified: historicalReadinessState.isNotEmpty
          ? historicalReadinessVerified
          : readiness['readiness_verified'] == true,
      readinessDecision: historicalReadinessState.isNotEmpty
          ? historicalReadinessDecision
          : _text(readiness['readiness_decision']),
      allLedgerStepsResolved: unresolved.isEmpty,
      missingEvidence: missing,
      sourceViolations: sourceViolations,
      readableSourceCount: documents.length,
      ledgerPath: Sprint118ClosureContract.ledgerPath,
    );
  }

  static Map<String, dynamic>? _readJsonObject(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    } on IOException {
      return null;
    }
  }

  static Map<String, String> _readLedgerStatuses(File ledger) {
    final statuses = <String, String>{};
    for (final line in ledger.readAsLinesSync()) {
      final match = RegExp(
        r'^\|\s*(118\.\d+)\s*\|[^|]*\|\s*([^|]+)\|',
      ).firstMatch(line);
      if (match != null) statuses[match.group(1)!] = match.group(2)!.trim();
    }
    return statuses;
  }

  static bool _resolved(String status) => <String>{
    'VERIFIED-LOCAL',
    'VERIFIED',
    'BLOCKED',
    'DEFERRED',
  }.contains(status);

  static String _text(Object? value) => value is String ? value : '';

  static int _int(Object? value) => value is int ? value : 0;
}
