import 'package:drift/drift.dart';
import '../../../database/project/project_database.dart';
import '../domain/generation_job.dart';

class GenerationRepository {
  GenerationRepository(this.database);
  final ProjectDatabase database;

  Future<void> updateStatus(
    String id,
    GenerationJobStatus status, {
    String? error,
    double? progress,
  }) =>
      (database.update(
        database.aiGenerationJobs,
      )..where((row) => row.id.equals(id))).write(
        AiGenerationJobsCompanion(
          status: Value(status.name),
          error: Value(error),
          progress: progress == null ? const Value.absent() : Value(progress),
          startedAt: status == GenerationJobStatus.running
              ? Value(DateTime.now())
              : const Value.absent(),
          completedAt:
              status == GenerationJobStatus.completed ||
                  status == GenerationJobStatus.failed ||
                  status == GenerationJobStatus.cancelled
              ? Value(DateTime.now())
              : const Value.absent(),
        ),
      );

  Future<void> saveJob(GenerationJob job) => database
      .into(database.aiGenerationJobs)
      .insertOnConflictUpdate(
        AiGenerationJobsCompanion.insert(
          id: job.id,
          projectId: job.projectId,
          providerId: job.providerId,
          modelId: Value(job.modelId),
          promptHistoryId: job.promptHistoryId,
          status: job.status.name,
          progress: Value(job.progress),
          error: Value(job.error),
          priority: Value(job.priority.index),
          createdAt: job.createdAt,
        ),
      );

  Future<GenerationJob?> getJob(String id) async {
    final row = await (database.select(
      database.aiGenerationJobs,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return GenerationJob(
      id: row.id,
      projectId: row.projectId,
      providerId: row.providerId,
      modelId: row.modelId,
      promptHistoryId: row.promptHistoryId,
      status: GenerationJobStatus.values.byName(row.status),
      progress: row.progress,
      error: row.error,
      priority: GenerationPriority
          .values[row.priority.clamp(0, GenerationPriority.values.length - 1)],
      createdAt: row.createdAt,
    );
  }

  Future<void> saveOutput({
    required String jobId,
    required String outputId,
    required String outputType,
    String? localPath,
    String? remoteUrl,
    String? mimeType,
    int sortOrder = 0,
  }) => database
      .into(database.aiGenerationOutputs)
      .insertOnConflictUpdate(
        AiGenerationOutputsCompanion.insert(
          id: outputId,
          jobId: jobId,
          outputType: outputType,
          localPath: Value(localPath),
          remoteUrl: Value(remoteUrl),
          mimeType: Value(mimeType),
          sortOrder: Value(sortOrder),
        ),
      );
  Future<List<AiGenerationOutput>> getOutputs(String jobId) =>
      (database.select(database.aiGenerationOutputs)
            ..where((t) => t.jobId.equals(jobId))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();

  Future<AiGenerationOutput?> getOutput(String outputId) => (database.select(
    database.aiGenerationOutputs,
  )..where((row) => row.id.equals(outputId))).getSingleOrNull();

  Future<List<AiGenerationOutput>> getProjectOutputs(String projectId) async {
    final jobs = await (database.select(
      database.aiGenerationJobs,
    )..where((row) => row.projectId.equals(projectId))).get();
    final result = <AiGenerationOutput>[];
    for (final job in jobs) {
      result.addAll(await getOutputs(job.id));
    }
    return result;
  }

  Future<void> saveInput({
    required String jobId,
    required String inputId,
    required String inputType,
    String? sourceId,
    String? filePath,
    String? snapshotData,
    int sortOrder = 0,
  }) => database
      .into(database.aiGenerationInputs)
      .insertOnConflictUpdate(
        AiGenerationInputsCompanion.insert(
          id: inputId,
          jobId: jobId,
          inputType: inputType,
          sourceId: Value(sourceId),
          filePath: Value(filePath),
          snapshotData: Value(snapshotData),
          sortOrder: Value(sortOrder),
        ),
      );
  Future<List<AiGenerationInput>> getInputs(String jobId) =>
      (database.select(database.aiGenerationInputs)
            ..where((t) => t.jobId.equals(jobId))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();
}
