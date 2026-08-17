/// Sprint 43 — Step 43.14 AI Cost Guard.
///
/// Guards expensive AI work with estimates and user-defined limits:
/// daily AI limit, project AI limit, generation limit, GPU limit.
class AiCostGuard {
  const AiCostGuard({
    required this.dailyLimit,
    required this.projectLimit,
    required this.generationLimit,
    required this.gpuLimitSeconds,
  });

  factory AiCostGuard.defaults() => const AiCostGuard(
    dailyLimit: 100,
    projectLimit: 500,
    generationLimit: 1000,
    gpuLimitSeconds: 3600,
  );

  final int dailyLimit;
  final int projectLimit;
  final int generationLimit;
  final int gpuLimitSeconds;

  AiCostEstimate estimate({
    required int generations,
    required int gpuSeconds,
    required double creditsPerGeneration,
  }) {
    return AiCostEstimate(
      generations: generations,
      gpuSeconds: gpuSeconds,
      estimatedCredits: (generations * creditsPerGeneration).round(),
    );
  }

  bool allows({
    required int estimatedCredits,
    required int usedDaily,
    required int usedProject,
    int newGenerations = 0,
    int newGpuSeconds = 0,
  }) {
    if (usedDaily + estimatedCredits > dailyLimit) return false;
    if (usedProject + estimatedCredits > projectLimit) return false;
    if (newGenerations > generationLimit) return false;
    if (newGpuSeconds > gpuLimitSeconds) return false;
    return true;
  }

  AiCostGuard copyWith({
    int? dailyLimit,
    int? projectLimit,
    int? generationLimit,
    int? gpuLimitSeconds,
  }) {
    return AiCostGuard(
      dailyLimit: dailyLimit ?? this.dailyLimit,
      projectLimit: projectLimit ?? this.projectLimit,
      generationLimit: generationLimit ?? this.generationLimit,
      gpuLimitSeconds: gpuLimitSeconds ?? this.gpuLimitSeconds,
    );
  }

  AiCostGuard withGenerationCount(int count) =>
      copyWith(generationLimit: count);
}

class AiCostEstimate {
  const AiCostEstimate({
    required this.generations,
    required this.gpuSeconds,
    required this.estimatedCredits,
  });

  final int generations;
  final int gpuSeconds;
  final int estimatedCredits;

  int get estimatedGpuSeconds => gpuSeconds;
}
