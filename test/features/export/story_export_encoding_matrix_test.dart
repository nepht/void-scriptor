import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/application/story_docx_exporter.dart';
import 'package:void_scriptor/features/story/application/story_markdown_exporter.dart';
import 'package:void_scriptor/features/story/application/story_txt_exporter.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

/// Sprint 145.35 - explicit encoding matrix: Unicode publishing fixture
/// dijamin round-trip (UTF-8, tanpa BOM, tanpa U+FFFD) untuk TXT,
/// Markdown, dan DOCX.
void main() {
  // Emoji via \u{...}; semua non-ASCII memakai escape eksplisit agar file
  // test tetap ASCII murni.
  const storyTitle =
      'Kisah Void: Mata Angin \u2014 \u7b2c\u4e00\u5377 \u{1F4D6}';
  const chapterTitle = 'Bab Perbatasan \u00d1 \u00df \u2014 \u7b2c\u4e00\u7ae0';
  const sceneTitle = 'Adegan Hujan \u0950';
  const draftLine1 =
      'Hujan neon \u00f1 \u{1F327} \u2023 \u201eajaib\u201c \u0646\u0627\u0646';
  const draftLine2 = 'Tab\tbertahan \u{1D11E}';
  const draft = '$draftLine1\n$draftLine2';

  Future<(StoryRepositoryImpl, String, CreateStoryService)>
  seedUnicodeFixture() async {
    final root = await Directory.systemTemp.createTemp('s14535-enc-');
    final paths = ProjectPaths(rootDirectory: root);
    final dbPath = (await paths.database('project-enc')).path;
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final db = await service.open(dbPath);
    addTearDown(db.close);
    final storyService = CreateStoryService(database: db, paths: paths);
    final storyId = await storyService.createStory(
      projectId: 'project-enc',
      title: storyTitle,
    );
    final chapterId = await storyService.createChapter(
      storyId: storyId,
      title: chapterTitle,
      chapterNumber: 1,
    );
    final sceneId = await storyService.createScene(
      storyId: storyId,
      chapterId: chapterId,
      title: sceneTitle,
      sceneNumber: 1,
    );
    final repository = StoryRepositoryImpl(
      database: db,
      projectId: 'project-enc',
    );
    await repository.saveSceneDraft(sceneId, draft);
    return (repository, storyId, storyService);
  }

  void expectNoReplacementChar(String text) {
    expect(
      text.contains('\uFFFD'),
      isFalse,
      reason: 'encoding matrix melarang replacement char',
    );
  }

  test('TXT exporter preserves Unicode draft byte-exact without BOM', () async {
    final (repository, storyId, _) = await seedUnicodeFixture();
    final out = await Directory.systemTemp.createTemp('s14535-enc-out-');
    addTearDown(() => out.deleteSync(recursive: true));
    final file = await const StoryTxtExporter().writeExport(
      repository,
      storyId,
      exportDirectory: out,
    );

    final bytes = file.readAsBytesSync();
    expect(bytes.take(3).toList(), isNot(equals([0xEF, 0xBB, 0xBF])));
    final text = utf8.decode(bytes);
    expectNoReplacementChar(text);
    expect(text, contains(storyTitle));
    expect(text, contains(chapterTitle));
    expect(text, contains(draftLine1));
    expect(text, contains(draftLine2));
  });

  test('Markdown exporter preserves Unicode headings byte-exact', () async {
    final (repository, storyId, _) = await seedUnicodeFixture();
    final out = await Directory.systemTemp.createTemp('s14535-enc-out-');
    addTearDown(() => out.deleteSync(recursive: true));
    final file = await const StoryMarkdownExporter().writeExport(
      repository,
      storyId,
      exportDirectory: out,
    );

    final text = utf8.decode(file.readAsBytesSync());
    expectNoReplacementChar(text);
    expect(text, startsWith('# $storyTitle'));
    expect(text, contains('## $chapterTitle'));
    expect(text, contains('### $sceneTitle'));
    expect(text, contains(draftLine1));
    expect(text, contains(draftLine2));
  });

  test('DOCX exporter preserves Unicode through ZIP+XML round-trip', () async {
    final (repository, storyId, _) = await seedUnicodeFixture();
    final out = await Directory.systemTemp.createTemp('s14535-enc-out-');
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
    expectNoReplacementChar(documentXml);
    expect(documentXml, contains(chapterTitle));
    expect(documentXml, contains(sceneTitle));
    expect(documentXml, contains(draftLine1));
    expect(documentXml, contains(draftLine2));
  });
}
