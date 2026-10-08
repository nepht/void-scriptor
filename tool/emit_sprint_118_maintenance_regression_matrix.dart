// Emit the 118.26 Maintenance Regression Matrix record from the gate's own
// report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_maintenance_regression_matrix.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_maintenance_regression_matrix.dart';

Map<String, Object?> _entry(Sprint118MaintenanceRegressionEntry entry) =>
    <String, Object?>{
      'suite': entry.suite,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'detail': entry.detail,
      'limitations': entry.limitations,
      'maintenance_executed': entry.maintenanceExecuted,
      'connector_certified': entry.connectorCertified,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118MaintenanceRegressionGate();
  final report = gate.evaluate();
  final anchor = const Sprint118MaintenanceRegressionLoader().loadAnchor();
  final matrix = Sprint118MaintenanceRegressionContract.canonicalMatrix;
  final record = <String, Object?>{
    'canonical_step': Sprint118MaintenanceRegressionContract.canonicalStep,
    'title': Sprint118MaintenanceRegressionContract.title,
    'document_role': 'maintenance-regression-matrix-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'matrix_verified': report.matrixVerified,
    'required_suites': Sprint118MaintenanceRegressionContract.requiredSuites,
    'required_fields': Sprint118MaintenanceRegressionContract.requiredFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'baseline': Sprint118MaintenanceRegressionContract.baselineManifestPath,
      'charter': Sprint118MaintenanceRegressionContract.charterManifestPath,
      'stability_fixes':
          Sprint118MaintenanceRegressionContract.stabilityFixesManifestPath,
      'intake': Sprint118MaintenanceRegressionContract.intakeManifestPath,
      'test_matrix':
          Sprint118MaintenanceRegressionContract.testMatrixManifestPath,
      'full_matrix':
          Sprint118MaintenanceRegressionContract.fullMatrixManifestPath,
      'patch_matrix':
          Sprint118MaintenanceRegressionContract.patchMatrixManifestPath,
      'connector_contract':
          Sprint118MaintenanceRegressionContract.connectorContractManifestPath,
      'auth': Sprint118MaintenanceRegressionContract.authManifestPath,
      'sync': Sprint118MaintenanceRegressionContract.syncManifestPath,
      'billing': Sprint118MaintenanceRegressionContract.billingManifestPath,
      'security': Sprint118MaintenanceRegressionContract.securityManifestPath,
      'privacy': Sprint118MaintenanceRegressionContract.privacyManifestPath,
      'accessibility':
          Sprint118MaintenanceRegressionContract.accessibilityManifestPath,
      'ui': Sprint118MaintenanceRegressionContract.uiManifestPath,
    },
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'stability_fixes_state': anchor?.stabilityFixesState,
    'stability_fixes_verdict': anchor?.stabilityFixesVerdict,
    'intake_state': anchor?.intakeState,
    'intake_verdict': anchor?.intakeVerdict,
    'live_connector_execution': anchor?.liveConnectorExecution,
    'readable_source_count': anchor?.readableSources.length,
    'reference_state_vocabulary':
        Sprint118MaintenanceRegressionContract.stateVocabulary(<List<String>>[
          anchor?.testMatrixSuites ?? const <String>[],
          anchor?.fullMatrixSuites ?? const <String>[],
          anchor?.patchMatrixSuites ?? const <String>[],
          anchor?.connectorContractSuites ?? const <String>[],
          anchor?.intakeCategories ?? const <String>[],
          anchor?.fixesSuites ?? const <String>[],
        ]),
    'canonical_sources':
        Sprint118MaintenanceRegressionContract.canonicalSources,
    'declared_suites': report.declaredSuites,
    'observed_count': report.observedCount,
    'entries': matrix.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Maintenance Regression Matrix over the committed 118.4 post-release health baseline, the committed 118.2 stability expansion charter, the committed 118.24 stability fixes register, the committed 118.6 incident support intake, and the committed 115/112/114/116 test-matrix witnesses. A pass does not execute a maintenance run, certify a connector, run a live connector, observe anything live, authorize a release, or publish.',
      'The matrix is written against GA_DELAYED. Every entry registers a reference for one of the ten canonical required suites (unit, connector_contract, auth, sync, billing, security, privacy, accessibility, ui, end_to_end), claims no live maintenance run, certifies no connector, and observes nothing live.',
      'A regression suite is never claimed executed without a release: the gate refuses any entry that claims a live maintenance run.',
      'A maintenance regression never certifies a connector: the gate refuses any entry that claims a certification.',
      'Live maintenance execution, connector certification, connector execution, live observation, release authorization, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'live maintenance execution',
      'connector certification',
      'live connector execution',
      'live observation',
      'public release publication',
    ],
  };
  final target = File(Sprint118MaintenanceRegressionContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('observed_count=${report.observedCount}');
  stdout.writeln('written=${target.path}');
}
