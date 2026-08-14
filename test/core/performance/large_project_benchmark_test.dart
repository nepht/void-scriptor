import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/large_project_benchmark.dart';

void main() {
  test('benchmark profile creates deterministic large-project counts', () {
    const profile = LargeProjectBenchmarkProfile.defaultProfile();
    final dataset = profile.generate();

    expect(dataset.characters, 50);
    expect(dataset.references, 2000);
    expect(dataset.generations, 1000);
    expect(dataset.scenes, 500);
    expect(dataset.timelineClips, 10000);
    expect(dataset.totalRecords, greaterThan(13000));
  });

  test('benchmark generator does not expose production UI seed action', () {
    const profile = LargeProjectBenchmarkProfile.defaultProfile();
    expect(profile.isDevelopmentOnly, isTrue);
  });
}
