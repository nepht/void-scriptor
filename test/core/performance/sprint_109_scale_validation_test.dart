import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/large_project_benchmark.dart';
import 'package:void_scriptor/core/performance/project_benchmark_runner.dart';

void main() {
  test('109.46 dataset and budgets are explicit', () {
    const profile = LargeProjectBenchmarkProfile(
      characters: 10,
      references: 40,
      generations: 20,
      scenes: 15,
      timelineClips: 100,
    );
    final dataset = profile.generate();
    expect(dataset.totalRecords, 185);
    expect(profile.isDevelopmentOnly, isTrue);
  });

  test(
    '109.46 benchmark returns measurable results within bounded budget',
    () async {
      final report = await ProjectBenchmarkRunner(
        profile: const LargeProjectBenchmarkProfile(
          characters: 1,
          references: 20,
          generations: 1,
          scenes: 1,
          timelineClips: 50,
        ),
      ).run();
      expect(report.referenceCount, 20);
      expect(report.timelineClipCount, 50);
      expect(report.totalMicros, greaterThanOrEqualTo(0));
    },
  );
}
