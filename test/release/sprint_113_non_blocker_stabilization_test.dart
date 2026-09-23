/// Test for Non-Blocker Stabilization (Step 113.32).
/// Validates the six canonical requirements — risk_assessed, minimal_change,
/// tests_added, reviewed, no_schema_break, documented — and the
/// blocked/fail/pass state of the stabilization log.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/non_blocker_stabilization.dart';

void main() {
  final log = StabilizationLog();

  group('113.32 Non-Blocker Stabilization', () {
    test('complete change carries all six canonical requirements', () {
      const change = StabilizationChange(
        issueId: 'NB-201',
        riskAssessment:
            'Risiko rendah: perbaikan teks label tanpa menyentuh schema atau '
            'alur data.',
        minimalChange: true,
        tests: <String>[
          'test/release/sprint_113_non_blocker_stabilization_test.dart',
        ],
        review: 'Reviewer: cron self-review dua jalur (diff + gate).',
        noSchemaBreak: true,
        documentation:
            'Dokumentasi diperbarui pada docs/architecture/07_development_guide.md.',
      );

      expect(StabilizationChange.requiredRequirementNames, <String>[
        'risk_assessed',
        'minimal_change',
        'tests_added',
        'reviewed',
        'no_schema_break',
        'documented',
      ]);
      expect(log.missingRequirements(change), isEmpty);
    });

    test('unmet requirements are reported by canonical name', () {
      const bare = StabilizationChange(
        issueId: 'NB-202',
        riskAssessment: '',
        minimalChange: false,
        tests: <String>[],
        review: '',
        noSchemaBreak: false,
        documentation: '',
      );

      expect(log.missingRequirements(bare), <String>[
        'risk_assessed',
        'minimal_change',
        'tests_added',
        'reviewed',
        'no_schema_break',
        'documented',
      ]);
    });

    test('blank issue_id is reported as issue_id', () {
      const noId = StabilizationChange(
        issueId: ' ',
        riskAssessment: 'low',
        minimalChange: true,
        tests: <String>['test/x_test.dart'],
        review: 'ok',
        noSchemaBreak: true,
        documentation: 'doc updated',
      );
      expect(log.missingRequirements(noId), <String>['issue_id']);
    });

    test('schema-breaking change fails no_schema_break when otherwise '
        'complete', () {
      const breaking = StabilizationChange(
        issueId: 'NB-203',
        riskAssessment: 'Risiko rendah menurut penilaian awal.',
        minimalChange: true,
        tests: <String>['test/features/example_test.dart'],
        review: 'ok',
        noSchemaBreak: false,
        documentation: 'catatan rilis diperbarui',
      );

      expect(log.missingRequirements(breaking), <String>['no_schema_break']);

      final evaluation = (StabilizationLog()..add(breaking)).evaluate();
      expect(evaluation.state, StabilizationState.fail);
      expect(evaluation.notes.join(' '), contains('NB-203'));
      expect(evaluation.notes.join(' '), contains('no_schema_break'));
    });

    test('empty log is blocked pending a stabilization attempt', () {
      final state = log.evaluate();
      expect(state.state, StabilizationState.blocked);
      expect(state.changeCount, 0);
      expect(state.notes.join(' '), isNotEmpty);
    });

    test('complete change passes and retains its documentation', () {
      final complete = StabilizationLog()
        ..add(
          const StabilizationChange(
            issueId: 'NB-204',
            riskAssessment:
                'Risiko rendah; perubahan terbatas pada copy pesan error.',
            minimalChange: true,
            tests: <String>['test/features/settings/settings_test.dart'],
            review: 'Self-review + gate analyzer/format/diff-check.',
            noSchemaBreak: true,
            documentation:
                'Recovery steps diperbarui di docs/guides/recovery.md.',
          ),
        );

      final state = complete.evaluate();
      expect(state.state, StabilizationState.pass);
      expect(state.changeCount, 1);
      expect(state.notes.join(' '), contains('docs/guides/recovery.md'));
    });

    test('incomplete change fails naming the issue and every missing '
        'requirement', () {
      final incomplete = StabilizationLog()
        ..add(
          const StabilizationChange(
            issueId: 'NB-205',
            riskAssessment: '',
            minimalChange: true,
            tests: <String>[],
            review: 'ok',
            noSchemaBreak: true,
            documentation: '',
          ),
        );

      final state = incomplete.evaluate();
      expect(state.state, StabilizationState.fail);
      final notes = state.notes.join(' ');
      expect(notes, contains('NB-205'));
      expect(notes, contains('risk_assessed'));
      expect(notes, contains('tests_added'));
      expect(notes, contains('documented'));
    });

    test('manifest records all six requirements with live status', () {
      final manifest =
          json.decode(
                File(
                  'docs/planning/v1.2/sprint_113_non_blocker_stabilization.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '113.32');
      final requirements = manifest['requirements'] as Map<String, dynamic>;
      expect(requirements.keys.toSet(), <String>{
        'risk_assessed',
        'minimal_change',
        'tests_added',
        'reviewed',
        'no_schema_break',
        'documented',
      });
      for (final value in requirements.values) {
        final entry = value as Map<String, dynamic>;
        expect(entry['description'], isNotEmpty);
        expect(entry['status'], isNotEmpty);
      }
      expect(manifest['limits'], isNotEmpty);
      expect(manifest['decision'], isNotEmpty);
    });
  });
}
