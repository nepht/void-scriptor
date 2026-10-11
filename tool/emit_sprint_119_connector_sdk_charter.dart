// Emit the 119.2 Connector SDK Charter from the contract evaluator.
//
// Run from the repository root:
//   dart run tool/emit_sprint_119_connector_sdk_charter.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_119_connector_sdk_charter.dart';

Map<String, Object?> _useCase(Sprint119SdkUseCase item) => <String, Object?>{
  'use_case_id': item.useCaseId,
  'audience_id': item.audienceId,
  'capability': item.capability,
  'outcome': item.outcome,
};

Map<String, Object?> _audience(Sprint119SdkAudience item) => <String, Object?>{
  'audience_id': item.audienceId,
  'role': item.role,
  'needs': item.needs,
};

Map<String, Object?> _boundary(Sprint119SdkBoundary item) => <String, Object?>{
  'boundary_id': item.boundaryId,
  'category': item.category,
  'rule': item.rule,
  'enforcement': item.enforcement,
};

Map<String, Object?> _nonGoal(Sprint119SdkNonGoal item) => <String, Object?>{
  'non_goal_id': item.nonGoalId,
  'statement': item.statement,
  'reason': item.reason,
};

Map<String, Object?> _metric(Sprint119SdkMetric item) => <String, Object?>{
  'metric_id': item.metricId,
  'name': item.name,
  'target': item.target,
  'measurement': item.measurement,
  'source': item.source,
};

Map<String, Object?> _exit(Sprint119SdkExitCriterion item) => <String, Object?>{
  'criterion_id': item.criterionId,
  'gate': item.gate,
  'description': item.description,
  'evidence': item.evidence,
  'requires_evidence': item.requiresEvidence,
};

void main() {
  const gate = Sprint119SdkCharterGate();
  final report = gate.evaluate();
  final anchor = const Sprint119SdkCharterLoader().loadAnchor();
  final charter = Sprint119SdkCharterContract.canonicalCharter;

  final record = <String, Object?>{
    'canonical_step': Sprint119SdkCharterContract.canonicalStep,
    'title': Sprint119SdkCharterContract.title,
    'document_role': 'charter-evaluation-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'charter_executable': report.charterExecutable,
    'required_fields': Sprint119SdkCharterContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'evidence_sources': <String, String>{
      'entry_gate': Sprint119SdkCharterContract.entryManifestPath,
    },
    'entry_state': anchor?.entryState,
    'entry_verdict': anchor?.entryVerdict,
    'entry_execution_allowed': anchor?.executionAllowed,
    'use_cases': charter.useCases.map(_useCase).toList(),
    'audiences': charter.audiences.map(_audience).toList(),
    'boundaries': charter.boundaries.map(_boundary).toList(),
    'non_goals': charter.nonGoals.map(_nonGoal).toList(),
    'metrics': charter.metrics.map(_metric).toList(),
    'exit_criteria': charter.exitCriteria.map(_exit).toList(),
    'claim_boundary': <String>[
      'This local record defines the Connector SDK charter; it does not install, execute, certify, expose, release, or publish a connector.',
      'Permission defaults, opaque secrets, scoped data, declared network access, approved UI slots, and separate release gates are contract boundaries, not live provider observations.',
      'Certification, provider exposure, external telemetry, signing, publication, and release remain DEFERRED-EXTERNAL.',
      'The authorized GitHub certification example does not authorize claims for other providers or bypass the later trust, manifest, runtime, and release gates.',
    ],
    'external_gates': <String>[
      'live connector execution',
      'provider certification',
      'provider exposure',
      'external telemetry',
      'signed publication and release',
    ],
  };

  final target = File(Sprint119SdkCharterContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );

  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('charter_executable=${report.charterExecutable}');
  stdout.writeln(
    'required_fields=${Sprint119SdkCharterContract.requiredFields.length}',
  );
  stdout.writeln('missing_fields=${report.missingFields.length}');
  stdout.writeln('violations=${report.violations.length}');
  stdout.writeln('written=${target.path}');
}
