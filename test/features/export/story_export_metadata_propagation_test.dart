import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/export/domain/export_profiles.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/application/story_txt_exporter.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

/// Sprint 145.35 - metadata propagation: ExportProfile front matter dan
/// chapter rules diteruskan ke output manuscript exporter.
void main() {
  Future<(StoryRepositoryImpl, String, CreateStoryService)>
  seedFixture() async {
    final root = await Directory.systemTemp.createTemp('s14535-meta-');
    final paths = ProjectPaths(rootDirectory: root);
    final dbPath = (await paths.database('project-meta')).path;
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final db = await service.open(dbPath);
    addTearDown(db.close);
    final storyService = CreateStoryService(database: db, paths: paths);
    final storyId = await storyService.createStory(
      projectId: 'project-meta',
      title: 'The Void',
    );
    await storyService.createChapter(
      storyId: storyId,
      title: 'Arrival',
      chapterNumber: 1,
    );
    final repository = StoryRepositoryImpl(
      database: db,
      projectId: 'project-meta',
    );
    return (repository, storyId, storyService);
  }

  test('TXT exporter tanpa profile sama dengan sebelumnya', () async {
    final (repository, storyId, _) = await seedFixture();
    const exporter = StoryTxtExporter();
    final output = await exporter.exportStory(repository, storyId);
    expect(output, startsWith('The Void'));
    // Tidak ada front matter tambahan.
    expect(output, isNot(contains('Pengarang:')));
  });

  test('TXT exporter dengan profile memunculkan front matter', () async {
    final (repository, storyId, _) = await seedFixture();
    const exporter = StoryTxtExporter();
    final profile = ExportProfile.plainText()
      ..setFrontMatter(title: 'The Void Novel', author: 'Choirudin');
    final output = await exporter.exportStory(
      repository,
      storyId,
      profile: profile,
    );
    expect(output, startsWith('The Void Novel'));
    expect(output, contains('Choirudin'));
    // Judul asli masih ada di body.
    expect(output, contains('Arrival'));
  });

  test('TXT exporter dengan profile memakai chapter prefix', () async {
    final (repository, storyId, _) = await seedFixture();
    const exporter = StoryTxtExporter();
    final profile = ExportProfile.plainText()
      ..setChapterRules(
        numberingStart: 1,
        titlePrefix: 'Chapter',
        pageBreakBefore: false,
      );
    final output = await exporter.exportStory(
      repository,
      storyId,
      profile: profile,
    );
    // Judul bab asli 'Arrival' diganti 'Chapter 1' karena prefix.
    expect(output, contains('Chapter 1'));
    expect(output, isNot(contains('Arrival')));
  });
}
