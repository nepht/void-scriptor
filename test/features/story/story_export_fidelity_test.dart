import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/application/story_docx_exporter.dart';
import 'package:void_scriptor/features/story/application/story_export_fidelity.dart';
import 'package:void_scriptor/features/story/application/story_markdown_exporter.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

/// Matriks fidelity export 145.24: satu novel fixture (2 bab, 2 scene per bab,
/// synopsis, karakter XML seperti '<' & dunia, baris kosong di draft) diekspor
/// ke Markdown dan DOCX, lalu hasilnya diverifikasi terhadap prasyarat
/// no-break 145.24:
///   1. judul story muncul satu kali di atas;
///   2. hunk: title (synopsis?) diikuti [chapter -> [scene -> [draft-line]]];
///   3. urutan export mengikuti ordering database (sortOrder);
///   4. export tidak memutasi naskah hidup (draft DB byte-identical);
///   5. setiap isi scene draft muncul utuh di kedua format.
void main() {
  test(
    'export fidelity matrix: markdown and docx match the ordered source',
    () async {
      final root = await Directory.systemTemp.createTemp('s145-24-fidelity-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final dbPath = (await paths.database('project-fidelity')).path;
      final service = ProjectDatabaseService();
      await service.create(dbPath);
      final db = await service.open(dbPath);
      addTearDown(db.close);

      final storyService = CreateStoryService(database: db, paths: paths);
      final storyId = await storyService.createStory(
        projectId: 'project-fidelity',
        title: 'Matrix Novel',
      );
      await (db.update(db.stories)..where((row) => row.assetId.equals(storyId)))
          .write(const StoriesCompanion(synopsis: Value('Sinopsis & <awal>.')));

      Future<String> chapter(String title, int number) => storyService
          .createChapter(storyId: storyId, title: title, chapterNumber: number);
      Future<String> scene(String chapterId, String title, int number) =>
          storyService.createScene(
            storyId: storyId,
            chapterId: chapterId,
            title: title,
            sceneNumber: number,
          );

      final chapterA = await chapter('Bab Satu', 1);
      final chapterB = await chapter('Bab Dua', 2);
      final sceneA1 = await scene(chapterA, 'S1', 1);
      final sceneA2 = await scene(chapterA, 'S2', 2);
      final sceneB1 = await scene(chapterB, 'S3', 1);
      final sceneB2 = await scene(chapterB, 'S4', 2);

      final repository = StoryRepositoryImpl(
        database: db,
        projectId: 'project-fidelity',
      );
      await repository.saveSceneDraft(
        sceneA1,
        'Qowner <melangkah> & dunia tetap diam.\n\nBaris kedua.',
      );
      await repository.saveSceneDraft(sceneA2, 'Draft dua.');
      await repository.saveSceneDraft(sceneB1, 'Draft tiga.');
      await repository.saveSceneDraft(sceneB2, 'Draft empat.');

      // Snapshot prasyarat 4: isi draft hidup sebelum export.
      final draftsBefore = <String, String?>{
        for (final id in [sceneA1, sceneA2, sceneB1, sceneB2])
          id: await repository.getSceneDraft(id),
      };

      final markdown = await const StoryMarkdownExporter().exportStory(
        repository,
        storyId,
      );
      final markdownReport = const StoryExportFidelity().markdownReport(
        markdown,
        expectTitle: 'Matrix Novel',
        expectSynopsis: 'Sinopsis & <awal>.',
        expectHunks: [
          const FidelityHunk(
            title: 'Bab Satu',
            children: [
              FidelityHunk(
                title: 'S1',
                lines: [
                  'Qowner <melangkah> & dunia tetap diam.',
                  '',
                  'Baris kedua.',
                ],
              ),
              FidelityHunk(title: 'S2', lines: ['Draft dua.']),
            ],
          ),
          const FidelityHunk(
            title: 'Bab Dua',
            children: [
              FidelityHunk(title: 'S3', lines: ['Draft tiga.']),
              FidelityHunk(title: 'S4', lines: ['Draft empat.']),
            ],
          ),
        ],
      );
      expect(
        markdownReport.failures,
        isEmpty,
        reason: 'markdown fidelity failures: ${markdownReport.failures}',
      );
      // Judul story muncul tepat satu kali.
      expect('Matrix Novel'.allMatches(markdown).length, 1);

      final docxFile = await const StoryDocxExporter().writeExport(
        repository,
        storyId,
        exportDirectory: Directory(p.join(root.path, 'exports')),
        fileName: 'matrix.docx',
      );
      final decoded = ZipDecoder().decodeBytes(
        docxFile.readAsBytesSync(),
        verify: true,
      );
      final documentXml = utf8.decode(
        decoded.find('word/document.xml')!.readBytes()!,
      );
      final docxReport = const StoryExportFidelity().docxReport(
        documentXml,
        expectTitle: 'Matrix Novel',
        expectSynopsis: 'Sinopsis & <awal>.',
        expectHunks: [
          const FidelityHunk(
            title: 'Bab Satu',
            children: [
              FidelityHunk(
                title: 'S1',
                lines: [
                  'Qowner <melangkah> & dunia tetap diam.',
                  '',
                  'Baris kedua.',
                ],
              ),
              FidelityHunk(title: 'S2', lines: ['Draft dua.']),
            ],
          ),
          const FidelityHunk(
            title: 'Bab Dua',
            children: [
              FidelityHunk(title: 'S3', lines: ['Draft tiga.']),
              FidelityHunk(title: 'S4', lines: ['Draft empat.']),
            ],
          ),
        ],
      );
      expect(
        docxReport.failures,
        isEmpty,
        reason: 'docx fidelity failures: ${docxReport.failures}',
      );
      expect('Matrix Novel'.allMatches(documentXml).length, 1);

      // Prasyarat 4: export tidak memutasi naskah hidup.
      for (final entry in draftsBefore.entries) {
        expect(
          await repository.getSceneDraft(entry.key),
          entry.value,
          reason: 'draft scene ${entry.key} berubah setelah export',
        );
      }
    },
  );
}
