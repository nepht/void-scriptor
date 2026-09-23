/// Test for Release Blocker Resolution (Step 113.31).
/// Validates the six canonical required_outputs — fix_refs, root_cause,
/// tests, review, risk_update, release_note — and the blocked/fail/pass
/// state of the resolution log.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/release_blocker_resolution.dart';

void main() {
  final log = BlockerResolutionLog();

  group('113.31 Release Blocker Resolution', () {
    test('complete resolution carries all six canonical outputs', () {
      const resolution = BlockerResolution(
        issueId: 'ISS-401',
        fixRefs: <String>['f2f6fa2c5b4f28358e070e44b5bbf6958308a641'],
        rootCause: 'State submitting tidak dikunci sehingga dialog ganda.',
        tests: <String>[
          'test/release/sprint_113_feedback_collection_evidence_log_test.dart',
        ],
        review: 'Reviewer: cron self-review dua jalur (diff + gate).',
        riskUpdate:
            'Risiko turun; residual: native GUI/hosted CI tetap UNVERIFIABLE.',
        releaseNote:
            'Export tidak lagi membuka dialog ganda saat diklik dua kali.',
      );

      expect(BlockerResolution.requiredOutputNames, <String>[
        'fix_refs',
        'root_cause',
        'tests',
        'review',
        'risk_update',
        'release_note',
      ]);
      expect(log.missingOutputs(resolution), isEmpty);
    });

    test('missing outputs are reported by canonical name', () {
      const bare = BlockerResolution(
        issueId: 'ISS-402',
        fixRefs: <String>[],
        rootCause: '',
        tests: <String>[],
        review: '',
        riskUpdate: '',
        releaseNote: '',
      );

      expect(log.missingOutputs(bare), <String>[
        'fix_refs',
        'root_cause',
        'tests',
        'review',
        'risk_update',
        'release_note',
      ]);
    });

    test('blank issue_id is reported as issue_id', () {
      const noId = BlockerResolution(
        issueId: ' ',
        fixRefs: <String>['abc123'],
        rootCause: 'rc',
        tests: <String>['test/x_test.dart'],
        review: 'ok',
        riskUpdate: 'low',
        releaseNote: 'note',
      );
      expect(log.missingOutputs(noId), <String>['issue_id']);
    });

    test('empty log is blocked pending a resolution attempt', () {
      final state = log.evaluate();
      expect(state.state, BlockerResolutionState.blocked);
      expect(state.resolutionCount, 0);
      expect(state.notes.join(' '), isNotEmpty);
    });

    test('complete resolution passes and retains its release note', () {
      final complete = BlockerResolutionLog()
        ..add(
          const BlockerResolution(
            issueId: 'ISS-403',
            fixRefs: <String>['671d917e3d4d098d14ff44063369372e64265db6'],
            rootCause: 'Clamp negatif pada maxStart saat resize clip.',
            tests: <String>['test/features/timeline/timeline_clamp_test.dart'],
            review: 'Self-review + gate analyzer/format/diff-check.',
            riskUpdate: 'Risiko rendah; tidak menyentuh schema.',
            releaseNote: 'Resize clip tidak lagi melempar ArgumentError.',
          ),
        );

      final state = complete.evaluate();
      expect(state.state, BlockerResolutionState.pass);
      expect(state.resolutionCount, 1);
      expect(state.notes.join(' '), contains('ArgumentError'));
    });

    test('incomplete resolution fails naming every missing output', () {
      final incomplete = BlockerResolutionLog()
        ..add(
          const BlockerResolution(
            issueId: 'ISS-404',
            fixRefs: <String>['deadbeef'],
            rootCause: '',
            tests: <String>[],
            review: 'ok',
            riskUpdate: '',
            releaseNote: '',
          ),
        );

      final state = incomplete.evaluate();
      expect(state.state, BlockerResolutionState.fail);
      final notes = state.notes.join(' ');
      expect(notes, contains('ISS-404'));
      expect(notes, contains('root_cause'));
      expect(notes, contains('tests'));
      expect(notes, contains('risk_update'));
      expect(notes, contains('release_note'));
    });

    test('manifest records all six required outputs with live status', () {
      final manifest =
          json.decode(
                File(
                  'docs/planning/v1.2/sprint_113_release_blocker_resolution.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '113.31');
      final outputs = manifest['required_outputs'] as Map<String, dynamic>;
      expect(outputs.keys.toSet(), <String>{
        'fix_refs',
        'root_cause',
        'tests',
        'review',
        'risk_update',
        'release_note',
      });
      for (final value in outputs.values) {
        final entry = value as Map<String, dynamic>;
        expect(entry['description'], isNotEmpty);
        expect(entry['status'], isNotEmpty);
      }
      expect(manifest['limits'], isNotEmpty);
      expect(manifest['decision'], isNotEmpty);
    });
  });
}
