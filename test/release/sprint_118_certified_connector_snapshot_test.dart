import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_certified_connector_snapshot.dart';

/// A fully satisfied snapshot. Each test flips exactly the one thing it is
/// about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it. The canonical snapshot
/// freezes an empty released subset (zero certified of thirty-two registered),
/// which is the honest state of the committed evidence.
Sprint118CertifiedConnectorSnapshot _snapshot({
  String releaseState = Sprint118SnapshotContract.delayedReleaseState,
  int registeredProviderCount = 32,
  List<Sprint118ConnectorSnapshotEntry>? releasedEntries,
}) {
  return Sprint118CertifiedConnectorSnapshot(
    releaseState: releaseState,
    registeredProviderCount: registeredProviderCount,
    releasedEntries:
        releasedEntries ?? const <Sprint118ConnectorSnapshotEntry>[],
  );
}

Sprint118ConnectorSnapshotEntry _entry({
  String providerId = 'email',
  String connectorVersion = 'manifest-v1',
  String status = 'CERTIFIED',
  List<String>? limitations,
  List<String>? regions,
  List<String>? plans,
  String iconVersion = 'generic-v1',
  String recheckDate = '2027-03-27',
}) {
  return Sprint118ConnectorSnapshotEntry(
    providerId: providerId,
    connectorVersion: connectorVersion,
    status: status,
    limitations:
        limitations ??
        const <String>[
          'local_certification_chain_only',
          'not_live_provider_availability',
        ],
    regions: regions ?? const <String>['GLOBAL'],
    plans: plans ?? const <String>['standard'],
    iconVersion: iconVersion,
    recheckDate: recheckDate,
  );
}

Sprint118ConnectorSnapshotAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict = Sprint118SnapshotContract.requiredCharterVerdict,
  String releaseState = Sprint118SnapshotContract.delayedReleaseState,
  int charterCertified = 0,
  int charterRegistered = 32,
  int evidenceCertified = 0,
  int evidenceLimited = 0,
  int evidenceUnverified = 32,
  int evidenceProviderCount = 32,
  int evidenceExposed = 0,
}) {
  return Sprint118ConnectorSnapshotAnchor(
    charterState: charterState,
    charterVerdict: charterVerdict,
    releaseState: releaseState,
    charterCertified: charterCertified,
    charterRegistered: charterRegistered,
    evidenceCertified: evidenceCertified,
    evidenceLimited: evidenceLimited,
    evidenceUnverified: evidenceUnverified,
    evidenceProviderCount: evidenceProviderCount,
    evidenceExposed: evidenceExposed,
  );
}

Sprint118SnapshotReport _run(
  Sprint118CertifiedConnectorSnapshot snapshot, {
  Sprint118ConnectorSnapshotAnchor? anchor,
}) {
  return const Sprint118CertifiedConnectorSnapshotGate().evaluateWith(
    anchor ?? _anchor(),
    snapshot,
  );
}

void main() {
  group('118.3 Certified Connector Snapshot', () {
    test('declares the canonical step, fields, and paths', () {
      expect(Sprint118SnapshotContract.canonicalStep, '118.3');
      expect(Sprint118SnapshotContract.title, 'Certified Connector Snapshot');
      expect(
        Sprint118SnapshotContract.manifestPath,
        'docs/planning/v1.3/sprint_118_certified_connector_snapshot.json',
      );
      expect(Sprint118SnapshotContract.requiredFields, <String>[
        'provider_id',
        'connector_version',
        'status',
        'limitations',
        'regions',
        'plans',
        'icon_version',
        'recheck_date',
      ]);
      expect(Sprint118SnapshotContract.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('vocabularies are internally consistent', () {
      // Every releasable status must be a known status, otherwise the gate can
      // never accept an entry that is allowed to be released.
      expect(
        Sprint118SnapshotContract.releasedStatuses,
        everyElement(isIn(Sprint118SnapshotContract.knownStatuses)),
      );
      expect(Sprint118SnapshotContract.requiredFields.length, 8);
      // The canonical snapshot freezes an empty released subset.
      expect(
        Sprint118SnapshotContract.canonicalSnapshot.releasedEntries,
        isEmpty,
      );
      expect(
        Sprint118SnapshotContract.canonicalSnapshot.registeredProviderCount,
        32,
      );
    });

    test('passes on the canonical empty released subset', () {
      final report = _run(_snapshot());
      expect(report.state, Sprint118SnapshotState.pass);
      expect(report.verdict, 'CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL');
      expect(report.snapshotFrozen, isTrue);
      expect(report.frozenProviderCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });

    test('passes when a certified entry matches the committed counts', () {
      final report = _run(
        _snapshot(releasedEntries: <Sprint118ConnectorSnapshotEntry>[_entry()]),
        anchor: _anchor(evidenceCertified: 1, evidenceUnverified: 31),
      );
      expect(report.state, Sprint118SnapshotState.pass);
      expect(report.frozenProviderCount, 1);
      expect(report.releasedSubset, <String>['email']);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118CertifiedConnectorSnapshotGate()
          .evaluateWith(null, _snapshot());
      expect(report.state, Sprint118SnapshotState.blocked);
      expect(report.verdict, 'SPRINT_118_SNAPSHOT_EVIDENCE_UNREADABLE');
      expect(
        report.blockers,
        contains('committed_snapshot_evidence_unreadable'),
      );
    });

    test('blocks when the 118.2 charter did not complete', () {
      final report = _run(
        _snapshot(),
        anchor: _anchor(charterVerdict: 'SPRINT_118_CHARTER_BLOCKED_UPSTREAM'),
      );
      expect(report.state, Sprint118SnapshotState.blocked);
      expect(
        report.blockers,
        contains('charter_not_complete:SPRINT_118_CHARTER_BLOCKED_UPSTREAM'),
      );
    });

    test('fails when the release state disagrees with the charter', () {
      final report = _run(
        _snapshot(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'GA_DELAYED'),
      );
      expect(report.state, Sprint118SnapshotState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when the registered count disagrees with the charter', () {
      final report = _run(_snapshot(registeredProviderCount: 31));
      expect(report.state, Sprint118SnapshotState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('snapshot_registered_count_mismatch:'),
        ),
        isTrue,
      );
    });

    test('fails when the registered count disagrees with the registry', () {
      final report = _run(
        _snapshot(),
        anchor: _anchor(evidenceProviderCount: 31),
      );
      expect(report.state, Sprint118SnapshotState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('snapshot_registry_count_mismatch:'),
        ),
        isTrue,
      );
    });

    test('fails on a blank or duplicate provider id', () {
      final blank = _run(
        _snapshot(
          releasedEntries: <Sprint118ConnectorSnapshotEntry>[
            _entry(providerId: ''),
          ],
        ),
      );
      expect(blank.state, Sprint118SnapshotState.fail);
      expect(blank.violations, contains('entry_blank_provider_id'));

      final duplicate = _run(
        _snapshot(
          releasedEntries: <Sprint118ConnectorSnapshotEntry>[
            _entry(providerId: 'email'),
            _entry(providerId: 'email'),
          ],
        ),
        anchor: _anchor(evidenceCertified: 2, evidenceUnverified: 30),
      );
      expect(duplicate.state, Sprint118SnapshotState.fail);
      expect(
        duplicate.violations,
        contains('entry_duplicate_provider_id:email'),
      );
    });

    test('fails on an unknown status', () {
      final report = _run(
        _snapshot(
          releasedEntries: <Sprint118ConnectorSnapshotEntry>[
            _entry(status: 'SHIPPED'),
          ],
        ),
        anchor: _anchor(evidenceCertified: 1),
      );
      expect(report.state, Sprint118SnapshotState.fail);
      expect(report.violations, contains('entry_unknown_status:email:SHIPPED'));
    });

    test('refuses to freeze an unreleased status as released', () {
      final report = _run(
        _snapshot(
          releasedEntries: <Sprint118ConnectorSnapshotEntry>[
            _entry(status: 'UNVERIFIED'),
          ],
        ),
        anchor: _anchor(evidenceCertified: 1),
      );
      expect(report.state, Sprint118SnapshotState.fail);
      expect(
        report.violations,
        contains('entry_status_not_releasable:email:UNVERIFIED'),
      );
    });

    test('fails when an entry carries no limitation', () {
      final report = _run(
        _snapshot(
          releasedEntries: <Sprint118ConnectorSnapshotEntry>[
            _entry(limitations: const <String>[]),
          ],
        ),
        anchor: _anchor(evidenceCertified: 1),
      );
      expect(report.state, Sprint118SnapshotState.fail);
      expect(report.violations, contains('entry_no_limitations:email'));
    });

    test('fails on missing or unknown regions', () {
      final none = _run(
        _snapshot(
          releasedEntries: <Sprint118ConnectorSnapshotEntry>[
            _entry(regions: const <String>[]),
          ],
        ),
        anchor: _anchor(evidenceCertified: 1),
      );
      expect(none.state, Sprint118SnapshotState.fail);
      expect(none.violations, contains('entry_no_regions:email'));

      final unknown = _run(
        _snapshot(
          releasedEntries: <Sprint118ConnectorSnapshotEntry>[
            _entry(regions: const <String>['MARS']),
          ],
        ),
        anchor: _anchor(evidenceCertified: 1),
      );
      expect(unknown.state, Sprint118SnapshotState.fail);
      expect(unknown.violations, contains('entry_unknown_region:email:MARS'));
    });

    test('fails on missing or unknown plans', () {
      final none = _run(
        _snapshot(
          releasedEntries: <Sprint118ConnectorSnapshotEntry>[
            _entry(plans: const <String>[]),
          ],
        ),
        anchor: _anchor(evidenceCertified: 1),
      );
      expect(none.state, Sprint118SnapshotState.fail);
      expect(none.violations, contains('entry_no_plans:email'));

      final unknown = _run(
        _snapshot(
          releasedEntries: <Sprint118ConnectorSnapshotEntry>[
            _entry(plans: const <String>['platinum']),
          ],
        ),
        anchor: _anchor(evidenceCertified: 1),
      );
      expect(unknown.state, Sprint118SnapshotState.fail);
      expect(unknown.violations, contains('entry_unknown_plan:email:platinum'));
    });

    test('fails on an invalid recheck date', () {
      final report = _run(
        _snapshot(
          releasedEntries: <Sprint118ConnectorSnapshotEntry>[
            _entry(recheckDate: '2027-13-40'),
          ],
        ),
        anchor: _anchor(evidenceCertified: 1),
      );
      expect(report.state, Sprint118SnapshotState.fail);
      expect(
        report.violations,
        contains('entry_invalid_recheck_date:email:2027-13-40'),
      );
    });

    test('fails when the released subset exceeds the committed evidence', () {
      // The committed evidence records zero certified of thirty-two; freezing a
      // released connector is exactly the drift the gate must refuse.
      final report = _run(
        _snapshot(releasedEntries: <Sprint118ConnectorSnapshotEntry>[_entry()]),
      );
      expect(report.state, Sprint118SnapshotState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('released_subset_count_mismatch:'),
        ),
        isTrue,
      );
      expect(
        report.violations.any(
          (v) => v.startsWith('released_certified_count_mismatch:'),
        ),
        isTrue,
      );
    });

    test('fails when exposure exceeds the released subset', () {
      final report = _run(_snapshot(), anchor: _anchor(evidenceExposed: 1));
      expect(report.state, Sprint118SnapshotState.fail);
      expect(
        report.violations,
        contains('exposed_beyond_released_subset:exposed=1:released=0'),
      );
    });

    test('parseIsoDate accepts real dates and refuses fabricated ones', () {
      expect(Sprint118SnapshotContract.parseIsoDate('2027-03-27'), isNotNull);
      expect(Sprint118SnapshotContract.parseIsoDate('2027-02-29'), isNull);
      expect(Sprint118SnapshotContract.parseIsoDate('2028-02-29'), isNotNull);
      expect(Sprint118SnapshotContract.parseIsoDate('2027-13-01'), isNull);
      expect(Sprint118SnapshotContract.parseIsoDate('not-a-date'), isNull);
    });

    test('isReleased is true only for certified and limited statuses', () {
      expect(_entry(status: 'CERTIFIED').isReleased, isTrue);
      expect(_entry(status: 'LIMITED').isReleased, isTrue);
      expect(_entry(status: 'UNVERIFIED').isReleased, isFalse);
      expect(_entry(status: 'BLOCKED').isReleased, isFalse);
    });
  });
}
