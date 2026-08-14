class LargeProjectBenchmarkProfile {
  const LargeProjectBenchmarkProfile({
    required this.characters,
    required this.references,
    required this.generations,
    required this.scenes,
    required this.timelineClips,
    this.isDevelopmentOnly = true,
  });

  const LargeProjectBenchmarkProfile.defaultProfile()
    : characters = 50,
      references = 2000,
      generations = 1000,
      scenes = 500,
      timelineClips = 10000,
      isDevelopmentOnly = true;

  final int characters;
  final int references;
  final int generations;
  final int scenes;
  final int timelineClips;
  final bool isDevelopmentOnly;

  LargeProjectBenchmarkDataset generate() => LargeProjectBenchmarkDataset(
    characters: characters,
    references: references,
    generations: generations,
    scenes: scenes,
    timelineClips: timelineClips,
  );
}

class LargeProjectBenchmarkDataset {
  const LargeProjectBenchmarkDataset({
    required this.characters,
    required this.references,
    required this.generations,
    required this.scenes,
    required this.timelineClips,
  });

  final int characters;
  final int references;
  final int generations;
  final int scenes;
  final int timelineClips;

  int get totalRecords =>
      characters + references + generations + scenes + timelineClips;
}
