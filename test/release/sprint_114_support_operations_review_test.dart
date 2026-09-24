import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/support_operations_review.dart';

void main() {
  group('114.7 Support Operations Review', () {
    test('empty review is blocked without claiming support health', () {
      final decision = SupportOperationsReview().evaluate();

      expect(decision.state, SupportOperationsState.blocked);
      expect(decision.volume, 0);
      expect(decision.notes, anyElement(contains('DEFERRED-EXTERNAL')));
    });

    test('invalid support data fails on canonical dimensions', () {
      final review = SupportOperationsReview()
        ..add(
          const SupportCase(
            caseId: 'SUP-001',
            severity: '',
            openedAt: '2026-09-24T08:00:00Z',
            firstResponseAt: '2026-09-24T07:00:00Z',
            resolvedAt: '2026-09-24T06:00:00Z',
            workaroundProvided: false,
            documentationRef: '',
          ),
        );

      final decision = review.evaluate();

      expect(decision.state, SupportOperationsState.fail);
      expect(decision.invalidFields, <String>[
        'severity',
        'response_time',
        'resolution_time',
      ]);
    });

    test('valid review reports volume, metrics, and honest gaps', () {
      final review = SupportOperationsReview()
        ..add(
          const SupportCase(
            caseId: 'SUP-002',
            severity: 'high',
            openedAt: '2026-09-24T08:00:00Z',
            firstResponseAt: '2026-09-24T08:30:00Z',
            resolvedAt: '2026-09-24T11:00:00Z',
            workaroundProvided: true,
            documentationRef: 'docs/troubleshooting/export.md',
          ),
        )
        ..add(
          const SupportCase(
            caseId: 'SUP-003',
            severity: 'low',
            openedAt: '2026-09-24T09:00:00Z',
            firstResponseAt: null,
            resolvedAt: null,
            workaroundProvided: false,
            documentationRef: '',
            repeatOfCaseId: 'SUP-002',
          ),
        );

      final decision = review.evaluate();

      expect(decision.state, SupportOperationsState.pass);
      expect(decision.volume, 2);
      expect(decision.metrics.severityCounts, <String, int>{
        'high': 1,
        'low': 1,
      });
      expect(decision.metrics.responseTimeCoverage, 1);
      expect(decision.metrics.resolutionTimeCoverage, 1);
      expect(decision.metrics.repeatRate, 0.5);
      expect(decision.metrics.workaroundCoverage, 1);
      expect(decision.metrics.documentationGapCount, 1);
      expect(decision.gaps, <String>[
        'response_time',
        'resolution_time',
        'workaround',
        'documentation_gap',
      ]);
    });

    test('manifest declares canonical dimensions and external deferral', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_support_operations_review.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.7');
      expect(document['dimensions'], <dynamic>[
        'volume',
        'severity',
        'response_time',
        'resolution_time',
        'repeat_rate',
        'workaround',
        'documentation_gap',
      ]);
      expect(document['external_support_operations'], 'DEFERRED-EXTERNAL');
      expect(document['content_collection'], 'excluded');
    });
  });
}
