// Emit the 118.22 Issue Deduplication & Root Cause record from the gate's own
// report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_issue_deduplication_root_cause.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_issue_deduplication_root_cause.dart';

Map<String, Object?> _entry(Sprint118IssueEntry entry) => <String, Object?>{
  'issue_id': entry.issueId,
  'duplicates': entry.duplicates,
  'connector_version': entry.connectorVersion,
  'component': entry.component,
  'reproduction': entry.reproduction,
  'root_cause': entry.rootCause,
  'impact': entry.impact,
  'owner': entry.owner,
  'root_cause_treated_as_confirmed': entry.rootCauseTreatedAsConfirmed,
};

void main() {
  const gate = Sprint118DedupGate();
  final report = gate.evaluate();
  final anchor = const Sprint118DedupLoader().loadAnchor();
  final log = Sprint118DedupContract.canonicalLog;
  final record = <String, Object?>{
    'canonical_step': Sprint118DedupContract.canonicalStep,
    'title': Sprint118DedupContract.title,
    'document_role': 'issue-deduplication-root-cause-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'log_verified': report.logVerified,
    'required_fields': Sprint118DedupContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'baseline': Sprint118DedupContract.baselineManifestPath,
      'charter': Sprint118DedupContract.charterManifestPath,
      'connector': Sprint118DedupContract.connectorManifestPath,
      'readiness': Sprint118DedupContract.readinessManifestPath,
    },
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'live_incident_executed': anchor?.liveIncidentExecuted,
    'component_vocabulary': anchor?.components,
    'connector_version_vocabulary': anchor?.connectorVersions,
    'impact_vocabulary': report.impactVocabulary,
    'owner_vocabulary': anchor?.owners,
    'readable_source_count': anchor?.readableSources.length,
    'canonical_components': Sprint118DedupContract.canonicalComponents,
    'canonical_sources': Sprint118DedupContract.canonicalSources,
    'declared_components': report.declaredComponents,
    'entry_count': report.entryCount,
    'entries': log.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Issue Deduplication & Root Cause log over the committed 118.4 post-release health baseline, the committed 118.2 stability expansion charter, the committed 117.5 certification snapshot lock, and the committed 117.6 support incident readiness witness. A pass does not ingest a live issue tracker, execute a live incident, certify a connector, expose a provider, authorize a release, or publish.',
      'The log is written against GA_DELAYED. Every entry registers a reference issue, folds no duplicates yet, claims no live impact, and stops short of confirming a root cause.',
      'A root cause is never confirmed without a live incident: the gate refuses any entry that treats its reference root-cause classification as a confirmed cause, and any entry that claims a live impact.',
      'Live issue-tracker ingestion, live incident execution, connector certification, provider exposure, release authorization, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'live issue-tracker ingestion',
      'live incident execution',
      'connector certification',
      'provider exposure',
      'public release publication',
    ],
  };
  final target = File(Sprint118DedupContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('entry_count=${report.entryCount}');
  stdout.writeln('written=${target.path}');
}
