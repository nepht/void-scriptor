enum BackgroundJobStatus { queued, running, completed, failed, cancelled }

enum BackgroundJobPriority { low, normal, high, critical }

enum BackgroundJobType {
  thumbnail,
  waveform,
  searchIndex,
  fileHash,
  integrityScan,
  cacheRebuild,
  import,
  export,
  backup,
  generationDownload,
  custom,
}

enum JobPersistence { transient, persistent }

enum JobResource { cpu, disk, network, gpu, database }

class BackgroundJob {
  const BackgroundJob({
    required this.id,
    required this.projectId,
    required this.type,
    required this.label,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.progress = 0,
    this.error,
    this.persistence = JobPersistence.transient,
  }) : assert(progress >= 0 && progress <= 1);

  final String id;
  final String projectId;
  final BackgroundJobType type;
  final String label;
  final BackgroundJobStatus status;
  final BackgroundJobPriority priority;
  final double progress;
  final DateTime createdAt;
  final String? error;
  final JobPersistence persistence;

  BackgroundJob copyWith({
    BackgroundJobStatus? status,
    double? progress,
    String? error,
    bool clearError = false,
  }) => BackgroundJob(
    id: id,
    projectId: projectId,
    type: type,
    label: label,
    status: status ?? this.status,
    priority: priority,
    createdAt: createdAt,
    progress: progress ?? this.progress,
    error: clearError ? null : error ?? this.error,
    persistence: persistence,
  );
}

int priorityWeight(BackgroundJobPriority priority) => switch (priority) {
  BackgroundJobPriority.critical => 4,
  BackgroundJobPriority.high => 3,
  BackgroundJobPriority.normal => 2,
  BackgroundJobPriority.low => 1,
};

class JobContext {
  const JobContext({required this.reportProgress, required this.isCancelled});

  final void Function(double progress) reportProgress;
  final bool Function() isCancelled;
}

abstract interface class BackgroundTask {
  String get id;
  BackgroundJob get job;
  BackgroundJobType get type;
  String? get taskKey;
  Set<JobResource> get resources;

  Future<void> execute(JobContext context);
  Future<void> cancel();
}
