// Emit the 118.27 Rollout Progression Decision record from the gate's own
// report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_rollout_progression_decision.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_rollout_progression_decision.dart';

Map<String, Object?> _entry(Sprint118RolloutProgressionEntry entry) =>
    <String, Object?>{
      'decision': entry.decision,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'detail': entry.detail,
      'limitations': entry.limitations,
      'expansion_claimed': entry.expansionClaimed,
      'rollback_claimed': entry.rollbackClaimed,
      'connector_disable_claimed': entry.connectorDisableClaimed,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118RolloutProgressionGate();
  final report = gate.evaluate();
  final anchor = const Sprint118RolloutProgressionLoader().loadAnchor();
  final decision = Sprint118RolloutProgressionContract.canonicalDecision;
  final record = <String, Object?>{
    'canonical_step': Sprint118RolloutProgressionContract.canonicalStep,
    'title': Sprint118RolloutProgressionContract.title,
    'document_role': 'rollout-progression-decision-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'selected_decision': report.selectedDecision,
    'decision_verified': report.decisionVerified,
    'required_decisions': Sprint118RolloutProgressionContract.requiredDecisions,
    'required_fields': Sprint118RolloutProgressionContract.requiredFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'baseline': Sprint118RolloutProgressionContract.baselineManifestPath,
      'charter': Sprint118RolloutProgressionContract.charterManifestPath,
      'regression': Sprint118RolloutProgressionContract.regressionManifestPath,
      'connector_disable':
          Sprint118RolloutProgressionContract.connectorDisableManifestPath,
      'approval_gate':
          Sprint118RolloutProgressionContract.approvalGateManifestPath,
      'rollout_plan':
          Sprint118RolloutProgressionContract.rolloutPlanManifestPath,
      'rollback_drill':
          Sprint118RolloutProgressionContract.rollbackDrillManifestPath,
    },
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'regression_state': anchor?.regressionState,
    'regression_verdict': anchor?.regressionVerdict,
    'connector_disable_state': anchor?.disableState,
    'connector_disable_verdict': anchor?.disableVerdict,
    'approval_decision': anchor?.approvalDecision,
    'approval_state': anchor?.approvalState,
    'execution_authorized': anchor?.executionAuthorized,
    'release_blocked': anchor?.releaseBlocked,
    'live_rollout_executed': anchor?.liveRolloutExecuted,
    'readable_source_count': anchor?.readableSources.length,
    'reference_state_vocabulary':
        Sprint118RolloutProgressionContract.stateVocabulary(<List<String>>[
          anchor?.rolloutFields ?? const <String>[],
          anchor?.drillControls ?? const <String>[],
          anchor?.disableAcceptance ?? const <String>[],
          anchor?.regressionSuites ?? const <String>[],
          anchor?.baselineAreas ?? const <String>[],
        ]),
    'canonical_sources': Sprint118RolloutProgressionContract.canonicalSources,
    'declared_decisions': report.declaredDecisions,
    'observed_count': report.observedCount,
    'entries': decision.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Rollout Progression Decision over the committed 118.4 post-release health baseline, the committed 118.2 stability expansion charter, the committed 118.26 maintenance regression matrix, the committed 118.25 connector-disable review, and the committed 117.45 approval gate, 117.44 rollout plan, and 117.8 rollback drill. A pass does not execute a rollout, expand or reduce exposure, disable a connector, roll back, authorize a release, or publish.',
      'The decision is written against GA_DELAYED. It enumerates all five canonical decision options (EXPAND, HOLD, REDUCE, DISABLE_CONNECTOR, ROLLBACK), claims no live expansion, no live reduction, no live connector disable, no live rollback, and observes nothing live, and selects HOLD as the only decision the evidence supports.',
      'A rollout progression decision is never made without a live rollout: when no live rollout has executed, the gate refuses any selected decision other than HOLD.',
      'A rollout is never expanded without a release, a connector is never disabled without a release, and nothing is rolled back that never ran: the gate refuses each claim by name.',
      'Live rollout execution, expansion, reduction, connector disable, rollback, release authorization, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'live rollout execution',
      'rollout expansion',
      'rollout reduction',
      'connector disable',
      'rollback execution',
      'public release publication',
    ],
  };
  final target = File(Sprint118RolloutProgressionContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('selected_decision=${report.selectedDecision}');
  stdout.writeln('written=${target.path}');
}
