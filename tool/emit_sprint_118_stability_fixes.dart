// Emit the 118.24 Stability Fixes record from the gate's own report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_stability_fixes.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_stability_fixes.dart';

Map<String, Object?> _entry(Sprint118StabilityFixEntry entry) =>
    <String, Object?>{
      'fix_area': entry.fixArea,
      'fix_id': entry.fixId,
      'reproduction': entry.reproduction,
      'minimal_change': entry.minimalChange,
      'regression_test': entry.regressionTest,
      'review': entry.review,
      'risk_update': entry.riskUpdate,
      'release_note': entry.releaseNote,
      'owner': entry.owner,
      'evidence': entry.evidence,
      'fix_shipped': entry.fixShipped,
      'scope_expanded': entry.scopeExpanded,
    };

void main() {
  const gate = Sprint118StabilityFixGate();
  final report = gate.evaluate();
  final anchor = const Sprint118StabilityFixLoader().loadAnchor();
  final register = Sprint118StabilityFixContract.canonicalRegister;
  final record = <String, Object?>{
    'canonical_step': Sprint118StabilityFixContract.canonicalStep,
    'title': Sprint118StabilityFixContract.title,
    'document_role': 'stability-fixes-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'register_verified': report.registerVerified,
    'required_requirements': Sprint118StabilityFixContract.requiredRequirements,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'baseline': Sprint118StabilityFixContract.baselineManifestPath,
      'charter': Sprint118StabilityFixContract.charterManifestPath,
      'readiness': Sprint118StabilityFixContract.readinessManifestPath,
      'intake': Sprint118StabilityFixContract.intakeManifestPath,
      'test_matrix': Sprint118StabilityFixContract.testMatrixManifestPath,
      'rollback': Sprint118StabilityFixContract.rollbackManifestPath,
      'p1_fixes': Sprint118StabilityFixContract.p1FixesManifestPath,
    },
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'readiness_state': anchor?.readinessState,
    'readiness_verdict': anchor?.readinessVerdict,
    'live_incident_executed': anchor?.liveIncidentExecuted,
    'intake_state': anchor?.intakeState,
    'intake_verdict': anchor?.intakeVerdict,
    'owner_vocabulary': anchor?.owners,
    'intake_category_vocabulary': anchor?.intakeCategories,
    'test_suite_vocabulary': anchor?.testSuites,
    'rollback_evidence_vocabulary': anchor?.rollbackEvidence,
    'p1_requirement_vocabulary': anchor?.p1Requirements,
    'readable_source_count': anchor?.readableSources.length,
    'canonical_fix_areas': Sprint118StabilityFixContract.fixAreas,
    'canonical_sources': Sprint118StabilityFixContract.canonicalSources,
    'declared_areas': report.declaredAreas,
    'fix_count': report.fixCount,
    'entries': register.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Stability Fixes register over the committed 118.4 post-release health baseline, the committed 118.2 stability expansion charter, the committed 117.6 support incident readiness witness, the committed 118.6 incident support intake witness, the committed 115 automated test matrix witness, the committed 114 rollback feature flag readiness witness, and the committed 114.29 P1 stability fixes witness. A pass does not ship a fix, apply a change, execute a regression test, perform a review, update a risk register, write a release note, reproduce a production regression, certify a connector, expose a provider, authorize a release, or publish.',
      'The register is written against GA_DELAYED. Every record registers a reference fix across the eight approved fix areas (auth, quota, sync, ai, billing, ui, accessibility, compatibility), claims no shipped fix, and stops short of confirming a live regression or an applied change.',
      'A fix is never claimed shipped without a release: the gate refuses any record that treats its reference fix as a shipped fix, and any record that claims a shipped fix through the readiness witness.',
      'A fix never expands scope beyond the approved minimum change: the gate refuses any record that widens the approved scope.',
      'Live fix shipping, change application, regression reproduction, connector certification, provider exposure, release authorization, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'live fix shipping',
      'live change application',
      'live regression reproduction',
      'regression test execution',
      'fix review',
      'risk register update',
      'release note publication',
      'connector certification',
      'provider exposure',
      'public release publication',
    ],
  };
  final target = File(Sprint118StabilityFixContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('fix_count=${report.fixCount}');
  stdout.writeln('written=${target.path}');
}
