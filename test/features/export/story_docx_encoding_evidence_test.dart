import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/application/story_docx_exporter.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

/// Sprint 145.35 - bukti encoding-aware DOCX pada batas internal writer.
///
/// Format DOCX (OOXML) mempersyaratkan part XML dienkode UTF-8 dan TANPA
/// byte order mark: Word menolak file bila prolog XML tidak persis
/// `<?xml version="1.0" encoding="UTF-8"?>` di awal part. Bukti ini
/// memastikan writer tidak menambahkan BOM dan tetap menulis UTF-8
/// byte-exact pada Unicode publishing fixture (Latin-1 subset),
/// selaras matriks encoding 27712d8 dan opsi TXT/Markdown (0b3d34e).
void main() {
  Future<(StoryRepositoryImpl, String, CreateStoryService)>
  seedStoryFixture() async {
    final root = await Directory.systemTemp.createTemp('s14535-docx-enc-');
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
    'DOCX parts are utf8 without BOM and unicode stays byte-exact',
    () async {
      final (repository, storyId, _) = await seedStoryFixture();
      final out = await Directory.systemTemp.createTemp('s14535-docx-out-');
      addTearDown(() => out.deleteSync(recursive: true));
      final file = await const StoryDocxExporter().writeExport(
        repository,
        storyId,
        exportDirectory: out,
      );
      final bytes = await file.readAsBytes();
      expect(bytes.take(2), [0x50, 0x4B]);
      final decoded = ZipDecoder().decodeBytes(bytes, verify: true);
      const xmlParts = [
        'word/document.xml',
        'docProps/core.xml',
        '[Content_Types].xml',
        'word/styles.xml',
      ];
      for (final name in xmlParts) {
        final part = decoded.find(name)!.readBytes()!;
        expect(
          part.take(3),
          isNot([0xEF, 0xBB, 0xBF]),
          reason: 'BOM dilarang di part XML OOXML: $name',
        );
        final text = utf8.decode(part);
        expect(
          text,
          startsWith('<?xml version="1.0" encoding="UTF-8"'),
          reason: 'prolog wajib di awal part: $name',
        );
      }
      final documentXml = utf8.decode(
        decoded.find('word/document.xml')!.readBytes()!,
      );
      expect(documentXml, contains('Kafe \u00f1 di trotoar'));
    },
  );
}
