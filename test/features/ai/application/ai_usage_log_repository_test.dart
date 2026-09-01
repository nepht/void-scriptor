import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/ai/application/ai_usage_log_repository.dart';

void main() {
  late ProjectDatabase db;
  late AiUsageLogRepository repository;

  setUp(() {
    db = ProjectDatabase(NativeDatabase.memory());
    repository = AiUsageLogRepository(db);
  });

  tearDown(() async => db.close());

  test('logs usage and totals cost per project', () async {
    // Seed a generation job for the project.
    await db
        .into(db.aiGenerationJobs)
        .insert(
          AiGenerationJobsCompanion.insert(
            id: 'gen-1',
            projectId: 'proj-1',
            providerId: 'openai',
            promptHistoryId: 'ph-1',
            status: 'completed',
            progress: const Value(1),
            priority: const Value(0),
            createdAt: DateTime.now(),
          ),
        );

    await repository.log(
      generationId: 'gen-1',
      provider: 'openai',
      model: 'gpt-4',
      promptTokens: 100,
      completionTokens: 50,
      cost: 0.25,
    );
    await repository.log(
      generationId: 'gen-1',
      provider: 'openai',
      model: 'gpt-4',
      promptTokens: 10,
      completionTokens: 5,
      cost: 0.05,
    );

    final logs = await repository.forProject('proj-1');
    expect(logs, hasLength(2));
    expect(
      await repository.totalCostForProject('proj-1'),
      closeTo(0.30, 0.001),
    );
  });

  test('schema version is 57', () {
    expect(ProjectDatabase.currentSchemaVersion, 58);
  });
}
