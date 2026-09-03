import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/application/story_txt_exporter.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

/// Sprint 145.35 - opsi encoding non-UTF-8 dan BOM untuk naskah TXT.
///
/// Konsumen publishing lawas (Word/LibreOffice era lama) kadang membutuhkan
/// BOM agar mendeteksi UTF-8, atau encoding single-byte seperti Latin-1.
/// Default TETAP UTF-8 tanpa BOM (kontrak encoding matrix 145.35).
void main() {
  Future<(StoryRepositoryImpl, String, CreateStoryService)>
  seedStoryFixture() async {
    final root = await Directory.systemTemp.createTemp('s14535-enc-');
    final paths = ProjectPaths(rootDirectory: root);
    final dbPath = (await paths.database('project-1')).path;
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final db = await service.open(dbPath);
    addTearDown(db.close);
    final storyService = CreateStoryService(database: db, paths: paths);
    final storyId = await storyService.createStory(
      projectId: 'project-1',
      title: 'Naskah Encoding',
    );
    final chapter = await storyService.createChapter(
      storyId: storyId,
      title: 'Bab Satu',
      chapterNumber: 1,
    );
    final scene = await storyService.createScene(
      storyId: storyId,
      chapterId: chapter,
      sceneNumber: 1,
      title: 'Adegan',
    );
    final repository = StoryRepositoryImpl(
      database: db,
      projectId: 'project-1',
    );
    await repository.saveSceneDraft(scene, 'Kafe \u00f1 di trotoar');
    return (repository, storyId, storyService);
  }

  test(
    'latin1 export writes bom plus latin1 bytes without replacement',
    () async {
      final (repository, storyId, _) = await seedStoryFixture();
      final dir = await Directory.systemTemp.createTemp('s14535-enc-out-');
      addTearDown(() => dir.delete(recursive: true));
      final file = await const StoryTxtExporter().writeExport(
        repository,
        storyId,
        exportDirectory: dir,
        fileName: 'story-latin1.txt',
        encoding: const Latin1Codec(),
        bom: true,
      );
      final bytes = await file.readAsBytes();
      expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
      final body = bytes.skip(3).toList();
      const text = 'Kafe \u00f1 di trotoar';
      expect(latin1.decode(body), contains(text));
      expect(body, isNot(contains(utf8.encode('\u00f1'))));
    },
  );

  test('utf8 export with bom prefixes EF BB BF and round-trips', () async {
    final (repository, storyId, _) = await seedStoryFixture();
    final dir = await Directory.systemTemp.createTemp('s14535-enc-out-');
    addTearDown(() => dir.delete(recursive: true));
    final file = await const StoryTxtExporter().writeExport(
      repository,
      storyId,
      exportDirectory: dir,
      fileName: 'story-bom.txt',
      bom: true,
    );
    final bytes = await file.readAsBytes();
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    expect(utf8.decode(bytes.skip(3).toList()), contains('Kafe \u00f1'));
  });

  test('default export stays utf8 without bom', () async {
    final (repository, storyId, _) = await seedStoryFixture();
    final dir = await Directory.systemTemp.createTemp('s14535-enc-out-');
    addTearDown(() => dir.delete(recursive: true));
    final file = await const StoryTxtExporter().writeExport(
      repository,
      storyId,
      exportDirectory: dir,
      fileName: 'story-default.txt',
    );
    final bytes = await file.readAsBytes();
    expect(bytes.take(3), isNot([0xEF, 0xBB, 0xBF]));
    expect(utf8.decode(bytes), contains('Kafe \u00f1'));
  });
}
