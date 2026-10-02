/// Sprint 117.37 — Beta Feedback Evidence Log.
///
/// Validates the eight canonical required_fields (feedback_id, consent,
/// provider, workflow, outcome, impact, evidence, limitations) and the
/// fail-closed structural rules of the log gate. The gate validates the log
/// *contract*; it does not claim a beta participant exists.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_beta_feedback_evidence_log.dart';

/// The fixture row used to prove the gate accepts a complete entry. It is a
/// structural fixture, not a recorded participant.
Sprint117BetaFeedbackEntry _fixture({String id = 'FB-11737-1'}) =>
    Sprint117BetaFeedbackEntry(
      feedbackId: id,
      consent: 'structural-fixture: cohort not started',
      provider: 'no_provider: no generation ran',
      workflow: 'no_workflow: beta not started',
      outcome: 'no_outcome: beta not started',
      impact: 'no_impact_claim',
      evidence: <String>['docs/evidence/sprint-117-37-manifest-20261002.json'],
      limitations: <String>[
        'fixture integrasi lokal; kohort beta belum dimulai (117.34)',
      ],
    );

/// One passing check per canonical field.
List<Sprint117FeedbackCheck> _passingChecks() => <Sprint117FeedbackCheck>[
  const Sprint117FeedbackCheck.pass(
    field: 'feedback_id',
    check: 'feedback_log_missing_fields_on_fixture',
    declared: 'no missing fields for a complete fixture entry',
    observed: 'no missing fields for a complete fixture entry',
  ),
  const Sprint117FeedbackCheck.pass(
    field: 'consent',
    check: 'consent_recorded_without_pseudonymised_participant',
    declared: 'consent carries a scope marker, never a participant identity',
    observed: 'consent scope marker, no participant field exists on the entry',
  ),
  const Sprint117FeedbackCheck.pass(
    field: 'provider',
    check: 'provider_identity_present_on_generation_row',
    declared: 'provider identity is reachable for a feedback entry',
    observed:
        'ai_generations.provider and ai_generation_jobs.provider_id exist; '
        'no feedback row is persisted yet, so no real provider is claimed',
  ),
  const Sprint117FeedbackCheck.pass(
    field: 'workflow',
    check: 'workflow_scope_recorded',
    declared: 'workflow is a required non-blank field on every entry',
    observed: 'workflow is required and blank entries fail the gate',
  ),
  const Sprint117FeedbackCheck.pass(
    field: 'outcome',
    check: 'outcome_is_required_and_non_blank',
    declared: 'outcome is a required non-blank field on every entry',
    observed: 'outcome is required and blank entries fail the gate',
  ),
  const Sprint117FeedbackCheck.pass(
    field: 'impact',
    check: 'impact_not_silently_defaulted',
    declared: 'impact must be stated, not implied by an absent value',
    observed: 'impact is required; an empty impact fails the gate',
  ),
  const Sprint117FeedbackCheck.pass(
    field: 'evidence',
    check: 'evidence_points_at_a_real_path',
    declared: 'at least one non-blank evidence reference per entry',
    observed:
        'evidence accepts ["  "] as missing and at least one surviving '
        'element as present; the shipped review table persists feedback '
        'per generation id',
  ),
  const Sprint117FeedbackCheck.pass(
    field: 'limitations',
    check: 'limitations_present_on_every_entry',
    declared: 'every entry states what the evidence does not cover',
    observed: 'limitations is required and blank-only lists fail the gate',
  ),
];

void main() {
  group('117.37 Beta Feedback Evidence Log', () {
    test('required fields are the eight canonical names, verbatim', () {
      expect(Sprint117BetaFeedbackLog.requiredFields, <String>[
        'feedback_id',
        'consent',
        'provider',
        'workflow',
        'outcome',
        'impact',
        'evidence',
        'limitations',
      ]);
    });

    test('a complete fixture entry has no missing fields', () {
      expect(Sprint117BetaFeedbackLog.missingFields(_fixture()), isEmpty);
    });

    test('every blank canonical field is reported by name', () {
      const bare = Sprint117BetaFeedbackEntry(
        feedbackId: '',
        consent: '',
        provider: '',
        workflow: '',
        outcome: '',
        impact: '',
        evidence: <String>[],
        limitations: <String>[],
      );

      expect(Sprint117BetaFeedbackLog.missingFields(bare), <String>[
        'feedback_id',
        'consent',
        'provider',
        'workflow',
        'outcome',
        'impact',
        'evidence',
        'limitations',
      ]);
    });

    test('a whitespace-only list element is blank, not present evidence', () {
      const blankElement = Sprint117BetaFeedbackEntry(
        feedbackId: 'FB-1',
        consent: 'c',
        provider: 'p',
        workflow: 'w',
        outcome: 'o',
        impact: 'i',
        evidence: <String>['   '],
        limitations: <String>['real limitation'],
      );

      expect(
        Sprint117BetaFeedbackLog.missingFields(blankElement),
        contains('evidence'),
      );
      expect(Sprint117BetaFeedbackLog.blankListElements(blankElement), <String>[
        'evidence:0',
      ]);
    });

    test('one blank element is named by field and index', () {
      const mixed = Sprint117BetaFeedbackEntry(
        feedbackId: 'FB-1',
        consent: 'c',
        provider: 'p',
        workflow: 'w',
        outcome: 'o',
        impact: 'i',
        evidence: <String>['ok', ''],
        limitations: <String>['ok', ''],
      );

      expect(Sprint117BetaFeedbackLog.blankListElements(mixed), <String>[
        'evidence:1',
        'limitations:1',
      ]);
    });

    test('a complete log with a passing check per field passes', () {
      final result = Sprint117BetaFeedbackLog.evaluate(
        entries: <Sprint117BetaFeedbackEntry>[_fixture()],
        checks: _passingChecks(),
      );

      expect(result.pass, isTrue);
      expect(result.failures, isEmpty);
      expect(result.verdict, Sprint117BetaFeedbackLog.passVerdict);
      expect(result.openItems, isEmpty);
      expect(result.fixtureEntries, 1);
    });

    test('an empty log fails instead of reporting a validated log', () {
      final result = Sprint117BetaFeedbackLog.evaluate(
        entries: const <Sprint117BetaFeedbackEntry>[],
        checks: _passingChecks(),
      );

      expect(result.pass, isFalse);
      expect(result.failures, contains('no_entries'));
      expect(result.verdict, Sprint117BetaFeedbackLog.failVerdict);
    });

    test('an incomplete entry fails and names the entry and field', () {
      const incomplete = Sprint117BetaFeedbackEntry(
        feedbackId: 'FB-11737-1',
        consent: '',
        provider: 'p',
        workflow: 'w',
        outcome: 'o',
        impact: 'i',
        evidence: <String>['e'],
        limitations: <String>['l'],
      );

      final result = Sprint117BetaFeedbackLog.evaluate(
        entries: const <Sprint117BetaFeedbackEntry>[incomplete],
        checks: _passingChecks(),
      );

      expect(result.pass, isFalse);
      expect(result.failures, contains('missing_field:FB-11737-1:consent'));
    });

    test('a blank-only list element fails the log', () {
      final result = Sprint117BetaFeedbackLog.evaluate(
        entries: const <Sprint117BetaFeedbackEntry>[
          Sprint117BetaFeedbackEntry(
            feedbackId: 'FB-11737-1',
            consent: 'c',
            provider: 'p',
            workflow: 'w',
            outcome: 'o',
            impact: 'i',
            evidence: <String>[' '],
            limitations: <String>['l'],
          ),
        ],
        checks: _passingChecks(),
      );

      expect(result.pass, isFalse);
      expect(
        result.failures,
        contains('blank_list_element:FB-11737-1:evidence:0'),
      );
    });

    test('a duplicated feedback id fails the log', () {
      final result = Sprint117BetaFeedbackLog.evaluate(
        entries: <Sprint117BetaFeedbackEntry>[_fixture(), _fixture()],
        checks: _passingChecks(),
      );

      expect(result.pass, isFalse);
      expect(result.failures, contains('duplicate_feedback_id:FB-11737-1'));
    });

    test('a required field with no check is a missing field check', () {
      final checks = _passingChecks()
        ..removeWhere((check) => check.field == 'impact');
      final result = Sprint117BetaFeedbackLog.evaluate(
        entries: <Sprint117BetaFeedbackEntry>[_fixture()],
        checks: checks,
      );

      expect(result.pass, isFalse);
      expect(result.failures, contains('missing_field_check:impact'));
    });

    test('a field whose only check is unmet never counts as passing', () {
      final checks = _passingChecks()
        ..removeWhere((check) => check.field == 'evidence')
        ..add(
          const Sprint117FeedbackCheck.unmet(
            field: 'evidence',
            check: 'evidence_exported_to_a_readable_log_file',
            declared: 'exported log file on disk',
            observed: 'no exported feedback log exists; beta not started',
          ),
        );

      final result = Sprint117BetaFeedbackLog.evaluate(
        entries: <Sprint117BetaFeedbackEntry>[_fixture()],
        checks: checks,
      );

      expect(result.pass, isFalse);
      expect(result.failures, contains('field_without_pass:evidence'));
      expect(
        result.openItems,
        contains('evidence:evidence_exported_to_a_readable_log_file'),
      );
    });

    test('an unmet check is reported as an open item, not a failure', () {
      final checks = <Sprint117FeedbackCheck>[
        ..._passingChecks(),
        const Sprint117FeedbackCheck.unmet(
          field: 'limitations',
          check: 'limitations_aggregated_into_a_single_live_document',
          declared: 'one aggregated limitations document',
          observed: 'no aggregated document exists; beta not started',
        ),
      ];

      final result = Sprint117BetaFeedbackLog.evaluate(
        entries: <Sprint117BetaFeedbackEntry>[_fixture()],
        checks: checks,
      );

      expect(result.pass, isTrue);
      expect(result.failures, isEmpty);
      expect(
        result.openItems,
        contains(
          'limitations:limitations_aggregated_into_a_single_live_document',
        ),
      );
    });

    test('a check on a non-canonical field fails as unknown', () {
      final result = Sprint117BetaFeedbackLog.evaluate(
        entries: <Sprint117BetaFeedbackEntry>[_fixture()],
        checks: <Sprint117FeedbackCheck>[
          ..._passingChecks(),
          const Sprint117FeedbackCheck.pass(
            field: 'sentiment',
            check: 'sentiment_scored',
            declared: 'a scored sentiment',
            observed: 'a scored sentiment',
          ),
        ],
      );

      expect(result.pass, isFalse);
      expect(result.failures, contains('unknown_field:sentiment'));
    });

    test('a duplicated check code fails the log', () {
      final result = Sprint117BetaFeedbackLog.evaluate(
        entries: <Sprint117BetaFeedbackEntry>[_fixture()],
        checks: <Sprint117FeedbackCheck>[
          ..._passingChecks(),
          ..._passingChecks(),
        ],
      );

      expect(result.pass, isFalse);
      expect(
        result.failures,
        contains(
          'duplicate_check:feedback_id:feedback_log_missing_fields_on_fixture',
        ),
      );
    });

    test('a blank declared or observed value is vacuous, never a pass', () {
      final result = Sprint117BetaFeedbackLog.evaluate(
        entries: <Sprint117BetaFeedbackEntry>[_fixture()],
        checks: <Sprint117FeedbackCheck>[
          ..._passingChecks()..removeWhere((check) => check.field == 'consent'),
          const Sprint117FeedbackCheck.pass(
            field: 'consent',
            check: 'consent_check_with_no_observation',
            declared: 'a declared claim',
            observed: '  ',
          ),
        ],
      );

      expect(result.pass, isFalse);
      expect(
        result.failures,
        contains('vacuous:consent:consent_check_with_no_observation'),
      );
      expect(result.failures, contains('field_without_pass:consent'));
    });

    test('the exported json names the step, the verdict and the failures', () {
      final result = Sprint117BetaFeedbackLog.evaluate(
        entries: <Sprint117BetaFeedbackEntry>[_fixture()],
        checks: _passingChecks(),
      );
      final decoded =
          jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>;

      expect(decoded['canonical_step'], '117.37');
      expect(decoded['document_role'], 'EVIDENCE');
      expect(decoded['verdict'], Sprint117BetaFeedbackLog.passVerdict);
      expect(decoded['pass'], isTrue);
      expect(decoded['required_fields'], hasLength(8));
      expect(decoded['failures'], isEmpty);
      expect(decoded['checks'], hasLength(8));
    });

    test('the gate claims no real participant and no live beta', () {
      // The fixture is structural only: the gate must not be readable as a
      // claim that a beta participant left feedback.
      final result = Sprint117BetaFeedbackLog.evaluate(
        entries: <Sprint117BetaFeedbackEntry>[_fixture()],
        checks: _passingChecks(),
      );
      final decoded =
          jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>;

      expect(result.fixtureEntries, 1);
      expect(decoded.containsKey('live_beta_executed'), isFalse);
      expect(result.verdict, isNot(contains('FEEDBACK_RECORDED')));
    });

    test('a gate run leaves no scratch residue in the source tree', () {
      final temp = Directory.systemTemp.createTempSync('sprint11737');
      try {
        final file = File('${temp.path}/gate.json')
          ..writeAsStringSync(
            jsonEncode(
              Sprint117BetaFeedbackLog.evaluate(
                entries: <Sprint117BetaFeedbackEntry>[_fixture()],
                checks: _passingChecks(),
              ).toJson(),
            ),
          );
        expect(file.existsSync(), isTrue);
      } finally {
        temp.deleteSync(recursive: true);
      }
      expect(temp.existsSync(), isFalse);
    });
  });
}
