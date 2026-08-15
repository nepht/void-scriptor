import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/application/context_budgeter.dart';

void main() {
  const budgeter = ContextBudgeter();

  test('returns full context when under budget', () {
    final result = budgeter.budget(
      sections: const {'canon': 'canon text', 'identity': 'identity text'},
      maxTokens: 1000,
    );
    expect(result.truncated, isFalse);
    expect(result.keptSections.keys, {'canon', 'identity'});
  });

  test('truncates lowest priority first when over budget', () {
    final result = budgeter.budget(
      sections: const {
        'canon': 'AAAA', // highest priority
        'identity': 'BBBB',
        'environment': 'CCCC',
      },
      maxTokens: 2, // only ~2 tokens fit
    );
    // canon always kept; lower priority dropped first
    expect(result.keptSections.containsKey('canon'), isTrue);
    expect(result.truncated, isTrue);
  });

  test('priority order matches canonical ordering', () {
    expect(ContextBudgeter.priorityOrder, [
      'canon',
      'preservation',
      'identity',
      'environment',
      'sceneAssets',
    ]);
  });
}
