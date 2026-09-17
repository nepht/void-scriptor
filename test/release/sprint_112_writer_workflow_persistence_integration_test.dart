import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/persisted_writer_workflow.dart';
import 'package:void_scriptor/features/story/domain/end_to_end_writer_workflow.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/domain/draft_snapshots.dart';
import 'package:void_scriptor/features/spoiler/domain/reader_redaction.dart';
import 'package:void_scriptor/features/spoiler/domain/spoiler_classification.dart';
import 'package:void_scriptor/features/world_logic/domain/spoiler_safe_manuscript_knowledge_export.dart';

void main() {
  test(
    '112.32 persists the writer workflow through a database restart',
    () async {
      final root = await Directory.systemTemp.createTemp('s112-writer-db-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final service = ProjectDatabaseService();
      final dbPath = (await paths.database('project-1')).path;
      await service.create(dbPath);
      final database = await service.open(dbPath);
      final storyService = CreateStoryService(database: database, paths: paths);
      final storyId = await storyService.createStory(
        projectId: 'project-1',
        title: 'Persisted Writer',
      );
      final chapterId = await storyService.createChapter(
        storyId: storyId,
        title: 'Bab Satu',
        chapterNumber: 1,
      );
      final sceneId = await storyService.createScene(
        storyId: storyId,
        chapterId: chapterId,
        title: 'Adegan Pembuka',
        sceneNumber: 1,
      );
      final repository = StoryRepositoryImpl(
        database: database,
        projectId: 'project-1',
      );
      final registry = SpoilerRegistry()
        ..addAudience(const SpoilerAudience('beta', SpoilerLevel.clean));
      final workflow = PersistedWriterWorkflow(
        repository: repository,
        workflow: EndToEndWriterWorkflow(
          snapshots: DraftSnapshotStore(
            clock: () => DateTime.utc(2026, 9, 18, 3),
          ),
          exportService: SpoilerSafeExportService(
            redactor: ReaderRedactor(registry: registry)
              ..grant(readerId: 'reader', audience: 'beta'),
          ),
        ),
      );

      final result = await workflow.run(
        sceneId: sceneId,
        plan: 'Rencanakan pembukaan.',
        initialDraft: 'Pembukaan [[Menara]].',
        revision: 'Revisi [[Menara]] yang lebih tajam.',
        exportRequest: const SpoilerSafeExportRequest(
          documentId: 'story-1',
          title: 'Persisted Writer',
          readerId: 'reader',
          currentScene: 'scene-1',
          format: ExportFormat.plainText,
          sections: [
            ExportSection(
              id: 'scene-1',
              title: 'Adegan',
              text: 'Clean export.',
            ),
          ],
        ),
      );

      expect(result.workflow.exportedContent, contains('Clean export.'));
      expect(result.initialSnapshotId, isNotEmpty);
      expect(await repository.getSceneDraft(sceneId), result.revision);
      await database.close();

      final reopened = await service.open(dbPath);
      addTearDown(reopened.close);
      final reopenedRepository = StoryRepositoryImpl(
        database: reopened,
        projectId: 'project-1',
      );
      expect(await reopenedRepository.getSceneDraft(sceneId), result.revision);
      final snapshots = await reopenedRepository.getSceneDraftSnapshots(
        sceneId,
      );
      expect(snapshots.map((snapshot) => snapshot.kind), contains('manual'));

      final restored = await reopenedRepository.restoreSceneDraftSnapshot(
        sceneId,
        snapshotId: result.initialSnapshotId,
      );
      expect(restored, result.initialDraft);
      expect(
        await reopenedRepository.getSceneDraft(sceneId),
        result.initialDraft,
      );
    },
  );
}
