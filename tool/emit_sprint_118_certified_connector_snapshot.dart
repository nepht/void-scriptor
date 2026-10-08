// Emit the 118.3 Certified Connector Snapshot record from the gate's own report.
//
// The committed 118.2 charter and 117.41 connector-registry evidence are the
// evidence *input*: the gate reads them and decides whether the snapshot is a
// faithful freeze of what was released. This file is the *output*: the gate's
// measured verdict plus the snapshot's canonical fields, all derived from the
// contract constants and the gate's own report. Nothing here is typed by hand,
// so the record cannot be made to agree with itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_certified_connector_snapshot.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_certified_connector_snapshot.dart';

Map<String, Object?> _entry(Sprint118ConnectorSnapshotEntry entry) =>
    <String, Object?>{
      'provider_id': entry.providerId,
      'connector_version': entry.connectorVersion,
      'status': entry.status,
      'limitations': entry.limitations,
      'regions': entry.regions,
      'plans': entry.plans,
      'icon_version': entry.iconVersion,
      'recheck_date': entry.recheckDate,
    };

void main() {
  const gate = Sprint118CertifiedConnectorSnapshotGate();
  final report = gate.evaluate();
  final anchor = const Sprint118ConnectorSnapshotLoader().loadAnchor();
  final snapshot = Sprint118SnapshotContract.canonicalSnapshot;

  final record = <String, Object?>{
    'canonical_step': Sprint118SnapshotContract.canonicalStep,
    'title': Sprint118SnapshotContract.title,
    'document_role': 'connector-snapshot-evaluation-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'snapshot_frozen': report.snapshotFrozen,
    'required_fields': Sprint118SnapshotContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed witnesses this snapshot is anchored to, from the contract
    // constants -- not retyped, so the record cannot cite a path the gate never
    // opens.
    'evidence_sources': <String, String>{
      'charter': Sprint118SnapshotContract.charterManifestPath,
      'registry_evidence': Sprint118SnapshotContract.registryEvidencePath,
    },
    // Facts read from the committed witnesses, never typed.
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_certified': anchor?.charterCertified,
    'charter_registered': anchor?.charterRegistered,
    'evidence_certified': anchor?.evidenceCertified,
    'evidence_limited': anchor?.evidenceLimited,
    'evidence_unverified': anchor?.evidenceUnverified,
    'evidence_provider_count': anchor?.evidenceProviderCount,
    'evidence_exposed': anchor?.evidenceExposed,
    // The snapshot itself, derived from the contract constants.
    'registered_provider_count': snapshot.registeredProviderCount,
    'frozen_provider_count': report.frozenProviderCount,
    'released_subset': report.releasedSubset,
    'released_entries': snapshot.releasedEntries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.2 charter and 117.41 connector-registry evidence. A pass means the snapshot faithfully freezes the released connector subset and its status counts match the registry; it does not certify any connector, expose any provider, or authorize any release.',
      'The snapshot is written against the delayed release state (GA_DELAYED). The committed registry evidence records CERTIFIED: 0 and LIMITED: 0 of 32 registered providers, so the released subset is empty and this record freezes exactly that.',
      'The gate reads the committed charter and registry evidence directly; an unreadable witness or an incomplete charter keeps the snapshot blocked rather than assumed.',
      'Connector certification, provider exposure, live availability, quota, cost, and credential state remain DEFERRED-EXTERNAL; nothing here is performed or authorized.',
    ],
    'external_gates': <String>[
      'connector certification evidence',
      'provider exposure authorization',
      'live provider availability',
      'quota, cost, and credential state',
      'public release publication',
    ],
  };

  final target = File(Sprint118SnapshotContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );

  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('release_state=${report.releaseState}');
  stdout.writeln('frozen_provider_count=${report.frozenProviderCount}');
  stdout.writeln('blockers=${report.blockers.length}');
  stdout.writeln('violations=${report.violations.length}');
  stdout.writeln('written=${target.path}');
}
