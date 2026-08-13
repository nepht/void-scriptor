import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/ai/application/ai_prompt_history_service.dart';

void main() {
  test('prompt history and revisions survive restart', () async {
    final root = await Directory.systemTemp.createTemp('s17-ai-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final dbPath = (await paths.database('p1')).path;
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final first = await service.open(dbPath);
    final history = AiPromptHistoryService(first);
    final id = await history.savePrompt(
      projectId: 'p1',
      target: 'video',
      prompt: 'MASTER PROMPT',
      negativePrompt: 'bad face',
      sceneId: 's1',
    );
    await history.saveRevision(
      promptHistoryId: id,
      content: 'MASTER PROMPT edited',
      revision: 2,
    );
    await first.close();
    final second = await service.open(dbPath);
    addTearDown(second.close);
    final restored = AiPromptHistoryService(second);
    expect((await restored.getHistory(id))?.prompt, 'MASTER PROMPT');
    expect(
      (await restored.getRevisions(id)).single.content,
      'MASTER PROMPT edited',
    );
    expect(second.schemaVersion, 13);
  });
}
