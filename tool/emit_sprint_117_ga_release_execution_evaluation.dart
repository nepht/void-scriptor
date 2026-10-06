// Emit the 117.46 evaluation record from the gate's own report.
//
// The execution manifest (sprint_117_ga_release_execution.json) is the
// evidence *input*: it records what the step claims and cites the paths that
// back each claim. This file is the *output*: the gate's measured verdict over
// that evidence. Keeping them separate is the point -- if the verdict were
// written back into the manifest it read, the record could be made to agree
// with itself, which is exactly the fail-open drift the gate exists to catch.
//
// Run from the repository root:
//   dart run tool/emit_sprint_117_ga_release_execution_evaluation.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_117_ga_release_execution.dart';

const String _evaluationPath =
    'docs/planning/v1.3/sprint_117_ga_release_execution_evaluation.json';

void main() {
  final gate = const Sprint117GaReleaseGate();
  final report = gate.evaluate();
  final evidence = const Sprint117GaReleaseLoader().load();

  final manifest = <String, Object?>{
    'canonical_step': Sprint117GaReleaseContract.canonicalStep,
    'title': 'General Availability Release -- Evaluation Record',
    'document_role': 'gate-evaluation-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'required_outputs': Sprint117GaReleaseContract.requiredOutputs,
    'missing_outputs': report.missingOutputs,
    'violations': report.violations,
    'open_items': report.openItems,
    'evidence_source': Sprint117GaReleaseContract.manifestPath,
    'approval_source': Sprint117GaReleaseContract.approvalManifestPath,
    // Read from the committed sources, never typed: the approval gate is the
    // witness, and the execution manifest's own claim is cross-checked
    // against it.
    'execution_authorized': evidence?.approvalSourceAuthorized ?? false,
    'approval_source_decision': evidence?.approvalSourceDecision,
    'execution_manifest_decision': evidence?.recordedDecision,
    'claim_boundary': <String>[
      'This record is the gate verdict over committed evidence, not a release. Nothing was published, tagged, or signed, and no connector subset was enforced.',
      'The gate evaluates the committed execution manifest and cross-checks the authorization claim against the committed approval gate (117.45). A record that authorizes itself is not authorized.',
      'A verified output is only accepted when the evidence path it cites exists on disk; an unknown status word or release decision is drift and fails the gate rather than passing it.',
      'Absent or malformed evidence yields blocked, never pass. A blocking release decision forbids pass however the output records read.',
    ],
    'external_gates': <String>[
      'hosted CI runner',
      'public telemetry',
      'public-trust code signing',
      'store publication pipeline',
      'certified connector subset',
    ],
  };

  final target = File(_evaluationPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );

  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('missing_outputs=${report.missingOutputs.length}');
  stdout.writeln('violations=${report.violations.length}');
  stdout.writeln('written=${target.path}');
}
