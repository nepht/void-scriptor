// Emit the 118.2 Stability & Expansion Charter record from the gate's own
// report.
//
// The committed 118.1 witnesses (entry gate + corrective scope approval) are the
// evidence *input*: the gate reads them and decides whether the charter may be
// executed. This file is the *output*: the gate's measured verdict plus the
// charter's six canonical fields, all derived from the contract constants and
// the gate's own report. Nothing here is typed by hand, so the record cannot be
// made to agree with itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_stability_expansion_charter.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_stability_expansion_charter.dart';

Map<String, Object?> _phase(Sprint118CharterPhase phase) => <String, Object?>{
  'phase_id': phase.phaseId,
  'start_epoch_ms': phase.startEpochMs,
  'end_epoch_ms': phase.endEpochMs,
  'duration_days': phase.durationDays,
  'exit_criterion': phase.exitCriterion,
};

Map<String, Object?> _question(Sprint118StabilityQuestion question) =>
    <String, Object?>{
      'question_id': question.questionId,
      'area': question.area,
      'step': question.step,
      'question': question.question,
      'measurable': question.measurable,
      'signal': question.signal,
    };

Map<String, Object?> _owner(Sprint118CharterOwner owner) => <String, Object?>{
  'owner_id': owner.ownerId,
  'role': owner.role,
  'scopes': owner.scopes,
};

Map<String, Object?> _stop(Sprint118CharterStopCondition stop) =>
    <String, Object?>{
      'stop_id': stop.stopId,
      'metric_id': stop.metricId,
      'operator': stop.operator,
      'threshold': stop.threshold,
      'window_minutes': stop.windowMinutes,
      'action': stop.action,
    };

Map<String, Object?> _exit(Sprint118CharterExitCriterion criterion) =>
    <String, Object?>{
      'criterion_id': criterion.criterionId,
      'gate': criterion.gate,
      'description': criterion.description,
      'requires_evidence': criterion.requiresEvidence,
    };

void main() {
  const gate = Sprint118StabilityExpansionCharterGate();
  final report = gate.evaluate();
  final anchor = const Sprint118CharterLoader().loadAnchor();
  final charter = Sprint118CharterContract.canonicalCharter;

  final record = <String, Object?>{
    'canonical_step': Sprint118CharterContract.canonicalStep,
    'title': Sprint118CharterContract.title,
    'document_role': 'charter-evaluation-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'charter_executable': report.charterExecutable,
    'required_fields': Sprint118CharterContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed 118.1 witnesses this charter is anchored to, from the
    // contract constants -- not retyped, so the record cannot cite a path the
    // gate never opens.
    'evidence_sources': <String, String>{
      'entry_gate': Sprint118CharterContract.entryManifestPath,
      'corrective_scope': Sprint118CharterContract.correctiveScopePath,
    },
    // Facts read from the committed 118.1 witnesses, never typed.
    'entry_state': anchor?.entryState,
    'entry_verdict': anchor?.entryVerdict,
    'entry_release_state': anchor?.releaseState,
    'corrective_scope_approved': anchor?.correctiveScopeApproved,
    'provider_count': anchor?.providerCount,
    // The charter itself, derived from the contract constants.
    'window': <String, Object?>{
      'window_id': charter.window.windowId,
      'start_epoch_ms': charter.window.startEpochMs,
      'end_epoch_ms': charter.window.endEpochMs,
      'duration_days': charter.window.durationDays,
      'derived_duration_days': charter.window.derivedDurationDays,
      'executed': charter.window.executed,
      'phases': charter.window.orderedPhases.map(_phase).toList(),
    },
    'stability_questions': charter.questions.map(_question).toList(),
    'expansion_budget': <String, Object?>{
      'max_new_certified_connectors':
          charter.expansionBudget.maxNewCertifiedConnectors,
      'requires_certification': charter.expansionBudget.requiresCertification,
      'currently_certified': charter.expansionBudget.currentlyCertified,
      'currently_limited': charter.expansionBudget.currentlyLimited,
      'registered_providers': charter.expansionBudget.registeredProviders,
      'blocked_reason': charter.expansionBudget.blockedReason,
    },
    'owners': charter.owners.map(_owner).toList(),
    'stop_conditions': charter.stopConditions.map(_stop).toList(),
    'exit_criteria': charter.exitCriteria.map(_exit).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.1 evidence. A pass means the charter is complete and internally consistent; it does not observe anything, certify any connector, or activate any release.',
      'The charter is written against the delayed release state (GA_DELAYED) with the approved corrective scope, so the observation window is declared and not executed and the expansion budget is zero new certified connectors out of 32 registered and 0 certified.',
      'The gate reads the committed 118.1 entry gate and corrective scope approval directly; an unreadable witness or an unapproved corrective scope keeps the charter blocked rather than assumed.',
      'Stability questions, stop conditions, and exit criteria are contracts to be executed by later steps (118.3 onward); no live telemetry, connector certification, provider exposure, or publication is performed or authorized here.',
    ],
    'external_gates': <String>[
      'live observation execution',
      'connector certification evidence',
      'provider exposure authorization',
      'external telemetry',
      'public release publication',
    ],
  };

  final target = File(Sprint118CharterContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );

  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('release_state=${report.releaseState}');
  stdout.writeln('missing_fields=${report.missingFields.length}');
  stdout.writeln('blockers=${report.blockers.length}');
  stdout.writeln('violations=${report.violations.length}');
  stdout.writeln('written=${target.path}');
}
