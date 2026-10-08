import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_issue_deduplication_root_cause.dart';

/// A single deduplication record. Each test flips exactly the one thing it is
/// about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it.
Sprint118IssueEntry _entry({
  String component = 'connection',
  String issueId = 'ISSUE-CONNECTION-REF',
  String connectorVersion = Sprint118DedupContract.referenceConnectorVersion,
  List<String> duplicates = const <String>[],
  List<String> reproduction = const <String>[
    Sprint118DedupContract.referenceReproduction,
  ],
  String rootCause = Sprint118DedupContract.referenceRootCause,
  String impact = Sprint118DedupContract.noImpact,
  String owner = 'nephthys',
  bool rootCauseTreatedAsConfirmed = false,
}) {
  return Sprint118IssueEntry(
    component: component,
    issueId: issueId,
    connectorVersion: connectorVersion,
    duplicates: duplicates,
    reproduction: reproduction,
    rootCause: rootCause,
    impact: impact,
    owner: owner,
    rootCauseTreatedAsConfirmed: rootCauseTreatedAsConfirmed,
  );
}

Sprint118DedupLog _log({
  String releaseState = Sprint118DedupContract.delayedReleaseState,
  List<Sprint118IssueEntry>? entries,
}) {
  return Sprint118DedupLog(
    releaseState: releaseState,
    entries: entries ?? Sprint118DedupContract.canonicalLog.entries,
  );
}

/// The canonical entries with exactly one component replaced, so a test can
/// flip a single field without rebuilding the whole log.
List<Sprint118IssueEntry> _replacing(
  String component,
  Sprint118IssueEntry replacement,
) {
  return <Sprint118IssueEntry>[
    for (final e in Sprint118DedupContract.canonicalLog.entries)
      if (e.component == component) replacement else e,
  ];
}

Sprint118DedupAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict = Sprint118DedupContract.requiredBaselineVerdict,
  String releaseState = Sprint118DedupContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict = Sprint118DedupContract.requiredCharterVerdict,
  bool liveIncidentExecuted = false,
  List<String>? components,
  List<String>? connectorVersions,
  List<String>? impacts,
  List<String>? owners,
  List<String>? readableSources,
}) {
  return Sprint118DedupAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    liveIncidentExecuted: liveIncidentExecuted,
    components: components ?? Sprint118DedupContract.canonicalComponents,
    connectorVersions:
        connectorVersions ??
        const <String>[Sprint118DedupContract.referenceConnectorVersion],
    impacts: impacts ?? const <String>['P0', 'P1', 'P2', 'P3'],
    owners: owners ?? const <String>['Choirudin', 'nephthys'],
    readableSources: readableSources ?? Sprint118DedupContract.canonicalSources,
  );
}

Sprint118DedupReport _run(
  Sprint118DedupLog log, {
  Sprint118DedupAnchor? anchor,
}) {
  return const Sprint118DedupGate().evaluateWith(anchor ?? _anchor(), log);
}

void main() {
  group('118.22 Issue Deduplication & Root Cause', () {
    test('declares the canonical step, title, fields, and paths', () {
      expect(Sprint118DedupContract.canonicalStep, '118.22');
      expect(Sprint118DedupContract.title, 'Issue Deduplication & Root Cause');
      expect(
        Sprint118DedupContract.manifestPath,
        'docs/planning/v1.3/sprint_118_issue_deduplication_root_cause.json',
      );
      expect(Sprint118DedupContract.requiredFields, <String>[
        'issue_id',
        'duplicates',
        'connector_version',
        'component',
        'reproduction',
        'root_cause',
        'impact',
        'owner',
      ]);
      expect(Sprint118DedupContract.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118DedupContract.requiredFields.length, 8);
      expect(Sprint118DedupContract.canonicalComponents.length, 10);
      expect(Sprint118DedupContract.canonicalSources.length, 10);
      // The impact vocabulary is derived from the readiness witness severity
      // levels, plus the no-impact marker.
      expect(
        Sprint118DedupContract.impactVocabulary(const <String>['P0', 'P1']),
        <String>['P0', 'P1', 'none'],
      );
    });

    test('canonical log covers the ten components and claims no live '
        'impact', () {
      final log = Sprint118DedupContract.canonicalLog;
      expect(log.entries.length, 10);
      expect(log.components.toSet(), <String>{
        'connection',
        'reauth',
        'quota',
        'sync',
        'backup',
        'ai',
        'billing',
        'crash',
        'performance',
        'support',
      });
      for (final entry in log.entries) {
        expect(entry.impact, Sprint118DedupContract.noImpact);
        expect(entry.rootCauseTreatedAsConfirmed, isFalse);
        expect(entry.duplicates, isEmpty);
        for (final field in Sprint118DedupContract.requiredFields) {
          if (field == 'duplicates') continue;
          expect(
            (entry.fields[field] ?? '').trim(),
            isNotEmpty,
            reason: '${entry.component}.$field must not be blank',
          );
        }
      }
    });

    test('passes on the canonical log', () {
      final report = _run(_log());
      expect(report.state, Sprint118DedupState.pass);
      expect(report.verdict, 'ISSUE_DEDUPLICATION_ROOT_CAUSE_VERIFIED_LOCAL');
      expect(report.logVerified, isTrue);
      expect(report.declaredComponents.length, 10);
      expect(report.entryCount, 10);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118DedupGate().evaluateWith(null, _log());
      expect(report.state, Sprint118DedupState.blocked);
      expect(report.verdict, 'SPRINT_118_DEDUP_EVIDENCE_UNREADABLE');
      expect(
        report.blockers,
        contains('committed_issue_dedup_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _log(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118DedupState.blocked);
      expect(
        report.blockers,
        contains('baseline_not_frozen:SPRINT_118_BASELINE_EVIDENCE_VIOLATION'),
      );
    });

    test('blocks when the 118.2 charter is not complete', () {
      final report = _run(
        _log(),
        anchor: _anchor(charterVerdict: 'CHARTER_EVIDENCE_VIOLATION'),
      );
      expect(report.state, Sprint118DedupState.blocked);
      expect(
        report.blockers,
        contains('charter_not_complete:CHARTER_EVIDENCE_VIOLATION'),
      );
    });

    test('fails when the release state disagrees with the baseline', () {
      final report = _run(
        _log(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'GA_DELAYED'),
      );
      expect(report.state, Sprint118DedupState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a live incident is claimed on the delayed path', () {
      final report = _run(_log(), anchor: _anchor(liveIncidentExecuted: true));
      expect(report.state, Sprint118DedupState.fail);
      expect(
        report.violations,
        contains('live_incident_claimed_executed_without_release'),
      );
    });

    test('fails when an entry claims a live impact without a release', () {
      final report = _run(
        _log(
          entries: _replacing(
            'connection',
            _entry(component: 'connection', impact: 'P0'),
          ),
        ),
      );
      expect(report.state, Sprint118DedupState.fail);
      expect(
        report.violations,
        contains('impact_claimed_without_release:connection:P0'),
      );
    });

    test('fails when an entry carries an unknown impact', () {
      final report = _run(
        _log(
          entries: _replacing(
            'reauth',
            _entry(component: 'reauth', impact: 'CRITICAL'),
          ),
        ),
      );
      expect(report.state, Sprint118DedupState.fail);
      expect(
        report.violations,
        contains('entry_unknown_impact:reauth:CRITICAL'),
      );
    });

    test('fails when an entry carries an unknown connector version', () {
      final report = _run(
        _log(
          entries: _replacing(
            'quota',
            _entry(component: 'quota', connectorVersion: 'manifest-v9'),
          ),
        ),
      );
      expect(report.state, Sprint118DedupState.fail);
      expect(
        report.violations,
        contains('entry_unknown_connector_version:quota:manifest-v9'),
      );
    });

    test('fails when an entry carries an unknown owner', () {
      final report = _run(
        _log(
          entries: _replacing(
            'sync',
            _entry(component: 'sync', owner: 'nobody'),
          ),
        ),
      );
      expect(report.state, Sprint118DedupState.fail);
      expect(report.violations, contains('entry_unknown_owner:sync:nobody'));
    });

    test('fails when a root cause is treated as confirmed', () {
      final report = _run(
        _log(
          entries: _replacing(
            'backup',
            _entry(component: 'backup', rootCauseTreatedAsConfirmed: true),
          ),
        ),
      );
      expect(report.state, Sprint118DedupState.fail);
      expect(
        report.violations,
        contains('root_cause_treated_as_confirmed:backup'),
      );
    });

    test('fails when a duplicate reference self-references', () {
      final report = _run(
        _log(
          entries: _replacing(
            'ai',
            _entry(
              component: 'ai',
              issueId: 'ISSUE-AI-REF',
              duplicates: const <String>['ISSUE-AI-REF'],
            ),
          ),
        ),
      );
      expect(report.state, Sprint118DedupState.fail);
      expect(
        report.violations,
        contains('duplicate_self_reference:ai:ISSUE-AI-REF'),
      );
    });

    test(
      'fails when a duplicate reference conflicts with a canonical issue',
      () {
        final report = _run(
          _log(
            entries: _replacing(
              'billing',
              _entry(
                component: 'billing',
                duplicates: const <String>['ISSUE-CRASH-REF'],
              ),
            ),
          ),
        );
        expect(report.state, Sprint118DedupState.fail);
        expect(
          report.violations,
          contains('duplicate_reference_conflict:billing:ISSUE-CRASH-REF'),
        );
      },
    );

    test('fails when a duplicate reference is blank', () {
      final report = _run(
        _log(
          entries: _replacing(
            'crash',
            _entry(component: 'crash', duplicates: const <String>['   ']),
          ),
        ),
      );
      expect(report.state, Sprint118DedupState.fail);
      expect(report.violations, contains('duplicate_reference_blank:crash'));
    });

    test('accepts a non-blank, non-conflicting duplicate reference', () {
      final report = _run(
        _log(
          entries: _replacing(
            'performance',
            _entry(
              component: 'performance',
              duplicates: const <String>['REPORT-EXTERNAL-1'],
            ),
          ),
        ),
      );
      expect(report.state, Sprint118DedupState.pass);
      expect(report.violations, isEmpty);
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _log(
          entries: _replacing(
            'support',
            _entry(component: 'support', issueId: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118DedupState.fail);
      expect(report.violations, contains('entry_blank_issue_id:support'));
    });

    test('fails when reproduction is empty', () {
      final report = _run(
        _log(
          entries: _replacing(
            'connection',
            _entry(component: 'connection', reproduction: const <String>[]),
          ),
        ),
      );
      expect(report.state, Sprint118DedupState.fail);
      expect(
        report.violations,
        contains('entry_blank_reproduction:connection'),
      );
    });

    test('fails on a duplicate component', () {
      final entries = <Sprint118IssueEntry>[
        ...Sprint118DedupContract.canonicalLog.entries,
        _entry(component: 'connection', issueId: 'ISSUE-CONNECTION-DUP'),
      ];
      final report = _run(_log(entries: entries));
      expect(report.state, Sprint118DedupState.fail);
      expect(report.violations, contains('component_duplicate:connection'));
    });

    test('fails when a canonical component is missing', () {
      final entries = <Sprint118IssueEntry>[
        for (final e in Sprint118DedupContract.canonicalLog.entries)
          if (e.component != 'support') e,
      ];
      final report = _run(_log(entries: entries));
      expect(report.state, Sprint118DedupState.fail);
      expect(report.violations, contains('component_missing:support'));
    });

    test('fails when an entry names an unknown component', () {
      final report = _run(
        _log(
          entries: _replacing(
            'connection',
            _entry(component: 'unknown_component'),
          ),
        ),
      );
      expect(report.state, Sprint118DedupState.fail);
      // The replacement also removes the real 'connection' entry, so both the
      // unknown-component and the missing-component violations are expected.
      expect(
        report.violations,
        contains('component_unknown:unknown_component'),
      );
      expect(report.violations, contains('component_missing:connection'));
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _log(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.3/sprint_118_connection_health_review.json',
          ],
        ),
      );
      expect(report.state, Sprint118DedupState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('reports the missing upstream component vocabulary honestly', () {
      final report = _run(
        _log(),
        anchor: _anchor(components: const <String>[]),
      );
      expect(
        report.openItems,
        contains('upstream_component_vocabulary_missing'),
      );
    });

    test('reports the missing upstream connector version vocabulary '
        'honestly', () {
      final report = _run(
        _log(),
        anchor: _anchor(connectorVersions: const <String>[]),
      );
      expect(
        report.openItems,
        contains('upstream_connector_version_vocabulary_missing'),
      );
    });

    test('reports the missing upstream impact vocabulary honestly', () {
      final report = _run(_log(), anchor: _anchor(impacts: const <String>[]));
      expect(report.openItems, contains('upstream_impact_vocabulary_missing'));
    });

    test('reports the missing upstream owner vocabulary honestly', () {
      final report = _run(_log(), anchor: _anchor(owners: const <String>[]));
      expect(report.openItems, contains('upstream_owner_vocabulary_missing'));
    });

    test('reports a canonical component that the witness does not name', () {
      final report = _run(
        _log(),
        anchor: _anchor(components: const <String>['connection']),
      );
      expect(report.openItems, contains('component_not_in_witness:reauth'));
    });

    test('sourceFor maps each component to its committed evidence source', () {
      expect(
        Sprint118DedupContract.sourceFor('connection'),
        'docs/planning/v1.3/sprint_118_connection_health_review.json',
      );
      expect(
        Sprint118DedupContract.sourceFor('support'),
        'docs/planning/v1.3/sprint_118_incident_support_intake.json',
      );
      expect(Sprint118DedupContract.sourceFor('unknown'), '');
    });
  });
}
