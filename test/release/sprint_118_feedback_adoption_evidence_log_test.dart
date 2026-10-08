import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_feedback_adoption_evidence_log.dart';

/// A single log entry. Each test flips exactly the one thing it is about, so a
/// test that flips nothing proves the pass path exists and every other test
/// proves one way the gate refuses to take it.
Sprint118FeedbackEntry _entry({
  String workflow = 'writer',
  String evidenceId = 'FEEDBACK-WRITER-REF',
  String source =
      'docs/planning/v1.2/sprint_113_writer_workflow_validation.json',
  String consent = Sprint118FeedbackAdoptionContract.noParticipantConsent,
  String outcome = Sprint118FeedbackAdoptionContract.noLiveOutcome,
  String friction = Sprint118FeedbackAdoptionContract.noFrictionRecorded,
  String request = 'requested:community_export',
  List<String> limitations = const <String>['no_live_telemetry'],
  bool requestIsCommitment = false,
}) {
  return Sprint118FeedbackEntry(
    workflow: workflow,
    evidenceId: evidenceId,
    source: source,
    consent: consent,
    outcome: outcome,
    friction: friction,
    request: request,
    limitations: limitations,
    requestIsCommitment: requestIsCommitment,
  );
}

Sprint118FeedbackAdoptionLog _log({
  String releaseState = Sprint118FeedbackAdoptionContract.delayedReleaseState,
  List<Sprint118FeedbackEntry>? entries,
}) {
  return Sprint118FeedbackAdoptionLog(
    releaseState: releaseState,
    entries: entries ?? Sprint118FeedbackAdoptionContract.canonicalLog.entries,
  );
}

/// The canonical entries with exactly one workflow replaced, so a test can flip
/// a single field without rebuilding the whole log.
List<Sprint118FeedbackEntry> _replacing(
  String workflow,
  Sprint118FeedbackEntry replacement,
) {
  return <Sprint118FeedbackEntry>[
    for (final e in Sprint118FeedbackAdoptionContract.canonicalLog.entries)
      if (e.workflow == workflow) replacement else e,
  ];
}

Sprint118FeedbackAdoptionAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118FeedbackAdoptionContract.requiredBaselineVerdict,
  String releaseState = Sprint118FeedbackAdoptionContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118FeedbackAdoptionContract.requiredCharterVerdict,
  bool liveAdoptionExecuted = false,
  List<String>? workflows,
  List<String>? outcomes,
  String consentType = 'EXPLICIT_WRITTEN',
  List<String>? readableSources,
}) {
  return Sprint118FeedbackAdoptionAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    liveAdoptionExecuted: liveAdoptionExecuted,
    workflows:
        workflows ?? Sprint118FeedbackAdoptionContract.canonicalWorkflows,
    outcomes:
        outcomes ??
        const <String>[
          'completion',
          'failure',
          'recovery',
          'abandonment',
          'workaround',
          'repeat_use',
          'limitations',
        ],
    consentType: consentType,
    readableSources:
        readableSources ?? Sprint118FeedbackAdoptionContract.canonicalSources,
  );
}

Sprint118FeedbackAdoptionReport _run(
  Sprint118FeedbackAdoptionLog log, {
  Sprint118FeedbackAdoptionAnchor? anchor,
}) {
  return const Sprint118FeedbackAdoptionGate().evaluateWith(
    anchor ?? _anchor(),
    log,
  );
}

void main() {
  group('118.21 Feedback & Adoption Evidence Log', () {
    test('declares the canonical step, title, fields, and paths', () {
      expect(Sprint118FeedbackAdoptionContract.canonicalStep, '118.21');
      expect(
        Sprint118FeedbackAdoptionContract.title,
        'Feedback & Adoption Evidence Log',
      );
      expect(
        Sprint118FeedbackAdoptionContract.manifestPath,
        'docs/planning/v1.3/sprint_118_feedback_adoption_evidence_log.json',
      );
      expect(Sprint118FeedbackAdoptionContract.requiredFields, <String>[
        'evidence_id',
        'source',
        'consent',
        'workflow',
        'outcome',
        'friction',
        'request',
        'limitations',
      ]);
      expect(
        Sprint118FeedbackAdoptionContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118FeedbackAdoptionContract.requiredFields.length, 8);
      expect(Sprint118FeedbackAdoptionContract.canonicalWorkflows.length, 5);
      expect(Sprint118FeedbackAdoptionContract.canonicalSources.length, 5);
      // Every canonical workflow maps to a distinct committed evidence source.
      final sources = <String>{
        for (final w in Sprint118FeedbackAdoptionContract.canonicalWorkflows)
          Sprint118FeedbackAdoptionContract.sourceFor(w),
      };
      expect(sources.length, 5);
      // The outcome vocabulary is derived from the workflow witness, plus the
      // no-live-outcome marker.
      expect(
        Sprint118FeedbackAdoptionContract.outcomeVocabulary(const <String>[
          'completion',
          'failure',
        ]),
        <String>['completion', 'failure', 'no_live_outcome'],
      );
      // The consent vocabulary is derived from the consent witness, plus the
      // no-participant marker.
      expect(
        Sprint118FeedbackAdoptionContract.consentVocabulary('EXPLICIT_WRITTEN'),
        <String>['EXPLICIT_WRITTEN', 'no_participant_consent'],
      );
    });

    test('canonical log covers the five workflows and claims no live '
        'outcome', () {
      final log = Sprint118FeedbackAdoptionContract.canonicalLog;
      expect(log.workflows.length, 5);
      expect(log.workflows.toSet(), <String>{
        'writer',
        'lore',
        'simulation',
        'sharing',
        'publishing',
      });
      for (final entry in log.entries) {
        expect(entry.outcome, Sprint118FeedbackAdoptionContract.noLiveOutcome);
        expect(
          entry.consent,
          Sprint118FeedbackAdoptionContract.noParticipantConsent,
        );
        expect(entry.requestIsCommitment, isFalse);
        for (final field in Sprint118FeedbackAdoptionContract.requiredFields) {
          expect(
            (entry.fields[field] ?? '').trim(),
            isNotEmpty,
            reason: '${entry.workflow}.$field must not be blank',
          );
        }
      }
    });

    test('passes on the canonical log', () {
      final report = _run(_log());
      expect(report.state, Sprint118FeedbackLogState.pass);
      expect(report.verdict, 'FEEDBACK_ADOPTION_EVIDENCE_LOG_VERIFIED_LOCAL');
      expect(report.logVerified, isTrue);
      expect(report.declaredWorkflows.length, 5);
      expect(report.entryCount, 5);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118FeedbackAdoptionGate().evaluateWith(
        null,
        _log(),
      );
      expect(report.state, Sprint118FeedbackLogState.blocked);
      expect(report.verdict, 'SPRINT_118_FEEDBACK_LOG_EVIDENCE_UNREADABLE');
      expect(
        report.blockers,
        contains('committed_feedback_log_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _log(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118FeedbackLogState.blocked);
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
      expect(report.state, Sprint118FeedbackLogState.blocked);
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
      expect(report.state, Sprint118FeedbackLogState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a live adoption is claimed on the delayed path', () {
      final report = _run(_log(), anchor: _anchor(liveAdoptionExecuted: true));
      expect(report.state, Sprint118FeedbackLogState.fail);
      expect(
        report.violations,
        contains('live_adoption_claimed_executed_without_release'),
      );
    });

    test('fails when an entry claims a live outcome without a release', () {
      final report = _run(
        _log(
          entries: _replacing(
            'writer',
            _entry(workflow: 'writer', outcome: 'completion'),
          ),
        ),
      );
      expect(report.state, Sprint118FeedbackLogState.fail);
      expect(
        report.violations,
        contains(
          'workflow_claims_live_outcome_without_release:writer:completion',
        ),
      );
    });

    test('fails when an entry claims participant consent without a '
        'participant', () {
      final report = _run(
        _log(
          entries: _replacing(
            'lore',
            _entry(workflow: 'lore', consent: 'EXPLICIT_WRITTEN'),
          ),
        ),
      );
      expect(report.state, Sprint118FeedbackLogState.fail);
      expect(
        report.violations,
        contains(
          'participant_consent_claimed_without_participant:lore:'
          'EXPLICIT_WRITTEN',
        ),
      );
    });

    test('fails when an entry carries an unknown consent', () {
      final report = _run(
        _log(
          entries: _replacing(
            'lore',
            _entry(workflow: 'lore', consent: 'IMPLIED'),
          ),
        ),
      );
      expect(report.state, Sprint118FeedbackLogState.fail);
      expect(report.violations, contains('entry_unknown_consent:lore:IMPLIED'));
    });

    test('fails when an entry carries an unknown outcome', () {
      final report = _run(
        _log(
          entries: _replacing(
            'simulation',
            _entry(workflow: 'simulation', outcome: 'SUCCESS'),
          ),
        ),
      );
      expect(report.state, Sprint118FeedbackLogState.fail);
      expect(
        report.violations,
        contains('entry_unknown_outcome:simulation:SUCCESS'),
      );
    });

    test('fails when a request is treated as a commitment', () {
      final report = _run(
        _log(
          entries: _replacing(
            'writer',
            _entry(workflow: 'writer', requestIsCommitment: true),
          ),
        ),
      );
      expect(report.state, Sprint118FeedbackLogState.fail);
      expect(
        report.violations,
        contains('request_treated_as_commitment:writer'),
      );
    });

    test('fails when a request is malformed', () {
      final report = _run(
        _log(
          entries: _replacing(
            'sharing',
            _entry(workflow: 'sharing', request: 'community_export'),
          ),
        ),
      );
      expect(report.state, Sprint118FeedbackLogState.fail);
      expect(
        report.violations,
        contains('request_malformed:sharing:community_export'),
      );
    });

    test('accepts the no-request marker as a well-formed request', () {
      final report = _run(
        _log(
          entries: _replacing(
            'sharing',
            _entry(
              workflow: 'sharing',
              request: Sprint118FeedbackAdoptionContract.noRequestRecorded,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118FeedbackLogState.pass);
      expect(report.violations, isEmpty);
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _log(
          entries: _replacing(
            'publishing',
            _entry(workflow: 'publishing', evidenceId: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118FeedbackLogState.fail);
      expect(report.violations, contains('entry_blank_evidence_id:publishing'));
    });

    test('fails when limitations are empty', () {
      final report = _run(
        _log(
          entries: _replacing(
            'lore',
            _entry(workflow: 'lore', limitations: const <String>[]),
          ),
        ),
      );
      expect(report.state, Sprint118FeedbackLogState.fail);
      expect(report.violations, contains('entry_blank_limitations:lore'));
    });

    test('fails on a duplicate workflow', () {
      final entries = <Sprint118FeedbackEntry>[
        ...Sprint118FeedbackAdoptionContract.canonicalLog.entries,
        _entry(workflow: 'writer', evidenceId: 'FEEDBACK-WRITER-DUP'),
      ];
      final report = _run(_log(entries: entries));
      expect(report.state, Sprint118FeedbackLogState.fail);
      expect(report.violations, contains('workflow_duplicate:writer'));
    });

    test('fails when a canonical workflow is missing', () {
      final entries = <Sprint118FeedbackEntry>[
        for (final e in Sprint118FeedbackAdoptionContract.canonicalLog.entries)
          if (e.workflow != 'publishing') e,
      ];
      final report = _run(_log(entries: entries));
      expect(report.state, Sprint118FeedbackLogState.fail);
      expect(report.violations, contains('workflow_missing:publishing'));
    });

    test('fails when an entry names an unknown workflow', () {
      final report = _run(
        _log(
          entries: _replacing('writer', _entry(workflow: 'unknown_workflow')),
        ),
      );
      expect(report.state, Sprint118FeedbackLogState.fail);
      // The replacement also removes the real 'writer' entry, so both the
      // unknown-workflow and the missing-workflow violations are expected.
      expect(report.violations, contains('workflow_unknown:unknown_workflow'));
      expect(report.violations, contains('workflow_missing:writer'));
    });

    test('fails when an entry cites an unreadable source', () {
      final report = _run(
        _log(
          entries: _replacing(
            'simulation',
            _entry(
              workflow: 'simulation',
              source: 'docs/planning/missing.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118FeedbackLogState.fail);
      expect(
        report.violations,
        contains(
          'entry_unreadable_source:simulation:docs/planning/missing.json',
        ),
      );
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _log(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.2/sprint_113_writer_workflow_validation.json',
          ],
        ),
      );
      expect(report.state, Sprint118FeedbackLogState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('reports the missing upstream workflow vocabulary honestly', () {
      final report = _run(_log(), anchor: _anchor(workflows: const <String>[]));
      expect(
        report.openItems,
        contains('upstream_workflow_vocabulary_missing'),
      );
    });

    test('reports the missing upstream outcome vocabulary honestly', () {
      final report = _run(_log(), anchor: _anchor(outcomes: const <String>[]));
      expect(report.openItems, contains('upstream_outcome_vocabulary_missing'));
    });

    test('reports the missing upstream consent vocabulary honestly', () {
      final report = _run(_log(), anchor: _anchor(consentType: ''));
      expect(report.openItems, contains('upstream_consent_vocabulary_missing'));
    });

    test('sourceFor maps each workflow to its committed evidence source', () {
      expect(
        Sprint118FeedbackAdoptionContract.sourceFor('writer'),
        'docs/planning/v1.2/sprint_113_writer_workflow_validation.json',
      );
      expect(
        Sprint118FeedbackAdoptionContract.sourceFor('publishing'),
        'docs/planning/v1.2/sprint_112_end_to_end_publishing_workflow.json',
      );
      expect(Sprint118FeedbackAdoptionContract.sourceFor('unknown'), '');
    });
  });
}
