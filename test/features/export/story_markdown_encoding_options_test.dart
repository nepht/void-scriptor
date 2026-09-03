import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/application/story_markdown_exporter.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

/// Sprint 145.35 - opsi encoding non-UTF-8 dan BOM untuk naskah Markdown.
///
/// Paritas dengan opsi TXT writer (encoding + BOM): konsumen publishing
/// lawas yang membaca .md sebagai teks polos butuh BOM agar mendeteksi
/// UTF-8, atau encoding single-byte seperti Latin-1. Konten internal
/// Markdown (heading `#`, `##`, `###`) tetap dihasilkan identik; hanya
/// representasi byte file yang berubah. Default TETAP UTF-8 tanpa BOM.
void main() {
  Future<(StoryRepositoryImpl, String, CreateStoryService)>
  seedStoryFixture() async {
    final root = await Directory.systemTemp.createTemp('s14535-md-enc-');
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

  test('latin1 markdown export writes bom plus latin1 bytes', () async {
    final (repository, storyId, _) = await seedStoryFixture();
    final dir = await Directory.systemTemp.createTemp('s14535-md-out-');
    addTearDown(() => dir.delete(recursive: true));
    final file = await const StoryMarkdownExporter().writeExport(
      repository,
      storyId,
      exportDirectory: dir,
      fileName: 'story-latin1.md',
      encoding: const Latin1Codec(),
      bom: true,
    );
    final bytes = await file.readAsBytes();
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final body = bytes.skip(3).toList();
    const text = 'Kafe \u00f1 di trotoar';
    expect(latin1.decode(body), contains('# Naskah Encoding'));
    expect(latin1.decode(body), contains(text));
    expect(body, isNot(contains(utf8.encode('\u00f1'))));
  });

  test(
    'utf8 markdown export with bom prefixes EF BB BF and round-trips',
    () async {
      final (repository, storyId, _) = await seedStoryFixture();
      final dir = await Directory.systemTemp.createTemp('s14535-md-out-');
      addTearDown(() => dir.delete(recursive: true));
      final file = await const StoryMarkdownExporter().writeExport(
        repository,
        storyId,
        exportDirectory: dir,
        fileName: 'story-bom.md',
        bom: true,
      );
      final bytes = await file.readAsBytes();
      expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
      expect(utf8.decode(bytes.skip(3).toList()), contains('Kafe \u00f1'));
    },
  );

  test('default markdown export stays utf8 without bom', () async {
    final (repository, storyId, _) = await seedStoryFixture();
    final dir = await Directory.systemTemp.createTemp('s14535-md-out-');
    addTearDown(() => dir.delete(recursive: true));
    final file = await const StoryMarkdownExporter().writeExport(
      repository,
      storyId,
      exportDirectory: dir,
      fileName: 'story-default.md',
    );
    final bytes = await file.readAsBytes();
    expect(bytes.take(3), isNot([0xEF, 0xBB, 0xBF]));
    final text = utf8.decode(bytes);
    expect(text, contains('# Naskah Encoding'));
    expect(text, contains('Kafe \u00f1'));
  });
}
