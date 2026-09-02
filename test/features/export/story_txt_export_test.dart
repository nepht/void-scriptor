import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/application/story_txt_exporter.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

void main() {
  Future<(StoryRepositoryImpl, String, CreateStoryService)> seedStoryFixture() async {
    final root = await Directory.systemTemp.createTemp('s14535-txt-');
    final paths = ProjectPaths(rootDirectory: root);
    final dbPath = (await paths.database('project-1')).path;
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final db = await service.open(dbPath);
    addTearDown(db.close);
    final storyService = CreateStoryService(database: db, paths: paths);
    final storyId = await storyService.createStory(
      projectId: 'project-1',
      title: 'Qowner: Rise of the Void',
    );
    final repository = StoryRepositoryImpl(
      database: db,
      projectId: 'project-1',
    );
    return (repository, storyId, storyService);
  }

  test(
    'plain txt export keeps chapter order with page breaks and no markdown',
    () async {
      final (repository, storyId, storyService) = await seedStoryFixture();
      final chapter1 = await storyService.createChapter(
        storyId: storyId,
        title: 'Arrival',
        chapterNumber: 1,
      );
      final scene11 = await storyService.createScene(
        storyId: storyId,
        chapterId: chapter1,
        title: 'Megacity Landing',
        sceneNumber: 1,
      );
      final scene12 = await storyService.createScene(
        storyId: storyId,
        chapterId: chapter1,
        title: 'Neon Rain',
        sceneNumber: 2,
      );
      final chapter2 = await storyService.createChapter(
        storyId: storyId,
        title: 'Departure',
        chapterNumber: 2,
      );
      final scene21 = await storyService.createScene(
        storyId: storyId,
        chapterId: chapter2,
        title: 'Void Gate',
        sceneNumber: 1,
      );
      await repository.saveSceneDraft(scene11, 'landing text');
      await repository.saveSceneDraft(scene12, 'storm text');
      await repository.saveSceneDraft(scene21, 'gate text');

      const exporter = StoryTxtExporter();
      final output = await exporter.exportStory(repository, storyId);

      expect(output.startsWith('Qowner: Rise of the Void'), isTrue);
      expect(output.contains('#'), isFalse);
      expect(output.contains('Megacity Landing'), isFalse);
      expect(output.endsWith('\n'), isFalse);

      final lines = output.split('\n');
      final breakIndexes = [
        for (var i = 0; i < lines.length; i++)
          if (lines[i] == '=' * 40) i,
      ];
      expect(breakIndexes, hasLength(1));
      expect(lines[breakIndexes.first - 1], isEmpty);
      expect(lines[breakIndexes.first + 1], isEmpty);

      final order = <String>[];
      for (final line in lines) {
        if (line == 'Arrival') order.add('c1');
        if (line == 'Departure') order.add('c2');
        if (line == 'landing text') order.add('s11');
        if (line == 'storm text') order.add('s12');
        if (line == 'gate text') order.add('s21');
      }
      expect(order, ['c1', 's11', 's12', 'c2', 's21']);
    },
  );

  test('txt writeExport validates filename and writes exact content', () async {
    final (repository, storyId, _) = await seedStoryFixture();
    const exporter = StoryTxtExporter();
    final out = await Directory.systemTemp.createTemp('s14535-out-');

    await expectLater(
      exporter.writeExport(
        repository,
        storyId,
        exportDirectory: out,
        fileName: 'story.md',
      ),
      throwsArgumentError,
    );
    await expectLater(
      exporter.writeExport(
        repository,
        storyId,
        exportDirectory: out,
        fileName: '../story.txt',
      ),
      throwsArgumentError,
    );

    final file = await exporter.writeExport(
      repository,
      storyId,
      exportDirectory: out,
    );
    expect(file.existsSync(), isTrue);
    expect(file.uri.pathSegments.last, 'story.txt');
    final expected =
        (await exporter.exportStory(repository, storyId)) +
        String.fromCharCode(10);
    expect(file.readAsStringSync(), expected);
  });
}
