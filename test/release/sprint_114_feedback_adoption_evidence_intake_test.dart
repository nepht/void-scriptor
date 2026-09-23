import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/feedback_adoption_evidence_intake.dart';

void main() {
  group('114.6 Feedback & Adoption Evidence Intake', () {
    test('empty intake is blocked rather than claiming adoption success', () {
      final decision = FeedbackAdoptionIntake().evaluate();

      expect(decision.state, FeedbackAdoptionState.blocked);
      expect(decision.evidenceCount, 0);
      expect(decision.notes, anyElement(contains('Belum ada evidence')));
    });

    test('incomplete evidence reports every canonical field', () {
      final intake = FeedbackAdoptionIntake()
        ..add(
          const AdoptionEvidence(
            evidenceId: 'ADOPT-001',
            source: '',
            consent: '',
            workflow: 'project-open',
            outcome: '',
            friction: '',
            limitations: <String>[],
            confidence: '',
          ),
        );

      final decision = intake.evaluate();

      expect(decision.state, FeedbackAdoptionState.fail);
      expect(decision.missingFields, <String>[
        'source',
        'consent',
        'outcome',
        'friction',
        'limitations',
        'confidence',
      ]);
    });

    test(
      'complete evidence is retained without collecting creative content',
      () {
        final intake = FeedbackAdoptionIntake()
          ..add(
            const AdoptionEvidence(
              evidenceId: 'ADOPT-002',
              source: 'local_interview',
              consent: 'recorded',
              workflow: 'project-open',
              outcome: 'completed',
              friction: 'none reported',
              limitations: <String>['single local workflow'],
              confidence: 'medium',
            ),
          );

        final decision = intake.evaluate();

        expect(decision.state, FeedbackAdoptionState.pass);
        expect(decision.evidenceCount, 1);
        expect(decision.missingFields, isEmpty);
        expect(intake.records.single.workflow, 'project-open');
        expect(decision.notes, anyElement(contains('creative content')));
      },
    );

    test('manifest declares canonical fields and evidence limits', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_feedback_adoption_evidence_intake.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.6');
      expect(document['required_fields'], <dynamic>[
        'evidence_id',
        'source',
        'consent',
        'workflow',
        'outcome',
        'friction',
        'limitations',
        'confidence',
      ]);
      expect(document['content_collection'], 'excluded');
      expect(document['external_adoption'], 'DEFERRED-EXTERNAL');
    });
  });
}
