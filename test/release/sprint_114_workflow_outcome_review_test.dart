/// Test for Workflow Outcome Review (Step 114.23).
///
/// Validates the seven canonical dimensions — completion, failure, recovery,
/// abandonment, workaround, repeat_use, limitations — the blocked/fail/pass
/// state of the review report, the five-workflow coverage contract (writer,
/// lore, simulation, sharing, publishing), the three cross-dimension honesty
/// rules, and the step manifest.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/workflow_outcome_review.dart';

const String _manifestPath =
    'docs/planning/v1.2/sprint_114_workflow_outcome_review.json';

WorkflowOutcomeEntry _entry(
  String workflow, {
  bool? completion = true,
  bool? failure = false,
  String? recovery = 'not_applicable',
  bool? abandonment = false,
  bool? workaround = false,
  bool? repeatUse = true,
  List<String>? limitations,
}) {
  return WorkflowOutcomeEntry(
    workflow: workflow,
    completion: completion,
    failure: failure,
    recovery: recovery,
    abandonment: abandonment,
    workaround: workaround,
    repeatUse: repeatUse,
    limitations: limitations ?? <String>[],
  );
}

List<WorkflowOutcomeEntry> _fullSet() {
  return <WorkflowOutcomeEntry>[
    for (final id in WorkflowOutcomeReview.expectedWorkflows)
      _entry(id, workaround: false),
  ];
}

void main() {
  group('114.23 Workflow Outcome Review', () {
    test('seven canonical dimensions in contract order', () {
      expect(WorkflowOutcomeEntry.requiredDimensions, <String>[
        'completion',
        'failure',
        'recovery',
        'abandonment',
        'workaround',
        'repeat_use',
        'limitations',
      ]);
    });

    test('five canonical workflows in contract order', () {
      expect(WorkflowOutcomeReview.expectedWorkflows, <String>[
        'writer',
        'lore',
        'simulation',
        'sharing',
        'publishing',
      ]);
    });

    test('absent entries are blocked without outcome claims', () {
      final report = WorkflowOutcomeReview().evaluate(null);

      expect(report.state, WorkflowOutcomeState.blocked);
      expect(report.entries, isEmpty);
      expect(report.workflowCount, 0);
      expect(report.missingDimensions, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes.join(' '), contains('DEFERRED-EXTERNAL'));
    });

    test('complete entry has no missing dimension', () {
      final review = WorkflowOutcomeReview();
      expect(review.missingDimensions(_entry('writer')), isEmpty);
    });

    test('blank and absent dimensions are reported by canonical name', () {
      const bare = WorkflowOutcomeEntry(
        workflow: '',
        completion: null,
        failure: null,
        recovery: null,
        abandonment: null,
        workaround: null,
        repeatUse: null,
        limitations: null,
      );
      expect(WorkflowOutcomeReview().missingDimensions(bare), <String>[
        'workflow',
        'completion',
        'failure',
        'recovery',
        'abandonment',
        'workaround',
        'repeat_use',
        'limitations',
      ]);
    });

    test('empty limitations is a recorded answer, absent field is missing', () {
      final review = WorkflowOutcomeReview();
      expect(review.missingDimensions(_entry('lore')), isEmpty);
      const withoutField = WorkflowOutcomeEntry(
        workflow: 'lore',
        completion: true,
        failure: false,
        recovery: 'not_applicable',
        abandonment: false,
        workaround: false,
        repeatUse: true,
        limitations: null,
      );
      expect(review.missingDimensions(withoutField), <String>['limitations']);
    });

    test('coverage incomplete fails naming the missing workflows', () {
      final report = WorkflowOutcomeReview().evaluate(<WorkflowOutcomeEntry>[
        _entry('writer'),
        _entry('lore'),
      ]);
      expect(report.state, WorkflowOutcomeState.fail);
      expect(report.violations.join(' '), contains('coverage incomplete'));
      expect(report.violations.join(' '), contains('missing simulation'));
    });

    test('duplicate workflow entry fails', () {
      final entries = _fullSet();
      entries[1] = _entry('writer', workaround: false);
      final report = WorkflowOutcomeReview().evaluate(entries);
      expect(report.state, WorkflowOutcomeState.fail);
      expect(
        report.violations.join(' '),
        contains('duplicate workflow: writer'),
      );
    });

    test('unexpected workflow entry is rejected', () {
      final report = WorkflowOutcomeReview().evaluate(<WorkflowOutcomeEntry>[
        ..._fullSet(),
        _entry('metaverse'),
      ]);
      expect(report.state, WorkflowOutcomeState.fail);
      expect(
        report.violations.join(' '),
        contains('unexpected workflow: metaverse'),
      );
    });

    test('failure without recovered state fails unrecovered rule', () {
      final entries = _fullSet();
      entries[0] = _entry(
        'writer',
        completion: false,
        failure: true,
        recovery: 'failed',
        workaround: true,
        repeatUse: false,
      );
      final report = WorkflowOutcomeReview().evaluate(entries);
      expect(report.state, WorkflowOutcomeState.fail);
      expect(report.violations, contains('unrecovered_failure: writer'));
    });

    test('failure with recovered state passes without penalty', () {
      final entries = _fullSet();
      entries[0] = _entry(
        'writer',
        failure: true,
        recovery: 'ok',
        workaround: true,
      );
      final report = WorkflowOutcomeReview().evaluate(entries);
      expect(report.state, WorkflowOutcomeState.pass);
      expect(report.violations, isEmpty);
    });

    test('incomplete workflow without failure or abandonment fails', () {
      final entries = _fullSet();
      entries[1] = _entry('lore', completion: false, repeatUse: false);
      final report = WorkflowOutcomeReview().evaluate(entries);
      expect(report.state, WorkflowOutcomeState.fail);
      expect(report.violations, contains('incomplete_without_cause: lore'));
    });

    test('repeat use claimed on an incomplete workflow fails', () {
      final entries = _fullSet();
      entries[2] = _entry(
        'simulation',
        completion: false,
        failure: true,
        recovery: 'ok',
        repeatUse: true,
      );
      final report = WorkflowOutcomeReview().evaluate(entries);
      expect(report.state, WorkflowOutcomeState.fail);
      expect(
        report.violations,
        contains('repeat_use_without_completion: simulation'),
      );
    });

    test('full five-workflow review passes and retains every answer', () {
      final report = WorkflowOutcomeReview().evaluate(_fullSet());
      expect(report.state, WorkflowOutcomeState.pass);
      expect(report.workflowCount, 5);
      expect(report.missingDimensions, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes.join(' '), contains('DEFERRED-EXTERNAL'));
      expect(
        report.entries.every((e) => e.limitations != null),
        isTrue,
        reason: 'every workflow records its limitations answer',
      );
    });

    test('manifest declares canonical dimensions, rules, and deferrals', () {
      final file = File(_manifestPath);
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.23');
      expect(document['dimensions'], <dynamic>[
        'completion',
        'failure',
        'recovery',
        'abandonment',
        'workaround',
        'repeat_use',
        'limitations',
      ]);
      expect(document['workflows'], <dynamic>[
        'writer',
        'lore',
        'simulation',
        'sharing',
        'publishing',
      ]);
      expect(document['violations'], <dynamic>[
        'unrecovered_failure',
        'incomplete_without_cause',
        'repeat_use_without_completion',
      ]);
      expect(document['native_workflow_execution'], 'DEFERRED-EXTERNAL');
      expect(document['end_user_validation'], 'DEFERRED-EXTERNAL');
      expect(document['public_distribution_gates'], 'DEFERRED-EXTERNAL');
      expect(document['limitations'], isA<List<dynamic>>());
      expect((document['limitations'] as List<dynamic>), isNotEmpty);
    });
  });
}
