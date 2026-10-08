// Emit the 118.21 Feedback & Adoption Evidence Log record from the gate's own
// report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_feedback_adoption_evidence_log.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_feedback_adoption_evidence_log.dart';

Map<String, Object?> _entry(Sprint118FeedbackEntry entry) => <String, Object?>{
  'evidence_id': entry.evidenceId,
  'source': entry.source,
  'consent': entry.consent,
  'workflow': entry.workflow,
  'outcome': entry.outcome,
  'friction': entry.friction,
  'request': entry.request,
  'limitations': entry.limitations,
  'request_is_commitment': entry.requestIsCommitment,
};

void main() {
  const gate = Sprint118FeedbackAdoptionGate();
  final report = gate.evaluate();
  final anchor = const Sprint118FeedbackAdoptionLoader().loadAnchor();
  final log = Sprint118FeedbackAdoptionContract.canonicalLog;
  final record = <String, Object?>{
    'canonical_step': Sprint118FeedbackAdoptionContract.canonicalStep,
    'title': Sprint118FeedbackAdoptionContract.title,
    'document_role': 'feedback-adoption-evidence-log-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'log_verified': report.logVerified,
    'required_fields': Sprint118FeedbackAdoptionContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'baseline': Sprint118FeedbackAdoptionContract.baselineManifestPath,
      'charter': Sprint118FeedbackAdoptionContract.charterManifestPath,
      'workflow': Sprint118FeedbackAdoptionContract.workflowManifestPath,
      'consent': Sprint118FeedbackAdoptionContract.consentManifestPath,
    },
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'live_adoption_executed': anchor?.liveAdoptionExecuted,
    'workflow_vocabulary': anchor?.workflows,
    'outcome_vocabulary': report.outcomeVocabulary,
    'consent_vocabulary': anchor == null
        ? const <String>[]
        : Sprint118FeedbackAdoptionContract.consentVocabulary(
            anchor.consentType,
          ),
    'consent_type': anchor?.consentType,
    'readable_source_count': anchor?.readableSources.length,
    'canonical_workflows': Sprint118FeedbackAdoptionContract.canonicalWorkflows,
    'canonical_sources': Sprint118FeedbackAdoptionContract.canonicalSources,
    'declared_workflows': report.declaredWorkflows,
    'entry_count': report.entryCount,
    'entries': log.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Feedback & Adoption evidence log over the committed 118.4 post-release health baseline, the committed 118.2 stability expansion charter, the committed 114.23 workflow-outcome review, and the committed 113.3 validation cohort consent. A pass does not run a participant validation, collect adoption telemetry, operate a support channel, certify a connector, expose a provider, authorize a release, or publish.',
      'The log is written against GA_DELAYED. Every entry records a request, claims no live outcome, and claims no participant consent.',
      'A request is never a commitment: the gate refuses any entry that treats its request as a commitment, and any request that is neither the no-request marker nor a requested: connector.',
      'Live participant feedback, adoption telemetry, support-channel operations, connector certification, provider exposure, release authorization, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'live participant feedback collection',
      'adoption telemetry',
      'support-channel operations',
      'connector certification',
      'provider exposure',
      'public release publication',
    ],
  };
  final target = File(Sprint118FeedbackAdoptionContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('entry_count=${report.entryCount}');
  stdout.writeln('written=${target.path}');
}
