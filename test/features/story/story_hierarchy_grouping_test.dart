// bug-hunt-run128 BUG-14 - getStoryHierarchy harus memetakan scene ke chapter
// dan chapter ke arc lewat lookup, bukan nested linear scan O(C*S^2). Test ini
// mengunci SEMANTIK grouping yang benar (2 arc x 3 chapter x 5 scene) supaya
// refactor Map-based tidak mengubah hasil; jumlah perbandingan tidak diassert
// (itu beban perf), tetapi struktur node-lah yang harus tetap identik.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

void main() {
  test('story hierarchy groups every scene under its chapter and chapter under '
      'its arc across a multi-arc tree', () async {
    final tempRoot = await Directory.systemTemp.createTemp('bug14-hier-');
    final packageRoot = Directory('${tempRoot.path}/projects');
    final package = await ProjectPackageService(
      rootDirectory: packageRoot,
    ).create(name: 'BUG14 Hierarchy');
    final session = await ProjectSessionManager().open(package);
    addTearDown(() async {
      await session.close();
      try {
        if (await tempRoot.exists()) {
          await tempRoot.delete(recursive: true);
        }
      } catch (_) {}
    });
    final service = CreateStoryService(
      database: session.database,
      paths: ProjectPaths(rootDirectory: packageRoot),
    );
    final storyId = await service.createStory(
      projectId: package.projectId,
      title: 'Nested',
    );
    final arc1 = await service.createArc(storyId: storyId, title: 'Arc 1');
    final arc2 = await service.createArc(storyId: storyId, title: 'Arc 2');
    final ch11 = await service.createChapter(
      storyId: storyId,
      arcId: arc1,
      title: 'Bab 1.1',
      chapterNumber: 1,
    );
    final ch12 = await service.createChapter(
      storyId: storyId,
      arcId: arc1,
      title: 'Bab 1.2',
      chapterNumber: 2,
    );
    final ch21 = await service.createChapter(
      storyId: storyId,
      arcId: arc2,
      title: 'Bab 2.1',
      chapterNumber: 3,
    );
    final s111 = await service.createScene(
      storyId: storyId,
      chapterId: ch11,
      title: 'Adegan 1',
      sceneNumber: 1,
    );
    final s112 = await service.createScene(
      storyId: storyId,
      chapterId: ch11,
      title: 'Adegan 2',
      sceneNumber: 2,
    );
    final s121 = await service.createScene(
      storyId: storyId,
      chapterId: ch12,
      title: 'Adegan 3',
      sceneNumber: 3,
    );
    final s211 = await service.createScene(
      storyId: storyId,
      chapterId: ch21,
      title: 'Adegan 4',
      sceneNumber: 4,
    );
    final s212 = await service.createScene(
      storyId: storyId,
      chapterId: ch21,
      title: 'Adegan 5',
      sceneNumber: 5,
    );

    final repo = StoryRepositoryImpl(
      database: session.database,
      projectId: package.projectId,
    );
    final hierarchy = await repo.getStoryHierarchy(storyId);

    // Chapter grouping: tiap chapter memuat tepat scene miliknya.
    final chaptersById = {for (final c in hierarchy.chapters) c.id: c};
    expect(chaptersById, hasLength(3));
    expect(chaptersById[ch11]!.scenes.map((s) => s.id).toSet(), {s111, s112});
    expect(chaptersById[ch12]!.scenes.map((s) => s.id).toSet(), {s121});
    expect(chaptersById[ch21]!.scenes.map((s) => s.id).toSet(), {s211, s212});

    // Arc grouping: tiap arc memuat tepat chapter miliknya, tanpa cross-arc.
    final arcsById = {for (final a in hierarchy.arcs) a.id: a};
    expect(arcsById, hasLength(2));
    expect(arcsById[arc1]!.chapters.map((c) => c.id).toSet(), {ch11, ch12});
    expect(arcsById[arc2]!.chapters.map((c) => c.id).toSet(), {ch21});

    // Tidak ada scene yang hilang atau terduplikasi di seluruh pohon.
    final allSceneIds = [
      for (final a in hierarchy.arcs)
        for (final c in a.chapters)
          for (final s in c.scenes) s.id,
    ];
    expect(allSceneIds, hasLength(5));
    expect(allSceneIds.toSet(), {s111, s112, s121, s211, s212});
  });
}
