import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/benchmark_dataset_seeder.dart';
import 'package:void_scriptor/core/performance/large_project_benchmark.dart';

void main() {
  test('seeds exactly the requested record counts', () {
    const profile = LargeProjectBenchmarkProfile(
      characters: 3,
      references: 5,
      generations: 2,
      scenes: 4,
      timelineClips: 7,
    );
    const seeder = BenchmarkDatasetSeeder(profile);

    final dataset = seeder.generate();

    expect(dataset.characters.length, 3);
    expect(dataset.references.length, 5);
    expect(dataset.generations.length, 2);
    expect(dataset.scenes.length, 4);
    expect(dataset.timelineClips.length, 7);
  });

  test('seeded records are deterministic for a fixed seed', () {
    const profile = LargeProjectBenchmarkProfile(
      characters: 2,
      references: 2,
      generations: 2,
      scenes: 2,
      timelineClips: 2,
    );
    final first = const BenchmarkDatasetSeeder(profile, seed: 42).generate();
    final second = const BenchmarkDatasetSeeder(profile, seed: 42).generate();

    expect(first.characters.first.name, second.characters.first.name);
    expect(first.references.first.title, second.references.first.title);
  });

  test('seeded records carry non-empty identifying fields', () {
    const profile = LargeProjectBenchmarkProfile(
      characters: 1,
      references: 1,
      generations: 1,
      scenes: 1,
      timelineClips: 1,
    );
    final dataset = const BenchmarkDatasetSeeder(profile, seed: 7).generate();

    expect(dataset.characters.single.name, isNotEmpty);
    expect(dataset.references.single.title, isNotEmpty);
    expect(dataset.generations.single.prompt, isNotEmpty);
    expect(dataset.scenes.single.title, isNotEmpty);
    expect(dataset.timelineClips.single.assetId, isNotEmpty);
  });

  test('default profile is development-only', () {
    expect(
      const LargeProjectBenchmarkProfile.defaultProfile().isDevelopmentOnly,
      isTrue,
    );
  });
}
