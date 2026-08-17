import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/domain/reputation_dimension.dart';

void main() {
  group('ReputationDimension', () {
    test('exposes the six canonical reputation dimensions', () {
      expect(ReputationDimension.values.map((e) => e.name), [
        'quality',
        'reliability',
        'collaboration',
        'contribution',
        'originality',
        'communityTrust',
      ]);
    });

    test('aggregates into a total reputation score', () {
      const score = ReputationScore(
        quality: 4,
        reliability: 5,
        collaboration: 3,
        contribution: 4,
        originality: 5,
        communityTrust: 4,
      );
      expect(score.average, closeTo(4.17, 0.01));
    });
  });
}
