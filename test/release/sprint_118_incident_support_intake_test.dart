import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_incident_support_intake.dart';

/// A single intake entry. Each test flips exactly the one thing it is about, so
/// a test that flips nothing proves the pass path exists and every other test
/// proves one way the gate refuses to take it.
Sprint118IncidentIntakeEntry _entry({
  String category = 'support',
  String incidentId = 'INTAKE-SUPPORT-REF',
  String source = 'support',
  String provider = Sprint118IncidentIntakeContract.unassignedProvider,
  String version = Sprint118IncidentIntakeContract.baseVersion,
  String impact = Sprint118IncidentIntakeContract.noImpact,
  String reproduction = Sprint118IncidentIntakeContract.declaredReproduction,
  String evidence =
      'docs/planning/v1.3/sprint_117_support_incident_readiness.json',
  String owner = Sprint118IncidentIntakeContract.incidentOwner,
}) {
  return Sprint118IncidentIntakeEntry(
    category: category,
    incidentId: incidentId,
    source: source,
    provider: provider,
    version: version,
    impact: impact,
    reproduction: reproduction,
    evidence: evidence,
    owner: owner,
  );
}

Sprint118IncidentIntake _intake({
  String releaseState = Sprint118IncidentIntakeContract.delayedReleaseState,
  List<Sprint118IncidentIntakeEntry>? entries,
}) {
  return Sprint118IncidentIntake(
    releaseState: releaseState,
    entries: entries ?? Sprint118IncidentIntakeContract.canonicalIntake.entries,
  );
}

/// The canonical entries with exactly one category replaced, so a test can flip
/// a single field without rebuilding the whole intake.
List<Sprint118IncidentIntakeEntry> _replacing(
  String category,
  Sprint118IncidentIntakeEntry replacement,
) {
  return <Sprint118IncidentIntakeEntry>[
    for (final e in Sprint118IncidentIntakeContract.canonicalIntake.entries)
      if (e.category == category) replacement else e,
  ];
}

Sprint118IncidentIntakeAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118IncidentIntakeContract.requiredBaselineVerdict,
  String releaseState = Sprint118IncidentIntakeContract.delayedReleaseState,
  String supportState = 'pass',
  String supportVerdict =
      Sprint118IncidentIntakeContract.requiredSupportVerdict,
  bool liveIncidentExecuted = false,
  List<String>? severityLevels,
  List<String>? owners,
  List<String>? readableSources,
}) {
  return Sprint118IncidentIntakeAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    supportState: supportState,
    supportVerdict: supportVerdict,
    liveIncidentExecuted: liveIncidentExecuted,
    severityLevels: severityLevels ?? const <String>['P0', 'P1', 'P2', 'P3'],
    owners: owners ?? const <String>['Choirudin', 'nephthys'],
    readableSources:
        readableSources ?? Sprint118IncidentIntakeContract.canonicalSources,
  );
}

Sprint118IncidentIntakeReport _run(
  Sprint118IncidentIntake intake, {
  Sprint118IncidentIntakeAnchor? anchor,
}) {
  return const Sprint118IncidentIntakeGate().evaluateWith(
    anchor ?? _anchor(),
    intake,
  );
}

void main() {
  group('118.6 Incident & Support Intake', () {
    test('declares the canonical step, title, fields, and paths', () {
      expect(Sprint118IncidentIntakeContract.canonicalStep, '118.6');
      expect(
        Sprint118IncidentIntakeContract.title,
        'Incident & Support Intake',
      );
      expect(
        Sprint118IncidentIntakeContract.manifestPath,
        'docs/planning/v1.3/sprint_118_incident_support_intake.json',
      );
      expect(Sprint118IncidentIntakeContract.requiredFields, <String>[
        'incident_id',
        'source',
        'provider',
        'version',
        'impact',
        'reproduction',
        'evidence',
        'owner',
      ]);
      expect(
        Sprint118IncidentIntakeContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118IncidentIntakeContract.requiredFields.length, 8);
      expect(Sprint118IncidentIntakeContract.incidentCategories.length, 10);
      expect(Sprint118IncidentIntakeContract.canonicalSources.length, 10);
      // Every canonical category maps to a distinct committed evidence source.
      final sources = <String>{
        for (final c in Sprint118IncidentIntakeContract.incidentCategories)
          Sprint118IncidentIntakeContract.sourceFor(c),
      };
      expect(sources.length, 10);
      // The impact vocabulary is derived from the readiness witness, plus the
      // no-impact marker.
      expect(
        Sprint118IncidentIntakeContract.impactVocabulary(const <String>[
          'P0',
          'P1',
        ]),
        <String>['P0', 'P1', 'none'],
      );
    });

    test('canonical intake covers the ten categories and claims no live '
        'incident', () {
      final intake = Sprint118IncidentIntakeContract.canonicalIntake;
      expect(intake.categories.length, 10);
      expect(intake.categories.toSet(), <String>{
        'support',
        'crash',
        'auth',
        'quota',
        'sync',
        'ai',
        'billing',
        'security',
        'privacy',
        'accessibility',
      });
      for (final entry in intake.entries) {
        expect(entry.impact, Sprint118IncidentIntakeContract.noImpact);
        expect(entry.owner, Sprint118IncidentIntakeContract.incidentOwner);
        for (final field in Sprint118IncidentIntakeContract.requiredFields) {
          expect(
            (entry.fields[field] ?? '').trim(),
            isNotEmpty,
            reason: '${entry.category}.$field must not be blank',
          );
        }
      }
    });

    test('passes on the canonical intake', () {
      final report = _run(_intake());
      expect(report.state, Sprint118IntakeState.pass);
      expect(report.verdict, 'INCIDENT_SUPPORT_INTAKE_VERIFIED_LOCAL');
      expect(report.intakeVerified, isTrue);
      expect(report.declaredCategories.length, 10);
      expect(report.incidentCount, 10);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118IncidentIntakeGate().evaluateWith(
        null,
        _intake(),
      );
      expect(report.state, Sprint118IntakeState.blocked);
      expect(report.verdict, 'SPRINT_118_INTAKE_EVIDENCE_UNREADABLE');
      expect(report.blockers, contains('committed_intake_evidence_unreadable'));
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _intake(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118IntakeState.blocked);
      expect(
        report.blockers,
        contains('baseline_not_frozen:SPRINT_118_BASELINE_EVIDENCE_VIOLATION'),
      );
    });

    test('blocks when the 117.6 support readiness is not a pass', () {
      final report = _run(
        _intake(),
        anchor: _anchor(supportVerdict: 'SUPPORT_INCIDENT_READINESS_MISSING'),
      );
      expect(report.state, Sprint118IntakeState.blocked);
      expect(
        report.blockers,
        contains('support_intake_not_ready:SUPPORT_INCIDENT_READINESS_MISSING'),
      );
    });

    test('fails when the release state disagrees with the baseline', () {
      final report = _run(
        _intake(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'GA_DELAYED'),
      );
      expect(report.state, Sprint118IntakeState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a live incident is claimed on the delayed path', () {
      final report = _run(
        _intake(),
        anchor: _anchor(liveIncidentExecuted: true),
      );
      expect(report.state, Sprint118IntakeState.fail);
      expect(
        report.violations,
        contains('live_incident_claimed_executed_without_release'),
      );
    });

    test('fails when an entry claims a live impact without a release', () {
      final report = _run(
        _intake(
          entries: _replacing('crash', _entry(category: 'crash', impact: 'P0')),
        ),
      );
      expect(report.state, Sprint118IntakeState.fail);
      expect(
        report.violations,
        contains('incident_claims_live_impact_without_release:crash:P0'),
      );
    });

    test('fails when an entry carries an unknown impact', () {
      final report = _run(
        _intake(
          entries: _replacing(
            'crash',
            _entry(category: 'crash', impact: 'SEVERE'),
          ),
        ),
      );
      expect(report.state, Sprint118IntakeState.fail);
      expect(report.violations, contains('entry_unknown_impact:crash:SEVERE'));
    });

    test('fails when an entry carries an unknown owner', () {
      final report = _run(
        _intake(
          entries: _replacing(
            'auth',
            _entry(category: 'auth', owner: 'nobody'),
          ),
        ),
      );
      expect(report.state, Sprint118IntakeState.fail);
      expect(report.violations, contains('entry_unknown_owner:auth:nobody'));
    });

    test('fails when an entry cites unreadable evidence', () {
      final report = _run(
        _intake(
          entries: _replacing(
            'sync',
            _entry(category: 'sync', evidence: 'docs/planning/missing.json'),
          ),
        ),
      );
      expect(report.state, Sprint118IntakeState.fail);
      expect(
        report.violations,
        contains('entry_unreadable_evidence:sync:docs/planning/missing.json'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _intake(
          entries: _replacing(
            'quota',
            _entry(category: 'quota', incidentId: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118IntakeState.fail);
      expect(report.violations, contains('entry_blank_incident_id:quota'));
    });

    test('fails on a duplicate category', () {
      final entries = <Sprint118IncidentIntakeEntry>[
        ...Sprint118IncidentIntakeContract.canonicalIntake.entries,
        _entry(category: 'support', incidentId: 'INTAKE-SUPPORT-DUP'),
      ];
      final report = _run(_intake(entries: entries));
      expect(report.state, Sprint118IntakeState.fail);
      expect(report.violations, contains('category_duplicate:support'));
    });

    test('fails when a canonical category is missing', () {
      final entries = <Sprint118IncidentIntakeEntry>[
        for (final e in Sprint118IncidentIntakeContract.canonicalIntake.entries)
          if (e.category != 'billing') e,
      ];
      final report = _run(_intake(entries: entries));
      expect(report.state, Sprint118IntakeState.fail);
      expect(report.violations, contains('category_missing:billing'));
    });

    test('fails when an entry names an unknown category', () {
      final report = _run(
        _intake(
          entries: _replacing('support', _entry(category: 'unknown_category')),
        ),
      );
      expect(report.state, Sprint118IntakeState.fail);
      // The replacement also removes the real 'support' entry, so both the
      // unknown-category and the missing-category violations are expected.
      expect(report.violations, contains('category_unknown:unknown_category'));
      expect(report.violations, contains('category_missing:support'));
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _intake(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.3/sprint_117_support_incident_readiness.json',
          ],
        ),
      );
      expect(report.state, Sprint118IntakeState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('reports the missing upstream severity vocabulary honestly', () {
      final report = _run(
        _intake(),
        anchor: _anchor(severityLevels: const <String>[]),
      );
      expect(
        report.openItems,
        contains('upstream_severity_vocabulary_missing'),
      );
    });

    test('reports the missing upstream owner vocabulary honestly', () {
      final report = _run(_intake(), anchor: _anchor(owners: const <String>[]));
      expect(report.openItems, contains('upstream_owner_vocabulary_missing'));
    });

    test('sourceFor maps each category to its committed evidence source', () {
      expect(
        Sprint118IncidentIntakeContract.sourceFor('support'),
        'docs/planning/v1.3/sprint_117_support_incident_readiness.json',
      );
      expect(
        Sprint118IncidentIntakeContract.sourceFor('crash'),
        'docs/planning/v1.2/sprint_114_crash_startup_health.json',
      );
      expect(Sprint118IncidentIntakeContract.sourceFor('unknown'), '');
    });
  });
}
