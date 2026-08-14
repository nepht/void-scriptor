enum GenerationJobStatus {
  queued,
  preparing,
  running,
  completed,
  failed,
  cancelled,
}

enum GenerationPriority { low, normal, high }

enum AiErrorType {
  authentication,
  rateLimit,
  network,
  timeout,
  unsupportedCapability,
  invalidRequest,
  provider,
  cancelled,
  unknown,
}

class GenerationJob {
  const GenerationJob({
    required this.id,
    required this.projectId,
    required this.providerId,
    required this.promptHistoryId,
    required this.status,
    required this.createdAt,
    this.modelId,
    this.progress = 0,
    this.error,
    this.priority = GenerationPriority.normal,
  });
  final String id;
  final String projectId;
  final String providerId;
  final String? modelId;
  final String promptHistoryId;
  final GenerationJobStatus status;
  final double progress;
  final String? error;
  final DateTime createdAt;
  final GenerationPriority priority;

  GenerationJob copyWith({
    GenerationJobStatus? status,
    double? progress,
    String? error,
    bool clearError = false,
  }) => GenerationJob(
    id: id,
    projectId: projectId,
    providerId: providerId,
    promptHistoryId: promptHistoryId,
    status: status ?? this.status,
    createdAt: createdAt,
    modelId: modelId,
    progress: progress ?? this.progress,
    error: clearError ? null : error ?? this.error,
    priority: priority,
  );
}

class RetryPolicy {
  const RetryPolicy({this.maxAttempts = 3});
  final int maxAttempts;
  bool shouldRetry(AiErrorType type, int attempt) {
    if (attempt >= maxAttempts) return false;
    return switch (type) {
      AiErrorType.network ||
      AiErrorType.timeout ||
      AiErrorType.rateLimit ||
      AiErrorType.provider => true,
      _ => false,
    };
  }
}
