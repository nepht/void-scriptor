import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../database/project/project_database.dart';

/// Records token usage and cost per generation (Step 28.6).
class AiUsageLogRepository {
  AiUsageLogRepository(this.database);

  final ProjectDatabase database;

  Future<void> log({
    required String generationId,
    required String provider,
    required String model,
    required int promptTokens,
    required int completionTokens,
    required double cost,
  }) => database
      .into(database.aiUsageLogs)
      .insert(
        AiUsageLogsCompanion.insert(
          id: const Uuid().v4(),
          generationId: generationId,
          provider: provider,
          model: model,
          promptTokens: promptTokens,
          completionTokens: completionTokens,
          cost: cost,
          createdAt: DateTime.now(),
        ),
      );

  Future<List<AiUsageLog>> forProject(String projectId) async {
    // Usage logs are keyed by generation; resolve generations for the project.
    final jobs = await (database.select(
      database.aiGenerationJobs,
    )..where((row) => row.projectId.equals(projectId))).get();
    final ids = jobs.map((job) => job.id).toList(growable: false);
    if (ids.isEmpty) return const [];
    final query = database.select(database.aiUsageLogs)
      ..where((row) => row.generationId.isIn(ids))
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]);
    return query.get();
  }

  Future<double> totalCostForProject(String projectId) async {
    final logs = await forProject(projectId);
    var total = 0.0;
    for (final log in logs) {
      total += log.cost;
    }
    return total;
  }
}
