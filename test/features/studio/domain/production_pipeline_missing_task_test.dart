// Regression lock for vs-hunt-20260913-studio STU-BUG-01 (Referee: Medium).
// Claim: ProductionBreakdown.isBlocked/complete use firstWhere without
// orElse, so querying a non-existent task id throws a raw StateError that
// leaks an implementation-detail exception type through a public domain API.
// Contract: every unknown-id lookup throws the typed UnknownProductionTaskException.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/studio/domain/production_pipeline.dart';

void main() {
  group('STU-BUG-01 typed lookup failures on unknown ids', () {
    test('isBlocked with an unknown task id throws the typed exception', () {
      final breakdown = ProductionBreakdown('Create episode');
      breakdown.addTask('Write', mode: DelegationMode.human);

      expect(
        () => breakdown.isBlocked('task-does-not-exist'),
        throwsA(isA<UnknownProductionTaskException>()),
      );
    });

    test('complete with an unknown task id throws the typed exception', () {
      final breakdown = ProductionBreakdown('Create episode');

      expect(
        () => breakdown.complete('task-does-not-exist'),
        throwsA(isA<UnknownProductionTaskException>()),
      );
    });

    test('isBlocked with a dangling dependency id throws the typed exception '
        'naming the missing dependency', () {
      final breakdown = ProductionBreakdown('Create episode');
      breakdown.addTask('Review', dependsOn: 'task-missing-dependency');

      Object? error;
      try {
        breakdown.isBlocked('task-0');
      } catch (e) {
        error = e;
      }
      expect(error, isA<UnknownProductionTaskException>());
      expect(
        (error as UnknownProductionTaskException).taskId,
        'task-missing-dependency',
      );
    });

    test('the typed exception is an Exception, not a raw StateError', () {
      final breakdown = ProductionBreakdown('Create episode');

      Object? error;
      try {
        breakdown.complete('task-does-not-exist');
      } catch (e) {
        error = e;
      }
      expect(error, isNotNull);
      expect(error, isA<Exception>());
      expect(error, isNot(isA<StateError>()));
    });
  });

  group('healthy paths stay green (intent preserved)', () {
    test('valid dependency ordering is unchanged', () {
      final director = ProductionDirector();
      final breakdown = director.breakdown('Create episode');
      final first = breakdown.addTask('Write', mode: DelegationMode.human);
      final second = breakdown.addTask('Review', dependsOn: first.id);
      expect(breakdown.isBlocked(second.id), isTrue);
      breakdown.complete(first.id);
      expect(breakdown.isBlocked(second.id), isFalse);
      expect(breakdown.isBlocked(first.id), isFalse);
    });
  });
}
