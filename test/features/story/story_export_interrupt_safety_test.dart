import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/application/story_docx_exporter.dart';
import 'package:void_scriptor/features/story/application/story_markdown_exporter.dart';
import 'package:void_scriptor/features/story/application/story_txt_exporter.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

/// 145.42 interrupted-export safety: `writeExport` menulis file final HANYA
/// lewat staging atomik `<final>.tmp` (konvensi atomic-write repo: journal
/// `<scene>.json.tmp`, registry `<file>.tmp`) lalu rename. Kegagalan tulis di
/// tengah (disk penuh, proses dihentikan, izin) tidak boleh meninggalkan file
/// ekspor final terpotong, dan ekspor valid sebelumnya harus tetap utuh.
///
/// Injeksi kegagalan deterministik lintas platform (pola journal
/// failure-injection): path staging ditanam sebagai DIREKTORI sehingga
/// penulisan staging pasti gagal, tanpa mock dan tanpa chmod.
void main() {
  test(
    'successful txt export writes final content without staging leftovers',
    () async {
      final env = await _seed();
      addTearDown(() => _teardown(env));

      final file = await const StoryTxtExporter().writeExport(
        env.repository,
        env.storyId,
        exportDirectory: env.exportDir,
      );

      final content = await file.readAsString();
      expect(content.startsWith('Interrupt Novel'), isTrue);
      expect(content.contains('Draf utuh Qowner.'), isTrue);
      final leftovers = env.exportDir
          .listSync()
          .where((entity) => entity.path.endsWith('.tmp'))
          .toList();
      expect(leftovers, isEmpty);
    },
  );

  test('interrupted txt export leaves no partial final file', () async {
    final env = await _seed();
    addTearDown(() => _teardown(env));
    _plantStagingDirectory(env.exportDir, 'story.txt');

    await expectLater(
      const StoryTxtExporter().writeExport(
        env.repository,
        env.storyId,
        exportDirectory: env.exportDir,
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(
      File(p.join(env.exportDir.path, 'story.txt')).existsSync(),
      isFalse,
      reason: 'file final tidak boleh tercipta dari tulisan parsial',
    );
  });

  test('failed txt export preserves the previous valid export', () async {
    final env = await _seed();
    addTearDown(() => _teardown(env));
    const exporter = StoryTxtExporter();
    final first = await exporter.writeExport(
      env.repository,
      env.storyId,
      exportDirectory: env.exportDir,
    );
    final firstBytes = await first.readAsBytes();
    await env.repository.saveSceneDraft(env.sceneId, 'Draf kedua berbeda.');
    final second = await exporter.writeExport(
      env.repository,
      env.storyId,
      exportDirectory: env.exportDir,
    );
    final previousBytes = await second.readAsBytes();
    expect(previousBytes, isNot(equals(firstBytes)));
    _plantStagingDirectory(env.exportDir, 'story.txt');

    await expectLater(
      exporter.writeExport(
        env.repository,
        env.storyId,
        exportDirectory: env.exportDir,
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(
      await File(first.path).readAsBytes(),
      equals(previousBytes),
      reason: 'ekspor valid sebelumnya tidak boleh tertimpa tulisan parsial',
    );
  });

  test('interrupted markdown export leaves no partial final file', () async {
    final env = await _seed();
    addTearDown(() => _teardown(env));
    _plantStagingDirectory(env.exportDir, 'story.md');

    await expectLater(
      const StoryMarkdownExporter().writeExport(
        env.repository,
        env.storyId,
        exportDirectory: env.exportDir,
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(File(p.join(env.exportDir.path, 'story.md')).existsSync(), isFalse);
  });

  test('interrupted docx export leaves no partial final file', () async {
    final env = await _seed();
    addTearDown(() => _teardown(env));
    _plantStagingDirectory(env.exportDir, 'story.docx');

    await expectLater(
      const StoryDocxExporter().writeExport(
        env.repository,
        env.storyId,
        exportDirectory: env.exportDir,
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(
      File(p.join(env.exportDir.path, 'story.docx')).existsSync(),
      isFalse,
    );
  });

  test('successful docx export remains a decodable zip', () async {
    final env = await _seed();
    addTearDown(() => _teardown(env));

    final file = await const StoryDocxExporter().writeExport(
      env.repository,
      env.storyId,
      exportDirectory: env.exportDir,
    );

    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    expect(archive.findFile('word/document.xml'), isNotNull);
  });

  test(
    'successful re-export replaces the previous export atomically',
    () async {
      final env = await _seed();
      addTearDown(() => _teardown(env));
      const exporter = StoryTxtExporter();
      await exporter.writeExport(
        env.repository,
        env.storyId,
        exportDirectory: env.exportDir,
      );
      await env.repository.saveSceneDraft(env.sceneId, 'Draf kedua berbeda.');

      final file = await exporter.writeExport(
        env.repository,
        env.storyId,
        exportDirectory: env.exportDir,
      );

      final content = await file.readAsString();
      expect(content.contains('Draf kedua berbeda.'), isTrue);
      expect(content.contains('Draf utuh Qowner.'), isFalse);
      final leftovers = env.exportDir
          .listSync()
          .where((entity) => entity.path.endsWith('.tmp'))
          .toList();
      expect(leftovers, isEmpty);
    },
  );
}

class _Env {
  _Env({
    required this.db,
    required this.repository,
    required this.storyId,
    required this.sceneId,
    required this.exportDir,
    required this.root,
  });

  final ProjectDatabase db;
  final StoryRepositoryImpl repository;
  final String storyId;
  final String sceneId;
  final Directory exportDir;
  final Directory root;
}

Future<_Env> _seed() async {
  final root = await Directory.systemTemp.createTemp('s145-42-export-');
  final paths = ProjectPaths(rootDirectory: root);
  final dbPath = (await paths.database('project-x42')).path;
  final service = ProjectDatabaseService();
  await service.create(dbPath);
  final db = await service.open(dbPath);
  final storyService = CreateStoryService(database: db, paths: paths);
  final storyId = await storyService.createStory(
    projectId: 'project-x42',
    title: 'Interrupt Novel',
  );
  final chapterId = await storyService.createChapter(
    storyId: storyId,
    title: 'Bab Satu',
    chapterNumber: 1,
  );
  final sceneId = await storyService.createScene(
    storyId: storyId,
    chapterId: chapterId,
    title: 'S1',
    sceneNumber: 1,
  );
  final repository = StoryRepositoryImpl(
    database: db,
    projectId: 'project-x42',
  );
  await repository.saveSceneDraft(sceneId, 'Draf utuh Qowner.');
  final exportDir = Directory(p.join(root.path, 'exports'))
    ..createSync(recursive: true);
  return _Env(
    db: db,
    repository: repository,
    storyId: storyId,
    sceneId: sceneId,
    exportDir: exportDir,
    root: root,
  );
}

Future<void> _teardown(_Env env) async {
  await env.db.close();
  await Future<void>.delayed(const Duration(milliseconds: 50));
  try {
    await env.root.delete(recursive: true);
  } on FileSystemException {
    // Cleanup temp best-effort; tidak menutupi hasil asersi.
  }
}

void _plantStagingDirectory(Directory exportDir, String fileName) {
  Directory(p.join(exportDir.path, '$fileName.tmp')).createSync();
}
