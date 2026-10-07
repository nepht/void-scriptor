// Emit the 118.1 entry-gate record from the gate's own report.
//
// The committed Sprint 117 witnesses (117.45 approval gate, 117.48 closure,
// 117.41 registry, 117.47 handoff) are the evidence *input*: the gate reads
// them and selects the release state. This file is the *output*: the gate's
// measured verdict over that evidence. Nothing here is typed by hand -- every
// field is derived from the report or read back from the contract, so the
// record cannot be made to agree with itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_entry_gate.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_entry_gate.dart';

void main() {
  const gate = Sprint118EntryGate();
  final report = gate.evaluate();
  final evidence = const Sprint118EntryLoader().load();

  final record = <String, Object?>{
    'canonical_step': Sprint118EntryContract.canonicalStep,
    'title': 'Sprint Entry & Release-State Gate',
    'document_role': 'gate-evaluation-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseStateWord,
    'execution_allowed': report.executionAllowed,
    'required_evidence': Sprint118EntryContract.requiredEvidence,
    'missing_evidence': report.missingEvidence,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed sources this gate reads, from the contract constants --
    // not retyped, so the record cannot cite a path the gate never opens.
    'evidence_sources': <String, String>{
      'sprint_117_decision': Sprint118EntryContract.approvalGatePath,
      'release_state': Sprint118EntryContract.closurePath,
      'artifact_version': Sprint118EntryContract.pubspecPath,
      'visible_connector_subset': Sprint118EntryContract.registryPath,
      'known_issues': Sprint118EntryContract.closurePath,
      'rollback_state': Sprint118EntryContract.rollbackDrillPath,
    },
    // Facts read from the committed witnesses, never typed.
    'approval_decision': evidence?.approvalDecision,
    'closure_decision': evidence?.closureDecision,
    'approval_state': evidence?.approvalState,
    'execution_authorized': evidence?.executionAuthorized,
    'release_decision_owner': evidence?.releaseDecisionOwner,
    'certified_count': evidence?.certifiedCount,
    'limited_count': evidence?.limitedCount,
    'provider_count': evidence?.providerCount,
    'corrective_scope_approved': evidence?.correctiveScopeApproved,
    'observation_window_active': evidence?.observationWindowActive,
    'artifact_version': evidence?.artifactVersion,
    'rollback_executed': evidence?.rollbackExecuted,
    'claim_boundary': <String>[
      'This record is the gate verdict over committed Sprint 117 evidence. A pass on GA_DELAYED authorizes only the approved local corrective scope; it is not a release activation. No connector was certified and no release state was changed.',
      'The gate reads the committed 117 witnesses directly rather than trusting any self-declared readiness flag, and it fails if the approval gate and the closure manifest disagree about the decision.',
      'A delayed 117 does not open the sprint without an approved corrective scope; an absent approval is undetermined, never permission.',
      'An unreadable witness or an unknown decision word keeps the gate closed. Certified connectors and release authorization remain mandatory for GA_RELEASED; nothing here publishes, signs, certifies, or activates anything.',
    ],
    'external_gates': <String>[
      'hosted CI runner',
      'certified connector subset',
      'corrective scope approval',
      'live beta execution',
      'public release publication',
    ],
  };

  final target = File(Sprint118EntryContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );

  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('release_state=${report.releaseStateWord}');
  stdout.writeln('blockers=${report.blockers.length}');
  stdout.writeln('violations=${report.violations.length}');
  stdout.writeln('written=${target.path}');
}
