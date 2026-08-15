import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/application/token_estimator.dart';

void main() {
  const estimator = TokenEstimator();

  test('empty text has zero tokens', () {
    expect(estimator.estimate(''), 0);
  });

  test('estimates by char/4 heuristic', () {
    // 16 characters => 4 tokens
    expect(estimator.estimate('1234567890123456'), 4);
  });

  test('never returns zero for non-empty text', () {
    expect(estimator.estimate('a'), 1);
    expect(estimator.estimate('abc'), 1);
  });

  test('model-specific factor scales the estimate', () {
    final heavy = TokenEstimator(charsPerToken: 2);
    expect(heavy.estimate('12345678'), 4);
  });
}
