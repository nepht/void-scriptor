import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/intent_definition_of_done.dart';

void main() {
  test('requires every intent verification category to pass', () {
    final report = IntentVerificationReport(
      results: {
        for (final category in IntentVerificationCategory.values)
          category: const VerificationResult.passed(),
      },
      commands: const ['flutter test test/features/intent', 'flutter analyze'],
    );

    expect(report.isComplete, isTrue);
    expect(report.missingCategories, isEmpty);
  });

  test('does not complete when a category is missing or failed', () {
    final report = IntentVerificationReport(
      results: const {
        IntentVerificationCategory.intent: VerificationResult.passed(),
        IntentVerificationCategory.multimodal: VerificationResult.failed(
          'not run',
        ),
      },
      commands: const ['flutter test test/features/intent'],
    );

    expect(report.isComplete, isFalse);
    expect(
      report.missingCategories,
      contains(IntentVerificationCategory.accessibility),
    );
    expect(
      report.failedCategories,
      contains(IntentVerificationCategory.multimodal),
    );
  });

  test('requires concrete commands as evidence', () {
    final report = IntentVerificationReport(
      results: {
        for (final category in IntentVerificationCategory.values)
          category: const VerificationResult.passed(),
      },
      commands: const [],
    );

    expect(report.isComplete, isFalse);
    expect(report.hasCommandEvidence, isFalse);
  });
}
