// Emit the 118.6 Incident & Support Intake record from the gate's own report.
//
// The committed 118.4 baseline and 117.6 support-incident-readiness witness are
// the evidence *input*: the gate reads them and decides whether the declared
// intake is well-formed. This file is the *output*: the gate's measured verdict
// plus the intake's canonical fields, all derived from the contract constants
// and the gate's own report. Nothing here is typed by hand, so the record cannot
// be made to agree with itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_incident_support_intake.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_incident_support_intake.dart';

Map<String, Object?> _entry(Sprint118IncidentIntakeEntry entry) =>
    <String, Object?>{
      'category': entry.category,
      'incident_id': entry.incidentId,
      'source': entry.source,
      'provider': entry.provider,
      'version': entry.version,
      'impact': entry.impact,
      'reproduction': entry.reproduction,
      'evidence': entry.evidence,
      'owner': entry.owner,
    };

void main() {
  const gate = Sprint118IncidentIntakeGate();
  final report = gate.evaluate();
  final anchor = const Sprint118IncidentIntakeLoader().loadAnchor();
  final intake = Sprint118IncidentIntakeContract.canonicalIntake;

  final record = <String, Object?>{
    'canonical_step': Sprint118IncidentIntakeContract.canonicalStep,
    'title': Sprint118IncidentIntakeContract.title,
    'document_role': 'incident-support-intake-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'intake_verified': report.intakeVerified,
    'required_fields': Sprint118IncidentIntakeContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed witnesses this intake is anchored to, from the contract
    // constants -- not retyped, so the record cannot cite a path the gate never
    // opens.
    'evidence_sources': <String, String>{
      'baseline': Sprint118IncidentIntakeContract.baselineManifestPath,
      'support_readiness':
          Sprint118IncidentIntakeContract.supportReadinessManifestPath,
    },
    // Facts read from the committed witnesses, never typed.
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'support_state': anchor?.supportState,
    'support_verdict': anchor?.supportVerdict,
    'live_incident_executed': anchor?.liveIncidentExecuted,
    'severity_levels': anchor?.severityLevels,
    'owners': anchor?.owners,
    'readable_source_count': anchor?.readableSources.length,
    // The intake itself, derived from the contract constants.
    'incident_count': report.incidentCount,
    'declared_categories': report.declaredCategories,
    'canonical_categories': Sprint118IncidentIntakeContract.incidentCategories,
    'no_impact': Sprint118IncidentIntakeContract.noImpact,
    'entries': intake.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.4 baseline and 117.6 support-incident-readiness evidence. A pass means the declared intake carries all eight required fields for every canonical incident category; it does not execute any incident, open any support channel, page any on-call rotation, or authorize any release.',
      'The intake is written against the delayed release state (GA_DELAYED). No release ran, so no entry registers a live incident and every entry carries impact "none".',
      'The gate reads the committed witnesses directly, derives its impact and owner vocabularies from the 117.6 readiness witness, and verifies each entry cites a committed, readable evidence source; an unreadable witness or an unfrozen baseline keeps the intake blocked rather than assumed.',
      'The impact vocabulary is the readiness witness severity levels plus the no-impact marker; the owner vocabulary is the readiness witness owners. Both are read from the committed witness, so the intake and the readiness plan cannot drift apart silently.',
      'Live incident handling, support channels, on-call rotation, provider escalation, connector certification, provider exposure, and publication remain DEFERRED-EXTERNAL; nothing here is performed or authorized.',
    ],
    'external_gates': <String>[
      'live incident handling',
      'support channel operations',
      'on-call rotation',
      'provider escalation',
      'connector certification evidence',
      'public release publication',
    ],
  };

  final target = File(Sprint118IncidentIntakeContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );

  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('release_state=${report.releaseState}');
  stdout.writeln('incident_count=${report.incidentCount}');
  stdout.writeln('declared_categories=${report.declaredCategories.length}');
  stdout.writeln('severity_levels=${anchor?.severityLevels.length ?? 0}');
  stdout.writeln('blockers=${report.blockers.length}');
  stdout.writeln('violations=${report.violations.length}');
  stdout.writeln('open_items=${report.openItems.length}');
  stdout.writeln('written=${target.path}');
}
