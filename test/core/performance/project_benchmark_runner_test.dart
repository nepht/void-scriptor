import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/large_project_benchmark.dart';
import 'package:void_scriptor/core/performance/project_benchmark_runner.dart';

void main() {
  test(
    'benchmark runner seeds fixtures and times representative queries',
    () async {
      const profile = LargeProjectBenchmarkProfile(
        characters: 10,
        references: 200,
        generations: 50,
        scenes: 100,
        timelineClips: 1000,
      );
      final report = await ProjectBenchmarkRunner(profile: profile).run();

      expect(report.referenceCount, 200);
      expect(report.timelineClipCount, 1000);
      expect(report.referenceListMicros, greaterThanOrEqualTo(0));
      expect(report.timelineRangeMicros, greaterThanOrEqualTo(0));
      expect(report.totalMicros, greaterThanOrEqualTo(0));
    },
  );

  test('benchmark report totals timing across queries', () {
    const report = ProjectBenchmarkReport(
      referenceCount: 1,
      timelineClipCount: 1,
      referenceListMicros: 10,
      timelineRangeMicros: 20,
    );
    expect(report.totalMicros, 30);
  });
}
