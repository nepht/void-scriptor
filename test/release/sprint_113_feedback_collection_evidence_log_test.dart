/// Test for Feedback Collection & Evidence Log (Step 113.28).
/// Validates the eight canonical required_fields — feedback_id, source,
/// consent, workflow, observation, impact, evidence, limitations — plus the
/// blocked/fail/pass decision of the evidence log.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/feedback_collection_evidence_log.dart';

void main() {
  final log = FeedbackCollectionLog();

  group('113.28 Feedback Collection & Evidence Log', () {
    test('complete entry carries all eight canonical fields', () {
      const entry = FeedbackEntry(
        feedbackId: 'FB-001',
        source: 'pilot-cohort/session-1',
        consent: 'recorded: cohort-consent-v1',
        workflow: 'novel-draft-export',
        observation:
            'Penulis kehilangan alur saat panel export berada di luar viewport.',
        impact: 'medium',
        evidence: ['docs/evidence/pilot/session-1-notes.md'],
        limitations: [
          'fixture integrasi lokal; partisipan belum didaftarkan (113.3)',
        ],
      );

      expect(FeedbackEntry.requiredFieldNames, <String>[
        'feedback_id',
        'source',
        'consent',
        'workflow',
        'observation',
        'impact',
        'evidence',
        'limitations',
      ]);
      expect(log.missingFields(entry), isEmpty);
    });

    test('missing or blank fields are reported by canonical name', () {
      const bare = FeedbackEntry(
        feedbackId: 'FB-002',
        source: '',
        consent: '',
        workflow: '',
        observation: '',
        impact: '',
        evidence: [],
        limitations: [],
      );

      final missing = log.missingFields(bare);
      expect(missing, <String>[
        'source',
        'consent',
        'workflow',
        'observation',
        'impact',
        'evidence',
        'limitations',
      ]);
      expect(missing, isNot(contains('feedback_id')));
    });

    test('blank feedback_id is reported as feedback_id', () {
      const noId = FeedbackEntry(
        feedbackId: '  ',
        source: 's',
        consent: 'c',
        workflow: 'w',
        observation: 'o',
        impact: 'high',
        evidence: ['e'],
        limitations: ['l'],
      );
      expect(log.missingFields(noId), <String>['feedback_id']);
    });

    test('empty log is blocked pending real pilot feedback', () {
      final decision = log.evaluate();
      expect(decision.decision, FeedbackDecision.blocked);
      expect(decision.entryCount, 0);
      expect(
        decision.limitations.join(' '),
        contains('113.3'),
        reason: 'kohort/persetujuan partisipan belum dimulai (step 113.3)',
      );
    });

    test('entry with incomplete fields fails the log decision', () {
      final incomplete = FeedbackCollectionLog()
        ..add(
          const FeedbackEntry(
            feedbackId: 'FB-003',
            source: 'pilot-cohort/session-2',
            consent: '',
            workflow: 'character-workspace',
            observation: 'Dialog hapus tanpa konfirmasi keranjang.',
            impact: 'high',
            evidence: ['docs/evidence/pilot/session-2-notes.md'],
            limitations: ['consent tidak tercatat'],
          ),
        );

      final decision = incomplete.evaluate();
      expect(decision.decision, FeedbackDecision.fail);
      expect(decision.limitations.join(' '), contains('consent'));
    });

    test('complete entries pass and retain their limitations', () {
      final complete = FeedbackCollectionLog()
        ..add(
          const FeedbackEntry(
            feedbackId: 'FB-004',
            source: 'internal-dogfood/run-1',
            consent: 'recorded: internal-no-personal-data',
            workflow: 'timeline-clip-edit',
            observation: 'Resize handle tidak terlihat pada zoom rendah.',
            impact: 'low',
            evidence: ['docs/evidence/dogfood/run-1-notes.md'],
            limitations: ['pengamat internal, bukan partisipan pilot'],
          ),
        );

      final decision = complete.evaluate();
      expect(decision.decision, FeedbackDecision.pass);
      expect(decision.entryCount, 1);
      expect(decision.limitations.join(' '), contains('pengamat internal'));
    });

    test('manifest records all eight required fields with live status', () {
      final manifest =
          json.decode(
                File(
                  'docs/planning/v1.2/sprint_113_feedback_collection_evidence_log.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '113.28');
      final fields = manifest['required_fields'] as Map<String, dynamic>;
      expect(fields.keys.toSet(), <String>{
        'feedback_id',
        'source',
        'consent',
        'workflow',
        'observation',
        'impact',
        'evidence',
        'limitations',
      });
      for (final value in fields.values) {
        final entry = value as Map<String, dynamic>;
        expect(entry['description'], isNotEmpty);
        expect(entry['status'], isNotEmpty);
      }
      expect(manifest['limits'], isNotEmpty);
      expect(manifest['decision'], isNotEmpty);
    });
  });
}
