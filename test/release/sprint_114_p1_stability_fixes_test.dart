import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/p1_stability_fixes_v114.dart';

void main() {
  group('114.29 P1 Stability Fixes', () {
    test('empty register is blocked without claiming a stability fix', () {
      final report = P1StabilityFixRegister().evaluate();

      expect(report.status, P1StabilityStatus.blocked);
      expect(report.fixCount, 0);
      expect(report.limitations, isNotEmpty);
    });

    test('complete fix records every canonical requirement', () {
      const fix = P1StabilityFix(
        issueId: 'P1-001',
        reproduction:
            'Project-open workflow fails after a recoverable regression.',
        minimalChange: 'Narrow validation correction in the affected workflow.',
        regressionTest: 'test/release/sprint_114_p1_stability_fixes_test.dart',
        review: 'Scoped diff and analyzer review.',
        riskUpdate:
            'Residual risk remains limited to external production observation.',
        releaseNote: 'Documented as a maintenance stability correction.',
      );

      expect(P1StabilityFix.requiredFields(fix), isEmpty);
      final report = P1StabilityFixRegister()..add(fix);
      expect(report.evaluate().status, P1StabilityStatus.pass);
      expect(report.evaluate().fixCount, 1);
    });

    test('incomplete fix fails with named requirements', () {
      final register = P1StabilityFixRegister()
        ..add(
          const P1StabilityFix(
            issueId: '',
            reproduction: '',
            minimalChange: '',
            regressionTest: '',
            review: '',
            riskUpdate: '',
            releaseNote: '',
          ),
        );
      final report = register.evaluate();

      expect(report.status, P1StabilityStatus.fail);
      final notes = report.limitations.join(' ');
      expect(notes, contains('issue_id'));
      expect(notes, contains('reproduction'));
      expect(notes, contains('minimal_change'));
      expect(notes, contains('regression_test'));
      expect(notes, contains('review'));
      expect(notes, contains('risk_update'));
      expect(notes, contains('release_note'));
    });

    test('manifest records canonical requirements and local limits', () {
      final manifest =
          json.decode(
                File(
                  'docs/planning/v1.2/sprint_114_p1_stability_fixes.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '114.29');
      expect(
        manifest['requirements'],
        containsAll(<String>[
          'reproduction',
          'minimal_change',
          'regression_test',
          'review',
          'risk_update',
          'release_note',
        ]),
      );
      expect(manifest['limits'], isNotEmpty);
      expect(manifest['status'], isNotEmpty);
    });
  });
}
