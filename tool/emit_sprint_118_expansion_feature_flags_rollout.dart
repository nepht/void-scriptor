// Emit the 118.41 Expansion Feature Flags & Rollout record from the gate's own
// report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_expansion_feature_flags_rollout.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_expansion_feature_flags_rollout.dart';

Map<String, Object?> _entry(Sprint118ExpansionFeatureFlagEntry entry) =>
    <String, Object?>{
      'provider_id': entry.providerId,
      'flag': entry.flag,
      'audience': entry.audience,
      'default': entry.defaultState,
      'dependencies': entry.dependencies,
      'health_criteria': entry.healthCriteria,
      'kill_switch': entry.killSwitch,
      'rollback': entry.rollback,
      'support': entry.support,
      'enabled': entry.enabled,
      'flipped': entry.flipped,
      'rolled_out': entry.rolledOut,
      'kill_switch_drilled': entry.killSwitchDrilled,
      'rollback_executed': entry.rollbackExecuted,
      'supported': entry.supported,
      'certified': entry.certified,
      'released': entry.released,
    };

void main() {
  const gate = Sprint118ExpansionFeatureFlagGate();
  final report = gate.evaluate();
  final anchor = const Sprint118ExpansionFeatureFlagLoader().loadAnchor();
  final record = Sprint118ExpansionFeatureFlagContract.canonicalRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118ExpansionFeatureFlagContract.canonicalStep,
    'title': Sprint118ExpansionFeatureFlagContract.title,
    'document_role': 'expansion-feature-flags-rollout-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'record_verified': report.recordVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_fields': Sprint118ExpansionFeatureFlagContract.requiredFields,
    'required_outputs': Sprint118ExpansionFeatureFlagContract.requiredOutputs,
    'expected_provider_count':
        Sprint118ExpansionFeatureFlagContract.expectedProviderCount,
    'expected_output_count':
        Sprint118ExpansionFeatureFlagContract.expectedOutputCount,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint118ExpansionFeatureFlagContract.charterManifestPath,
      'snapshot': Sprint118ExpansionFeatureFlagContract.snapshotManifestPath,
      'approval_gate':
          Sprint118ExpansionFeatureFlagContract.approvalGateManifestPath,
      'icon_registry':
          Sprint118ExpansionFeatureFlagContract.iconRegistryManifestPath,
      'registry_reconciliation': Sprint118ExpansionFeatureFlagContract
          .registryReconciliationManifestPath,
      'snapshot_lock':
          Sprint118ExpansionFeatureFlagContract.snapshotLockManifestPath,
      'beta_exposure_flag_matrix':
          Sprint118ExpansionFeatureFlagContract.betaExposureFlagMatrixPath,
      'feature_flag_rollout_matrix':
          Sprint118ExpansionFeatureFlagContract.featureFlagRolloutMatrixPath,
      'feature_flag_dependency':
          Sprint118ExpansionFeatureFlagContract.featureFlagDependencyPath,
      'staged_beta_rollout':
          Sprint118ExpansionFeatureFlagContract.stagedBetaRolloutPath,
      'staged_ga_rollout':
          Sprint118ExpansionFeatureFlagContract.stagedGaRolloutPath,
      'support_incident':
          Sprint118ExpansionFeatureFlagContract.supportIncidentPath,
      'registry_evidence':
          Sprint118ExpansionFeatureFlagContract.registryEvidencePath,
    },
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_max_new_certified': anchor?.charterMaxNewCertified,
    'charter_currently_certified': anchor?.charterCurrentlyCertified,
    'charter_registered_providers': anchor?.charterRegisteredProviders,
    'snapshot_state': anchor?.snapshotState,
    'snapshot_verdict': anchor?.snapshotVerdict,
    'snapshot_certified': anchor?.snapshotCertified,
    'snapshot_registered': anchor?.snapshotRegistered,
    'registry_expected_count': anchor?.registryExpectedCount,
    'registry_evidence_provider_count': anchor?.registryEvidenceProviderCount,
    'registry_evidence_exposed': anchor?.registryEvidenceExposed,
    'registry_evidence_withheld': anchor?.registryEvidenceWithheld,
    'snapshot_lock_locked_count': anchor?.snapshotLockLockedCount,
    'approval_decision': anchor?.approvalDecision,
    'approval_state': anchor?.approvalState,
    'execution_authorized': anchor?.executionAuthorized,
    'release_blocked': anchor?.releaseBlocked,
    'registered_provider_count': anchor?.registeredProviders.length,
    'readable_source_count': anchor?.readableSources.length,
    'flag_vocabulary': anchor?.flagVocabulary,
    'audience_vocabulary': anchor?.audienceVocabulary,
    'default_vocabulary': anchor?.defaultVocabulary,
    'dependency_vocabulary': anchor?.dependencyVocabulary,
    'health_vocabulary': anchor?.healthVocabulary,
    'kill_switch_vocabulary': anchor?.killSwitchVocabulary,
    'rollback_vocabulary': anchor?.rollbackVocabulary,
    'support_vocabulary': anchor?.supportVocabulary,
    'reference_state_vocabulary':
        Sprint118ExpansionFeatureFlagContract.stateVocabulary(<List<String>>[
          anchor?.flagVocabulary ?? const <String>[],
          anchor?.audienceVocabulary ?? const <String>[],
          anchor?.defaultVocabulary ?? const <String>[],
          anchor?.dependencyVocabulary ?? const <String>[],
          anchor?.healthVocabulary ?? const <String>[],
          anchor?.killSwitchVocabulary ?? const <String>[],
          anchor?.rollbackVocabulary ?? const <String>[],
          anchor?.supportVocabulary ?? const <String>[],
        ]),
    'canonical_sources': Sprint118ExpansionFeatureFlagContract.canonicalSources,
    'declared_providers': report.declaredProviders,
    'declared_provider_count': report.declaredProviders.length,
    'enabled_providers': report.enabledProviders,
    'flipped_providers': report.flippedProviders,
    'rolled_out_providers': report.rolledOutProviders,
    'certified_providers': report.certifiedProviders,
    'released_providers': report.releasedProviders,
    'enabled_count': report.enabledCount,
    'flipped_count': report.flippedCount,
    'rolled_out_count': report.rolledOutCount,
    'certified_count': report.certifiedCount,
    'released_count': report.releasedCount,
    'entries': record.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Expansion Feature Flags & Rollout over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 GA approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 117.4 certification snapshot lock, the committed 117.41 connector-registry evidence, and the committed 116.50/117.41/112.6/113.13/117.44/117.47 rollout witnesses. A pass does not enable a connector, flip a feature flag, advance a rollout stage, drill a kill switch, execute a rollback, fire a support escalation, certify a connector, or release a connector.',
      'The feature flags and rollout record is written against GA_DELAYED. It enumerates all 32 registered providers exactly once, anchors each of the eight canonical rollout outputs (flag, audience, default, dependencies, health_criteria, kill_switch, rollback, support) to a committed witness vocabulary, claims no flag flipped and no rollout executed, and keeps the expansion budget frozen at zero new certified connectors.',
      'A connector is never recorded as enabled, and a rollout is never advanced, without live provider verification and an authorized release: the gate refuses any entry that claims an enabled connector, a flipped flag, an advanced rollout, a drilled kill switch, an executed rollback, an active support escalation, a certified connector, or a released connector on the delayed path, and refuses any expansion budget that is not frozen or any snapshot that certifies a connector.',
      'A registered provider set is never reviewed while drifting: the gate refuses a record that drops a registered provider, invents an unknown provider, or duplicates a provider, and refuses a record whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, charter count, 117.41 registry evidence count, and 117.4 snapshot lock count do not all reconcile to 32, or whose 117.41 registry visibility does not reconcile to 32 with zero exposed.',
      'The eight canonical rollout outputs are never invented: each output is grounded by the committed witness vocabulary for that output (the 116.50 staged beta rollout monitoring flags/health_metrics/provider_kill_switches/rollback, the 117.41 beta exposure flag matrix audience, the 112.6 feature flag rollout matrix default_policy, the 113.13 feature flag dependency validation dependency_matrix.cross_dependencies, and the 117.44 staged GA rollout plan support).',
      'Connector enablement, feature-flag flipping, rollout advancement, kill-switch drilling, rollback execution, support escalation, connector certification, connector release, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'connector enablement authorization',
      'feature flag flip authorization',
      'rollout stage advancement',
      'kill switch drill execution',
      'rollback execution',
      'support escalation',
      'connector certification',
      'connector release authorization',
      'public release publication',
    ],
  };
  final target = File(Sprint118ExpansionFeatureFlagContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('declared_provider_count=${report.declaredProviders.length}');
  stdout.writeln('enabled_count=${report.enabledCount}');
  stdout.writeln('flipped_count=${report.flippedCount}');
  stdout.writeln('rolled_out_count=${report.rolledOutCount}');
  stdout.writeln('certified_count=${report.certifiedCount}');
  stdout.writeln('released_count=${report.releasedCount}');
  stdout.writeln('written=${target.path}');
}
