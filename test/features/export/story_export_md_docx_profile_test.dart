import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/export/domain/export_profiles.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/application/story_docx_exporter.dart';
import 'package:void_scriptor/features/story/application/story_markdown_exporter.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

/// Sprint 145.35 - metadata propagation untuk Markdown dan DOCX writer.
///
/// ExportProfile front matter dan chapter rules harus diteruskan ke output
/// Markdown dan DOCX (bukan hanya TXT), dan DOCX harus menyertakan metadata
/// OOXML (docProps/core.xml) berisi judul + pengarang.
void main() {
  Future<(StoryRepositoryImpl, String, CreateStoryService)>
  seedFixture() async {
    final root = await Directory.systemTemp.createTemp('s14535-mddocx-');
    final paths = ProjectPaths(rootDirectory: root);
    final dbPath = (await paths.database('project-mddocx')).path;
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final db = await service.open(dbPath);
    addTearDown(db.close);
    final storyService = CreateStoryService(database: db, paths: paths);
    final storyId = await storyService.createStory(
      projectId: 'project-mddocx',
      title: 'The Void',
    );
    await storyService.createChapter(
      storyId: storyId,
      title: 'Arrival',
      chapterNumber: 1,
    );
    final repository = StoryRepositoryImpl(
      database: db,
      projectId: 'project-mddocx',
    );
    return (repository, storyId, storyService);
  }

  ExportProfile profile({String? fmTitle, String? author}) {
    final p = ExportProfile.docx();
    if (fmTitle != null || author != null) {
      p.setFrontMatter(title: fmTitle ?? 'The Void', author: author ?? '');
    }
    p.setChapterRules(
      numberingStart: 1,
      titlePrefix: 'Chapter',
      pageBreakBefore: true,
    );
    return p;
  }

  test('Markdown tanpa profile memakai judul story asli', () async {
    final (repository, storyId, _) = await seedFixture();
    const exporter = StoryMarkdownExporter();
    final output = await exporter.exportStory(repository, storyId);
    expect(output, startsWith('# The Void'));
    expect(output, contains('## Arrival'));
  });

  test(
    'Markdown dengan profile memakai front matter dan chapter prefix',
    () async {
      final (repository, storyId, _) = await seedFixture();
      const exporter = StoryMarkdownExporter();
      final output = await exporter.exportStory(
        repository,
        storyId,
        profile: profile(fmTitle: 'The Void Novel', author: 'Choirudin'),
      );
      expect(output, startsWith('# The Void Novel'));
      expect(output, contains('Choirudin'));
      expect(output, contains('## Chapter 1'));
      expect(output, isNot(contains('## Arrival')));
    },
  );

  test('DOCX tanpa profile memakai judul story asli', () async {
    final (repository, storyId, _) = await seedFixture();
    final out = await Directory.systemTemp.createTemp('s14535-mddocx-out-');
    addTearDown(() => out.deleteSync(recursive: true));
    final file = await const StoryDocxExporter().writeExport(
      repository,
      storyId,
      exportDirectory: out,
    );
    final decoded = ZipDecoder().decodeBytes(
      file.readAsBytesSync(),
      verify: true,
    );
    final documentXml = utf8.decode(
      decoded.find('word/document.xml')!.readBytes()!,
    );
    expect(documentXml, contains('The Void'));
    expect(documentXml, contains('Arrival'));
    // Metadata OOXML tetap hadir, title mengikuti judul story.
    final coreXml = utf8.decode(
      decoded.find('docProps/core.xml')!.readBytes()!,
    );
    expect(coreXml, contains('<dc:title>The Void</dc:title>'));
  });

  test(
    'DOCX dengan profile memakai front matter, chapter prefix, dan metadata',
    () async {
      final (repository, storyId, _) = await seedFixture();
      final out = await Directory.systemTemp.createTemp('s14535-mddocx-out2-');
      addTearDown(() => out.deleteSync(recursive: true));
      final file = await const StoryDocxExporter().writeExport(
        repository,
        storyId,
        exportDirectory: out,
        profile: profile(fmTitle: 'The Void Novel', author: 'Choirudin'),
      );
      final decoded = ZipDecoder().decodeBytes(
        file.readAsBytesSync(),
        verify: true,
      );
      final documentXml = utf8.decode(
        decoded.find('word/document.xml')!.readBytes()!,
      );
      expect(documentXml, contains('The Void Novel'));
      expect(documentXml, contains('Choirudin'));
      expect(documentXml, contains('Chapter 1'));
      expect(documentXml, isNot(contains('Arrival')));
      final coreXml = utf8.decode(
        decoded.find('docProps/core.xml')!.readBytes()!,
      );
      expect(coreXml, contains('<dc:title>The Void Novel</dc:title>'));
      expect(coreXml, contains('<dc:creator>Choirudin</dc:creator>'));
    },
  );
}
