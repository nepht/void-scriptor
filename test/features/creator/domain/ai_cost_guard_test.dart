import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/domain/ai_cost_guard.dart';

void main() {
  group('AiCostGuard', () {
    test('estimates cost before expensive work', () {
      final guard = AiCostGuard.defaults();
      final estimate = guard.estimate(
        generations: 8,
        gpuSeconds: 120,
        creditsPerGeneration: 2,
      );
      expect(estimate.generations, 8);
      expect(estimate.estimatedCredits, 16);
      expect(estimate.estimatedGpuSeconds, 120);
    });

    test('respects daily and project limits', () {
      final guard = AiCostGuard.defaults().copyWith(
        dailyLimit: 100,
        projectLimit: 500,
      );
      expect(
        guard.allows(estimatedCredits: 85, usedDaily: 10, usedProject: 400),
        isTrue,
      );
      expect(
        guard.allows(estimatedCredits: 101, usedDaily: 10, usedProject: 0),
        isFalse,
      );
      expect(
        guard.allows(estimatedCredits: 99, usedDaily: 0, usedProject: 490),
        isFalse,
      );
    });

    test('generation and gpu limits block overruns', () {
      final guard = AiCostGuard.defaults().copyWith(
        generationLimit: 50,
        gpuLimitSeconds: 600,
      );
      expect(
        guard.allows(estimatedCredits: 10, usedDaily: 0, usedProject: 0),
        isTrue,
      );
      expect(
        guard.allows(
          estimatedCredits: 10,
          usedDaily: 0,
          usedProject: 0,
          newGenerations: 51,
        ),
        isFalse,
      );
      expect(
        guard.allows(
          estimatedCredits: 10,
          usedDaily: 0,
          usedProject: 0,
          newGpuSeconds: 601,
        ),
        isFalse,
      );
      expect(guard.withGenerationCount(50).generationLimit, 50);
    });
  });
}
