import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/export/domain/export_protection.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/application/story_docx_exporter.dart';
import 'package:void_scriptor/features/story/application/story_markdown_exporter.dart';
import 'package:void_scriptor/features/story/application/story_txt_exporter.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

// Sprint 145.35 - cross-format no-watermark proof: naskah lokal (TXT,
// Markdown, DOCX) diekspor sebagai private master dan diputus melalui
// ExportProtectionPlanner. Kontrak: private master tetap bersih bahkan
// saat policy mode always, manifest mencatat watermarkApplied false, dan
// artefak tidak mengandung teks watermark. Kontras publicPreview
// membuktikan planner memang aktif (test tidak vacuous).
void main() {
  const watermarkText = 'VOID PREVIEW';
  const storyTitle = 'The Void Master Copy';
  const chapterTitle = 'Arrival';
  const draft = 'Neon rain over the megacity.';

  WatermarkStyle style() => WatermarkStyle.validated(
    text: watermarkText,
    position: WatermarkPosition.bottomRight,
    opacity: 0.25,
    scalePercent: 4,
  );

  ExportProtectionRequest request({
    required String assetId,
    required ExportUse use,
    required List<int> contentBytes,
  }) {
    return ExportProtectionRequest.validated(
      assetId: assetId,
      kind: ProtectedAssetKind.novel,
      use: use,
      tier: SubscriptionTier.free,
      generatedByApp: false,
      contentBytes: contentBytes,
      ownership: OwnershipMetadata.validated(
        creatorId: 'creator-1',
        projectId: 'project-nw',
        copyrightHolder: 'Choirudin',
        rightsStatement: 'All rights reserved.',
      ),
      exportRevision: 'rev-1',
    );
  }

  Future<(StoryRepositoryImpl, String, CreateStoryService)>
  seedFixture() async {
    final root = await Directory.systemTemp.createTemp('s14535-nw-');
    final paths = ProjectPaths(rootDirectory: root);
    final dbPath = (await paths.database('project-nw')).path;
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final db = await service.open(dbPath);
    addTearDown(db.close);
    final storyService = CreateStoryService(database: db, paths: paths);
    final storyId = await storyService.createStory(
      projectId: 'project-nw',
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
      title: 'Megacity Landing',
      sceneNumber: 1,
    );
    final repository = StoryRepositoryImpl(
      database: db,
      projectId: 'project-nw',
    );
    await repository.saveSceneDraft(sceneId, draft);
    return (repository, storyId, storyService);
  }

  test(
    'TXT export sebagai private master tetap bersih dari watermark',
    () async {
      final (repository, storyId, _) = await seedFixture();
      final out = await Directory.systemTemp.createTemp('s14535-nw-out-');
      addTearDown(() => out.deleteSync(recursive: true));
      final file = await const StoryTxtExporter().writeExport(
        repository,
        storyId,
        exportDirectory: out,
      );

      final bytes = file.readAsBytesSync();
      final decision = const ExportProtectionPlanner().plan(
        request(
          assetId: storyId,
          use: ExportUse.privateMaster,
          contentBytes: bytes,
        ),
        WatermarkPolicy.validated(mode: WatermarkMode.always, style: style()),
      );

      expect(decision.applyWatermark, isFalse);
      expect(decision.overlay, isNull);
      expect(decision.reason, contains('master'));
      expect(decision.sourceContentPreserved, isTrue);
      expect(decision.manifest.watermarkApplied, isFalse);
      expect(utf8.decode(bytes), isNot(contains(watermarkText)));
    },
  );

  test(
    'Markdown export sebagai private master tetap bersih dari watermark',
    () async {
      final (repository, storyId, _) = await seedFixture();
      final out = await Directory.systemTemp.createTemp('s14535-nw-out-');
      addTearDown(() => out.deleteSync(recursive: true));
      final file = await const StoryMarkdownExporter().writeExport(
        repository,
        storyId,
        exportDirectory: out,
      );

      final bytes = file.readAsBytesSync();
      final decision = const ExportProtectionPlanner().plan(
        request(
          assetId: storyId,
          use: ExportUse.privateMaster,
          contentBytes: bytes,
        ),
        WatermarkPolicy.validated(mode: WatermarkMode.always, style: style()),
      );

      expect(decision.applyWatermark, isFalse);
      expect(decision.overlay, isNull);
      expect(decision.manifest.watermarkApplied, isFalse);
      expect(utf8.decode(bytes), isNot(contains(watermarkText)));
    },
  );

  test(
    'DOCX export sebagai private master tetap bersih dari watermark',
    () async {
      final (repository, storyId, _) = await seedFixture();
      final out = await Directory.systemTemp.createTemp('s14535-nw-out-');
      addTearDown(() => out.deleteSync(recursive: true));
      final file = await const StoryDocxExporter().writeExport(
        repository,
        storyId,
        exportDirectory: out,
      );

      final bytes = file.readAsBytesSync();
      final decision = const ExportProtectionPlanner().plan(
        request(
          assetId: storyId,
          use: ExportUse.privateMaster,
          contentBytes: bytes,
        ),
        WatermarkPolicy.validated(mode: WatermarkMode.always, style: style()),
      );

      expect(decision.applyWatermark, isFalse);
      expect(decision.overlay, isNull);
      expect(decision.manifest.watermarkApplied, isFalse);
      final decoded = ZipDecoder().decodeBytes(bytes, verify: true);
      final documentXml = utf8.decode(
        decoded.find('word/document.xml')!.readBytes()!,
      );
      expect(documentXml, isNot(contains(watermarkText)));
      // Konten asli utuh di artefak.
      expect(documentXml, contains(draft));
    },
  );

  test(
    'Kontras: publicPreview pada policy previewOnly menerima watermark',
    () async {
      final (repository, storyId, _) = await seedFixture();
      final out = await Directory.systemTemp.createTemp('s14535-nw-out-');
      addTearDown(() => out.deleteSync(recursive: true));
      final file = await const StoryTxtExporter().writeExport(
        repository,
        storyId,
        exportDirectory: out,
      );

      final bytes = file.readAsBytesSync();
      final decision = const ExportProtectionPlanner().plan(
        request(
          assetId: storyId,
          use: ExportUse.publicPreview,
          contentBytes: bytes,
        ),
        WatermarkPolicy.validated(
          mode: WatermarkMode.previewOnly,
          style: style(),
        ),
      );

      expect(decision.applyWatermark, isTrue);
      expect(decision.overlay?.text, watermarkText);
      expect(decision.manifest.watermarkApplied, isTrue);
      // Naskah master di disk tetap bersih - watermark hanya keputusan
      // untuk pipeline preview, bukan penimpaan artefak master.
      expect(utf8.decode(bytes), isNot(contains(watermarkText)));
    },
  );
}
