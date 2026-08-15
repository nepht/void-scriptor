import 'dart:math' as math;

import 'large_project_benchmark.dart';

class BenchmarkCharacter {
  const BenchmarkCharacter({required this.name});
  final String name;
}

class BenchmarkReference {
  const BenchmarkReference({required this.title});
  final String title;
}

class BenchmarkGeneration {
  const BenchmarkGeneration({required this.prompt});
  final String prompt;
}

class BenchmarkScene {
  const BenchmarkScene({required this.title});
  final String title;
}

class BenchmarkTimelineClip {
  const BenchmarkTimelineClip({required this.assetId});
  final String assetId;
}

class SeededBenchmarkDataset {
  const SeededBenchmarkDataset({
    required this.characters,
    required this.references,
    required this.generations,
    required this.scenes,
    required this.timelineClips,
  });

  final List<BenchmarkCharacter> characters;
  final List<BenchmarkReference> references;
  final List<BenchmarkGeneration> generations;
  final List<BenchmarkScene> scenes;
  final List<BenchmarkTimelineClip> timelineClips;

  int get totalRecords =>
      characters.length +
      references.length +
      generations.length +
      scenes.length +
      timelineClips.length;
}

/// Benchmark dataset seed generator (Steps 26.82–26.85).
///
/// Generates actual records so large-project benchmarks exercise the same
/// database/index/search paths a real project would. It is development-only:
/// it lives in `core/performance` and is never referenced from production UI.
class BenchmarkDatasetSeeder {
  const BenchmarkDatasetSeeder(this.profile, {this.seed = 0});

  final LargeProjectBenchmarkProfile profile;
  final int seed;

  SeededBenchmarkDataset generate() {
    final random = math.Random(seed);
    return SeededBenchmarkDataset(
      characters: List.generate(
        profile.characters,
        (i) => BenchmarkCharacter(name: 'Character ${i + 1}'),
      ),
      references: List.generate(
        profile.references,
        (i) => BenchmarkReference(title: 'Reference ${i + 1}'),
      ),
      generations: List.generate(
        profile.generations,
        (i) =>
            BenchmarkGeneration(prompt: 'Benchmark prompt ${i + 1} seed $seed'),
      ),
      scenes: List.generate(
        profile.scenes,
        (i) => BenchmarkScene(title: 'Scene ${i + 1}'),
      ),
      timelineClips: List.generate(
        profile.timelineClips,
        (i) => BenchmarkTimelineClip(
          assetId: 'clip-${random.nextInt(1 << 31)}-$i',
        ),
      ),
    );
  }
}
