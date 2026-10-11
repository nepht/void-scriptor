/// Fail-closed contract for roadmap step 119.2 -- Connector SDK Charter.
///
/// This step records the intended connector use cases and their limits. It
/// does not install, certify, expose, or execute a connector. Live provider
/// health, credentials, publication, and release remain external gates.
library;

import 'dart:convert';
import 'dart:io';

enum Sprint119SdkCharterState { pass, fail, blocked }

class Sprint119SdkUseCase {
  const Sprint119SdkUseCase({
    required this.useCaseId,
    required this.audienceId,
    required this.capability,
    required this.outcome,
  });

  final String useCaseId;
  final String audienceId;
  final String capability;
  final String outcome;
}

class Sprint119SdkAudience {
  const Sprint119SdkAudience({
    required this.audienceId,
    required this.role,
    required this.needs,
  });

  final String audienceId;
  final String role;
  final String needs;
}

class Sprint119SdkBoundary {
  const Sprint119SdkBoundary({
    required this.boundaryId,
    required this.category,
    required this.rule,
    required this.enforcement,
  });

  final String boundaryId;
  final String category;
  final String rule;
  final String enforcement;
}

class Sprint119SdkNonGoal {
  const Sprint119SdkNonGoal({
    required this.nonGoalId,
    required this.statement,
    required this.reason,
  });

  final String nonGoalId;
  final String statement;
  final String reason;
}

class Sprint119SdkMetric {
  const Sprint119SdkMetric({
    required this.metricId,
    required this.name,
    required this.target,
    required this.measurement,
    required this.source,
  });

  final String metricId;
  final String name;
  final String target;
  final String measurement;
  final String source;
}

class Sprint119SdkExitCriterion {
  const Sprint119SdkExitCriterion({
    required this.criterionId,
    required this.gate,
    required this.description,
    required this.evidence,
    this.requiresEvidence = true,
  });

  final String criterionId;
  final String gate;
  final String description;
  final String evidence;
  final bool requiresEvidence;
}

class Sprint119ConnectorSdkCharter {
  const Sprint119ConnectorSdkCharter({
    required this.useCases,
    required this.audiences,
    required this.boundaries,
    required this.nonGoals,
    required this.metrics,
    required this.exitCriteria,
  });

  final List<Sprint119SdkUseCase> useCases;
  final List<Sprint119SdkAudience> audiences;
  final List<Sprint119SdkBoundary> boundaries;
  final List<Sprint119SdkNonGoal> nonGoals;
  final List<Sprint119SdkMetric> metrics;
  final List<Sprint119SdkExitCriterion> exitCriteria;
}

class Sprint119SdkCharterAnchor {
  const Sprint119SdkCharterAnchor({
    required this.entryState,
    required this.entryVerdict,
    required this.executionAllowed,
  });

  final String entryState;
  final String entryVerdict;
  final bool executionAllowed;
}

class Sprint119SdkCharterReport {
  const Sprint119SdkCharterReport({
    required this.state,
    required this.verdict,
    required this.charterExecutable,
    required this.externalGates,
    this.missingFields = const <String>[],
    this.violations = const <String>[],
    this.blockers = const <String>[],
  });

  final Sprint119SdkCharterState state;
  final String verdict;
  final bool charterExecutable;
  final String externalGates;
  final List<String> missingFields;
  final List<String> violations;
  final List<String> blockers;
}

class Sprint119SdkCharterContract {
  const Sprint119SdkCharterContract();

  static const String canonicalStep = '119.2';
  static const String title = 'Connector SDK Charter';
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_connector_sdk_charter.json';
  static const String entryManifestPath =
      'docs/planning/v1.3/sprint_119_entry_gate.json';
  static const String requiredEntryVerdict = 'SPRINT_119_ENTRY_READY_LOCAL';
  static const String externalGates = 'DEFERRED-EXTERNAL';

  static const List<String> requiredFields = <String>[
    'use_cases',
    'audiences',
    'boundaries',
    'non_goals',
    'metrics',
    'exit_criteria',
  ];

  static const List<String> requiredExitGates = <String>[
    'use_cases_bounded',
    'audiences_named',
    'boundaries_defined',
    'non_goals_recorded',
    'metrics_measurable',
    'external_work_deferred',
  ];

  static const Sprint119SdkCharterAnchor canonicalAnchor =
      Sprint119SdkCharterAnchor(
        entryState: 'pass',
        entryVerdict: requiredEntryVerdict,
        executionAllowed: true,
      );

  static const Sprint119ConnectorSdkCharter
  canonicalCharter = Sprint119ConnectorSdkCharter(
    useCases: <Sprint119SdkUseCase>[
      Sprint119SdkUseCase(
        useCaseId: 'authorized_connect',
        audienceId: 'writer',
        capability: 'connect',
        outcome:
            'connect only after explicit permission and visible scope review',
      ),
      Sprint119SdkUseCase(
        useCaseId: 'scoped_resource_read',
        audienceId: 'writer',
        capability: 'read',
        outcome:
            'read an allowed resource through a brokered, auditable handle',
      ),
      Sprint119SdkUseCase(
        useCaseId: 'connection_diagnosis',
        audienceId: 'operator',
        capability: 'health',
        outcome: 'diagnose health without exposing credentials or content',
      ),
      Sprint119SdkUseCase(
        useCaseId: 'contract_validation',
        audienceId: 'developer',
        capability: 'contract_test',
        outcome: 'validate a connector against deterministic local contracts',
      ),
    ],
    audiences: <Sprint119SdkAudience>[
      Sprint119SdkAudience(
        audienceId: 'writer',
        role: 'writer',
        needs: 'safe, understandable account and project capabilities',
      ),
      Sprint119SdkAudience(
        audienceId: 'workspace_admin',
        role: 'workspace administrator',
        needs: 'permission review, disable, revoke, and support visibility',
      ),
      Sprint119SdkAudience(
        audienceId: 'operator',
        role: 'support and reliability operator',
        needs: 'health, diagnostics, incident containment, and audit evidence',
      ),
      Sprint119SdkAudience(
        audienceId: 'developer',
        role: 'connector developer',
        needs: 'typed contracts, mocks, diagnostics, and fail-closed tests',
      ),
    ],
    boundaries: <Sprint119SdkBoundary>[
      Sprint119SdkBoundary(
        boundaryId: 'permission_default_deny',
        category: 'security',
        rule: 'undeclared capabilities and destinations are denied',
        enforcement: 'manifest validation and broker policy',
      ),
      Sprint119SdkBoundary(
        boundaryId: 'secret_opaque',
        category: 'security',
        rule: 'connectors never receive plaintext secrets or tokens',
        enforcement: 'opaque secret references and redacted diagnostics',
      ),
      Sprint119SdkBoundary(
        boundaryId: 'scoped_data_access',
        category: 'data',
        rule:
            'novel, character, project, and account data stay separately scoped',
        enforcement: 'brokered handles, consent, and audit records',
      ),
      Sprint119SdkBoundary(
        boundaryId: 'network_allowlist',
        category: 'runtime',
        rule:
            'network access is limited to declared destinations and protocols',
        enforcement: 'broker policy with denial diagnostics',
      ),
      Sprint119SdkBoundary(
        boundaryId: 'ui_extension_slots',
        category: 'ui',
        rule:
            'connectors use approved Account Center slots, not arbitrary layout injection',
        enforcement: 'typed extension points and visual regression coverage',
      ),
      Sprint119SdkBoundary(
        boundaryId: 'external_release_gate',
        category: 'release',
        rule:
            'certification, provider exposure, publication, and release stay gated',
        enforcement: 'separate evidence and operator approval gates',
      ),
    ],
    nonGoals: <Sprint119SdkNonGoal>[
      Sprint119SdkNonGoal(
        nonGoalId: 'public_marketplace',
        statement: 'ship a public connector marketplace',
        reason: 'requires external review, publication, and support evidence',
      ),
      Sprint119SdkNonGoal(
        nonGoalId: 'arbitrary_connector_execution',
        statement: 'run arbitrary third-party code in the desktop process',
        reason: 'violates sandbox and failure-isolation boundaries',
      ),
      Sprint119SdkNonGoal(
        nonGoalId: 'plaintext_secret_access',
        statement:
            'expose passwords, tokens, or API keys to connectors or logs',
        reason:
            'the security contract requires opaque references and redaction',
      ),
      Sprint119SdkNonGoal(
        nonGoalId: 'silent_telemetry',
        statement: 'collect connector or writing telemetry without consent',
        reason: 'privacy and consent are explicit product boundaries',
      ),
      Sprint119SdkNonGoal(
        nonGoalId: 'provider_certification',
        statement: 'certify a new provider from the charter alone',
        reason:
            'certification requires its own live or otherwise authorized evidence',
      ),
      Sprint119SdkNonGoal(
        nonGoalId: 'release_publication',
        statement: 'publish or release an SDK package from this local contract',
        reason:
            'release authorization, signing, and external gates are separate',
      ),
    ],
    metrics: <Sprint119SdkMetric>[
      Sprint119SdkMetric(
        metricId: 'charter_completeness',
        name: 'required charter fields complete',
        target: '100% of six required fields are populated',
        measurement: 'gate report missing_fields count',
        source: 'local charter evaluator',
      ),
      Sprint119SdkMetric(
        metricId: 'permission_default_deny',
        name: 'undeclared capability denial',
        target: '100% of undeclared capability requests are denied',
        measurement: 'contract test result',
        source: 'manifest and broker tests',
      ),
      Sprint119SdkMetric(
        metricId: 'secret_exposure_zero',
        name: 'plaintext secret exposure',
        target: '0 plaintext secrets in connector inputs and diagnostics',
        measurement: 'redaction and boundary test result',
        source: 'security test evidence',
      ),
      Sprint119SdkMetric(
        metricId: 'data_scope_integrity',
        name: 'cross-scope data access',
        target: '0 unauthorized cross-scope reads or writes',
        measurement: 'broker access decision result',
        source: 'data boundary tests',
      ),
      Sprint119SdkMetric(
        metricId: 'kill_switch_coverage',
        name: 'connector disable coverage',
        target: '100% of connectable providers have a defined disable path',
        measurement: 'manifest and runtime capability inventory',
        source: 'connector health and safety gate',
      ),
      Sprint119SdkMetric(
        metricId: 'contract_regression',
        name: 'contract regression status',
        target: '0 failing focused tests before a charter exit decision',
        measurement: 'focused test and analyzer result',
        source: 'local verification pipeline',
      ),
    ],
    exitCriteria: <Sprint119SdkExitCriterion>[
      Sprint119SdkExitCriterion(
        criterionId: 'exit_use_cases',
        gate: 'use_cases_bounded',
        description:
            'Each supported use case names one capability and outcome.',
        evidence: 'canonical charter manifest and evaluator report',
      ),
      Sprint119SdkExitCriterion(
        criterionId: 'exit_audiences',
        gate: 'audiences_named',
        description: 'Each audience has a role and a concrete product need.',
        evidence: 'canonical audience list in the charter manifest',
      ),
      Sprint119SdkExitCriterion(
        criterionId: 'exit_boundaries',
        gate: 'boundaries_defined',
        description:
            'Security, data, runtime, UI, and release boundaries name enforcement.',
        evidence: 'boundary list and boundary-focused tests',
      ),
      Sprint119SdkExitCriterion(
        criterionId: 'exit_non_goals',
        gate: 'non_goals_recorded',
        description: 'Unsafe or externally gated work is explicitly excluded.',
        evidence: 'canonical non-goal list in the charter manifest',
      ),
      Sprint119SdkExitCriterion(
        criterionId: 'exit_metrics',
        gate: 'metrics_measurable',
        description:
            'Every success metric has a target, measurement, and source.',
        evidence: 'metric definitions and focused evaluator tests',
      ),
      Sprint119SdkExitCriterion(
        criterionId: 'exit_external_boundary',
        gate: 'external_work_deferred',
        description:
            'Certification, provider exposure, publication, and release remain separate gates.',
        evidence: 'claim boundary and external gate record',
      ),
    ],
  );
}

class Sprint119SdkCharterLoader {
  const Sprint119SdkCharterLoader();

  Sprint119SdkCharterAnchor? loadAnchor() {
    final file = File(Sprint119SdkCharterContract.entryManifestPath);
    if (!file.existsSync()) return null;

    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) return null;
      return Sprint119SdkCharterAnchor(
        entryState: _text(decoded['state']),
        entryVerdict: _text(decoded['verdict']),
        executionAllowed: decoded['execution_allowed'] == true,
      );
    } on Object {
      return null;
    }
  }
}

class Sprint119SdkCharterGate {
  const Sprint119SdkCharterGate();

  Sprint119SdkCharterReport evaluate() {
    return evaluateWith(
      const Sprint119SdkCharterLoader().loadAnchor(),
      Sprint119SdkCharterContract.canonicalCharter,
    );
  }

  Sprint119SdkCharterReport evaluateWith(
    Sprint119SdkCharterAnchor? anchor,
    Sprint119ConnectorSdkCharter charter,
  ) {
    if (anchor == null) {
      return const Sprint119SdkCharterReport(
        state: Sprint119SdkCharterState.blocked,
        verdict: 'SPRINT_119_SDK_CHARTER_EVIDENCE_UNREADABLE',
        charterExecutable: false,
        externalGates: Sprint119SdkCharterContract.externalGates,
        blockers: <String>['committed_entry_evidence_unreadable'],
      );
    }

    final blockers = <String>[];
    if (anchor.entryState != 'pass' ||
        anchor.entryVerdict !=
            Sprint119SdkCharterContract.requiredEntryVerdict ||
        !anchor.executionAllowed) {
      blockers.add('committed_entry_gate_not_ready');
    }
    if (blockers.isNotEmpty) {
      return Sprint119SdkCharterReport(
        state: Sprint119SdkCharterState.blocked,
        verdict: 'SPRINT_119_SDK_CHARTER_ENTRY_BLOCKED',
        charterExecutable: false,
        externalGates: Sprint119SdkCharterContract.externalGates,
        blockers: blockers,
      );
    }

    final missingFields = <String>[];
    final fieldLengths = <String, int>{
      'use_cases': charter.useCases.length,
      'audiences': charter.audiences.length,
      'boundaries': charter.boundaries.length,
      'non_goals': charter.nonGoals.length,
      'metrics': charter.metrics.length,
      'exit_criteria': charter.exitCriteria.length,
    };
    for (final field in Sprint119SdkCharterContract.requiredFields) {
      if ((fieldLengths[field] ?? 0) == 0) missingFields.add(field);
    }
    if (missingFields.isNotEmpty) {
      return Sprint119SdkCharterReport(
        state: Sprint119SdkCharterState.blocked,
        verdict: 'SPRINT_119_SDK_CHARTER_FIELDS_MISSING',
        charterExecutable: false,
        externalGates: Sprint119SdkCharterContract.externalGates,
        missingFields: missingFields,
      );
    }

    final violations = <String>[];
    _addDuplicateViolations(
      violations,
      'audience',
      charter.audiences.map((item) => item.audienceId),
    );
    _addDuplicateViolations(
      violations,
      'use_case',
      charter.useCases.map((item) => item.useCaseId),
    );
    _addDuplicateViolations(
      violations,
      'boundary',
      charter.boundaries.map((item) => item.boundaryId),
    );
    _addDuplicateViolations(
      violations,
      'non_goal',
      charter.nonGoals.map((item) => item.nonGoalId),
    );
    _addDuplicateViolations(
      violations,
      'metric',
      charter.metrics.map((item) => item.metricId),
    );
    _addDuplicateViolations(
      violations,
      'exit_criterion',
      charter.exitCriteria.map((item) => item.criterionId),
    );

    final audienceIds = charter.audiences
        .map((item) => item.audienceId)
        .toSet();
    for (final useCase in charter.useCases) {
      if (!audienceIds.contains(useCase.audienceId)) {
        violations.add('use_case_audience_unknown:${useCase.useCaseId}');
      }
      if (_isBlank(useCase.capability)) {
        violations.add('use_case_capability_missing:${useCase.useCaseId}');
      }
      if (_isBlank(useCase.outcome)) {
        violations.add('use_case_outcome_missing:${useCase.useCaseId}');
      }
    }
    for (final audience in charter.audiences) {
      if (_isBlank(audience.role) || _isBlank(audience.needs)) {
        violations.add('audience_definition_missing:${audience.audienceId}');
      }
    }
    for (final boundary in charter.boundaries) {
      if (_isBlank(boundary.category) ||
          _isBlank(boundary.rule) ||
          _isBlank(boundary.enforcement)) {
        violations.add('boundary_definition_missing:${boundary.boundaryId}');
      }
    }
    for (final nonGoal in charter.nonGoals) {
      if (_isBlank(nonGoal.statement) || _isBlank(nonGoal.reason)) {
        violations.add('non_goal_definition_missing:${nonGoal.nonGoalId}');
      }
    }
    for (final metric in charter.metrics) {
      if (_isBlank(metric.name) ||
          _isBlank(metric.target) ||
          _isBlank(metric.measurement) ||
          _isBlank(metric.source)) {
        violations.add('metric_target_missing:${metric.metricId}');
      }
    }

    final exitGates = charter.exitCriteria.map((item) => item.gate).toSet();
    for (final gate in Sprint119SdkCharterContract.requiredExitGates) {
      if (!exitGates.contains(gate)) violations.add('exit_gate_missing:$gate');
    }
    for (final criterion in charter.exitCriteria) {
      if (_isBlank(criterion.description) ||
          _isBlank(criterion.evidence) ||
          !criterion.requiresEvidence) {
        violations.add('exit_evidence_missing:${criterion.criterionId}');
      }
    }

    if (violations.isNotEmpty) {
      return Sprint119SdkCharterReport(
        state: Sprint119SdkCharterState.fail,
        verdict: 'SPRINT_119_SDK_CHARTER_INVALID',
        charterExecutable: false,
        externalGates: Sprint119SdkCharterContract.externalGates,
        violations: violations,
      );
    }

    return const Sprint119SdkCharterReport(
      state: Sprint119SdkCharterState.pass,
      verdict: 'CHARTER_COMPLETE_LOCAL',
      charterExecutable: true,
      externalGates: Sprint119SdkCharterContract.externalGates,
    );
  }
}

void _addDuplicateViolations(
  List<String> violations,
  String label,
  Iterable<String> ids,
) {
  final seen = <String>{};
  final reported = <String>{};
  for (final id in ids) {
    if (!seen.add(id) && reported.add(id)) {
      violations.add('duplicate_${label}_id:$id');
    }
  }
}

bool _isBlank(String value) => value.trim().isEmpty;

String _text(Object? value) => value is String ? value : '';
