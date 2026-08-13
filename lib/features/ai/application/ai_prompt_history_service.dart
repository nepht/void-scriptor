import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../database/project/project_database.dart';

class AiPromptHistoryService {
  AiPromptHistoryService(this.database);
  final ProjectDatabase database;

  Future<String> savePrompt({
    required String projectId,
    required String target,
    required String prompt,
    String negativePrompt = '',
    String? sceneId,
    String? assetId,
    String? provider,
    String? model,
  }) async {
    final id = const Uuid().v4();
    await database
        .into(database.aiPromptHistory)
        .insert(
          AiPromptHistoryCompanion.insert(
            id: id,
            projectId: projectId,
            sceneId: Value(sceneId),
            assetId: Value(assetId),
            target: target,
            prompt: prompt,
            negativePrompt: Value(negativePrompt),
            provider: Value(provider),
            model: Value(model),
            createdAt: DateTime.now(),
          ),
        );
    return id;
  }

  Future<void> saveRevision({
    required String promptHistoryId,
    required String content,
    required int revision,
  }) => database
      .into(database.promptRevisions)
      .insert(
        PromptRevisionsCompanion.insert(
          id: const Uuid().v4(),
          promptHistoryId: promptHistoryId,
          revision: revision,
          content: content,
          createdAt: DateTime.now(),
        ),
      );
  Future<AiPromptHistoryData?> getHistory(String id) => (database.select(
    database.aiPromptHistory,
  )..where((row) => row.id.equals(id))).getSingleOrNull();
  Future<List<PromptRevision>> getRevisions(String historyId) =>
      (database.select(database.promptRevisions)
            ..where((row) => row.promptHistoryId.equals(historyId))
            ..orderBy([(row) => OrderingTerm(expression: row.revision)]))
          .get();
}
