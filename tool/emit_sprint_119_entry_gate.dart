// Emit the Sprint 119.1 entry gate from the domain contract.
// Run from the repository root:
//   dart run tool/emit_sprint_119_entry_gate.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_119_entry_gate.dart';

void main() {
  const gate = Sprint119EntryGate();
  final report = gate.evaluate();
  final manifest = <String, Object?>{
    'canonical_step': Sprint119EntryContract.canonicalStep,
    'title': 'Sprint 119 Entry Gate',
    'document_role': 'sprint-119-entry-gate-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'execution_allowed': report.executionAllowed,
    'corrective_execution_allowed': report.correctiveExecutionAllowed,
    'execution_mode': report.executionMode,
    'active_sprint_unchanged': report.activeSprintUnchanged,
    'next_step': Sprint119EntryContract.nextStep,
    'required_evidence': Sprint119EntryContract.requiredEvidence,
    'required_sources': Sprint119EntryContract.requiredSources,
    'canonical_sources': Sprint119EntryContract.canonicalSources,
    'criteria': report.criteria.map((criterion) => criterion.toJson()).toList(),
    'satisfied_count': report.satisfiedCount,
    'blocked_count': report.blockedCount,
    'blockers': report.blockers,
    'missing_evidence': report.missingEvidence,
    'violations': report.violations,
    'notes': report.notes,
    'claim_boundary': <String>[
      'This gate only decides whether Sprint 119.1 may be admitted; it does not activate Sprint 119, publish a connector, expose a provider, or authorize a release.',
      'Local Sprint 118 closure alone is not live stability; this gate accepts only a measured live Account Center observation for that dimension, while connector certification, release, and expansion remain blocked until their own evidence is present.',
      'The active Hermes sprint remains 118 while this gate is blocked. SDK, sandbox, signed packaging, catalog, and self-service expansion steps remain unopened.',
      'When corrective_execution_allowed is true, Hermes may run only the approved Sprint 118 local corrective scope; it must not activate Sprint 119 expansion, certify a connector, expose a provider, release, or publish.',
      'No secret, credential, provider token, or live account data is read by this gate.',
    ],
    'external_gates': <String>[
      'live Account Center stability observation',
      'connector certification example',
      'release authorization',
      'Sprint 119 execution authorization',
    ],
  };
  final target = File(Sprint119EntryContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );

  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln(
    'corrective_execution_allowed=${report.correctiveExecutionAllowed}',
  );
  stdout.writeln('execution_mode=${report.executionMode}');
  stdout.writeln('active_sprint_unchanged=${report.activeSprintUnchanged}');
  stdout.writeln('satisfied_count=${report.satisfiedCount}');
  stdout.writeln('blocked_count=${report.blockedCount}');
  stdout.writeln('blockers=${report.blockers.join(',')}');
  stdout.writeln('written=${target.path}');
}
