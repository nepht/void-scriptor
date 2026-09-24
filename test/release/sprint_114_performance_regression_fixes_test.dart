import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/performance_regression_fixes_v114.dart';

void main() {
  group('114.30 Performance Regression Fixes', () {
    test('empty register is blocked without claiming a performance fix', () {
      final report = PerformanceRegressionFixRegister().evaluate();

      expect(report.status, PerformanceRegressionStatus.blocked);
      expect(report.fixCount, 0);
      expect(report.limitations, isNotEmpty);
    });

    test('complete fix records profile, budget, before-after and regression', () {
      const fix = PerformanceRegressionFix(
        issueId: 'PERF-001',
        profile: 'Search p95 profile identifies repeated index rebuild.',
        rootCause: 'The query rebuilds the same immutable index per request.',
        budget: 'Search p95 must remain <= 1000ms.',
        fix:
            'Reuse the index for the request scope without changing ownership.',
        beforeAfter: 'Before 1500ms p95; after 700ms p95.',
        regressionTest:
            'test/release/sprint_114_performance_regression_fixes_test.dart',
      );

      expect(PerformanceRegressionFix.requiredFields(fix), isEmpty);
      final report = PerformanceRegressionFixRegister()..add(fix);
      expect(report.evaluate().status, PerformanceRegressionStatus.pass);
      expect(report.evaluate().fixCount, 1);
    });

    test('incomplete fix fails with named requirements', () {
      final register = PerformanceRegressionFixRegister()
        ..add(
          const PerformanceRegressionFix(
            issueId: '',
            profile: '',
            rootCause: '',
            budget: '',
            fix: '',
            beforeAfter: '',
            regressionTest: '',
          ),
        );
      final report = register.evaluate();

      expect(report.status, PerformanceRegressionStatus.fail);
      final notes = report.limitations.join(' ');
      for (final field in <String>[
        'issue_id',
        'profile',
        'root_cause',
        'budget',
        'fix',
        'before_after',
        'regression_test',
      ]) {
        expect(notes, contains(field));
      }
    });

    test('manifest records canonical requirements and local limits', () {
      final manifest =
          json.decode(
                File(
                  'docs/planning/v1.2/sprint_114_performance_regression_fixes.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '114.30');
      expect(
        manifest['requirements'],
        containsAll(<String>[
          'profile',
          'root_cause',
          'budget',
          'fix',
          'before_after',
          'regression_test',
        ]),
      );
      expect(manifest['limits'], isNotEmpty);
      expect(manifest['status'], isNotEmpty);
    });
  });
}
