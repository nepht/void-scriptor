import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/bible/application/create_lore_entity_service.dart';
import 'package:void_scriptor/features/bible/application/lore_backlink_service.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/domain/lore_backlinks.dart';
import 'package:void_scriptor/features/story/domain/lore_link_suggester.dart';

void main() {
  late Directory root;
  late ProjectDatabase database;
  late StoryRepositoryImpl storyRepo;

  setUp(() async {
    root = Directory(
      '${Directory.systemTemp.path}/s109-backlinks-${DateTime.now().microsecondsSinceEpoch}',
    );
    await root.create(recursive: true);
    final paths = ProjectPaths(rootDirectory: root);
    final service = ProjectDatabaseService();
    final dbPath = (await paths.database('project-1')).path;
    await service.create(dbPath);
    database = await service.open(dbPath);
    storyRepo = StoryRepositoryImpl(database: database, projectId: 'project-1');

    await database
        .into(database.stories)
        .insert(
          StoriesCompanion.insert(
            assetId: 'story-1',
            projectId: 'project-1',
            title: 'Saga Api',
          ),
        );

    Future<void> addScene(String id, String title, int number) => database
        .into(database.storyScenes)
        .insert(
          StoryScenesCompanion.insert(
            id: id,
            storyId: 'story-1',
            chapterId: 'ch-1',
            title: title,
            sceneNumber: number,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    await addScene('scene-1', 'Pembukaan', 1);
    await addScene('scene-2', 'Kebakaran', 2);

    await storyRepo.saveSceneDraft(
      'scene-1',
      'Api menyala. [[Api]] membakar \\[[Api]] dan teks polos Api.',
    );
    await storyRepo.saveSceneDraft(
      'scene-2',
      '[[Api]] lagi, lalu [[Naga Hilang]].',
    );
  });

  tearDown(() async {
    await database.close();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    root.deleteSync(recursive: true);
  });

  const catalog = [
    LoreEntityRef(id: 'sp-api', name: 'Api', kind: 'species'),
    LoreEntityRef(id: 'b-naga', name: 'Naga Salju', kind: 'bible:lore'),
  ];

  group('backlink_query', () {
    test(
      'finds link occurrences across scenes with their source titles',
      () async {
        const service = LoreBacklinkService();

        final links = await service.backlinks(
          database,
          projectId: 'project-1',
          entityName: 'Api',
        );

        expect(links.map((l) => l.sourceId), ['scene-1', 'scene-2']);
        expect(links.map((l) => l.sourceTitle), ['Pembukaan', 'Kebakaran']);
        expect(links.every((l) => l.target == 'Api'), isTrue);
      },
    );

    test('ignores escaped openings and plain-text mentions', () async {
      const service = LoreBacklinkService();

      final links = await service.backlinks(
        database,
        projectId: 'project-1',
        entityName: 'Api',
      );

      // scene-1 memuat satu link nyata; escape \[[Api]] dan teks polos "Api"
      // tidak dihitung. scene-2 memuat satu link.
      expect(links, hasLength(2));
    });

    test('matches the trimmed display name case-sensitively', () async {
      const service = LoreBacklinkService();

      final links = await service.backlinks(
        database,
        projectId: 'project-1',
        entityName: ' api ',
      );

      expect(links, isEmpty);
    });

    test('returns empty for an entity never linked', () async {
      const service = LoreBacklinkService();

      final links = await service.backlinks(
        database,
        projectId: 'project-1',
        entityName: 'Air Hidup',
      );

      expect(links, isEmpty);
    });
  });

  group('broken_link_report', () {
    test('flags targets missing from the catalog as broken', () async {
      const service = LoreBacklinkService();

      final report = await service.scanIntegrity(
        database,
        projectId: 'project-1',
        catalog: catalog,
      );

      final broken = report.brokenLinks;
      expect(broken, hasLength(1));
      expect(broken.single.sourceId, 'scene-2');
      expect(broken.single.target, 'Naga Hilang');
      expect(broken.single.health, LoreLinkHealth.broken);
    });

    test('does not flag targets present in the catalog', () async {
      const service = LoreBacklinkService();

      final report = await service.scanIntegrity(
        database,
        projectId: 'project-1',
        catalog: catalog,
      );

      final resolvedTargets = report.findings
          .where((f) => f.health == LoreLinkHealth.resolved)
          .map((f) => f.target)
          .toSet();
      expect(resolvedTargets, {'Api'});
      expect(report.findings, hasLength(3));
    });

    test('uses the live project catalog when none is injected', () async {
      const createService = CreateLoreEntityService();
      await createService.create(
        database,
        projectId: 'project-1',
        name: 'Naga Hilang',
      );

      const service = LoreBacklinkService();
      final healed = await service.scanIntegrity(
        database,
        projectId: 'project-1',
      );

      // Membuat entitas yang hilang menutup temuan broken miliknya.
      // ('Api' tetap broken karena tidak dibuat di skenario ini.)
      expect(
        healed.brokenLinks.map((f) => f.target),
        isNot(contains('Naga Hilang')),
      );
    });
  });

  group('ambiguous_link_report', () {
    test('reports ambiguous links together with every candidate', () async {
      await database
          .into(database.storyScenes)
          .insert(
            StoryScenesCompanion.insert(
              id: 'scene-3',
              storyId: 'story-1',
              chapterId: 'ch-1',
              title: 'Gudang',
              sceneNumber: 3,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      await storyRepo.saveSceneDraft('scene-3', '[[Kubus]] dan [[kubus]].');

      const duplicated = [
        LoreEntityRef(id: 'b-kubus', name: 'Kubus', kind: 'bible:lore'),
        LoreEntityRef(id: 'sp-kubus', name: 'kubus', kind: 'species'),
      ];
      const service = LoreBacklinkService();

      final report = await service.scanIntegrity(
        database,
        projectId: 'project-1',
        catalog: duplicated,
      );

      final ambiguous = report.ambiguousLinks;
      // Kedua kemunculan ([[Kubus]] dan [[kubus]]) digabung ke satu temuan
      // per sumber dengan hitungan occurrences, memuat semua kandidat.
      expect(ambiguous, hasLength(1));
      expect(ambiguous.single.sourceId, 'scene-3');
      expect(ambiguous.single.occurrences, 2);
      expect(
        ambiguous.single.candidates.map((c) => c.id),
        containsAll(['b-kubus', 'sp-kubus']),
      );
    });

    test(
      'single candidate with the same normalized name stays resolved',
      () async {
        await database
            .into(database.storyScenes)
            .insert(
              StoryScenesCompanion.insert(
                id: 'scene-4',
                storyId: 'story-1',
                chapterId: 'ch-1',
                title: 'Menara',
                sceneNumber: 4,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
        await storyRepo.saveSceneDraft('scene-4', 'Tautan [[  api  ]] saja.');

        const service = LoreBacklinkService();
        final report = await service.scanIntegrity(
          database,
          projectId: 'project-1',
          catalog: catalog,
        );

        final finding = report.findings.singleWhere(
          (f) => f.sourceId == 'scene-4',
        );
        expect(finding.health, LoreLinkHealth.resolved);
        expect(finding.candidates.single.id, 'sp-api');
      },
    );
  });

  group('repair_action', () {
    test('retargets every matching link across scenes', () async {
      const service = LoreBacklinkService();

      final changed = await service.retargetOccurrences(
        database,
        projectId: 'project-1',
        from: 'Naga Hilang',
        to: 'Naga Salju',
      );

      expect(changed, 1);
      expect(
        await storyRepo.getSceneDraft('scene-2'),
        '[[Api]] lagi, lalu [[Naga Salju]].',
      );
    });

    test('keeps plain text and escaped copies intact while renaming', () async {
      await database
          .into(database.storyScenes)
          .insert(
            StoryScenesCompanion.insert(
              id: 'scene-r',
              storyId: 'story-1',
              chapterId: 'ch-1',
              title: 'Ruang Tulis',
              sceneNumber: 5,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      await storyRepo.saveSceneDraft(
        'scene-r',
        'Naga Hilang polos. \\[[Naga Hilang]] dan [[Naga Hilang]] link.',
      );

      const service = LoreBacklinkService();
      // scene-2 (fixture setUp) dan scene-r sama-sama memuat [[Naga Hilang]].
      final changed = await service.retargetOccurrences(
        database,
        projectId: 'project-1',
        from: 'Naga Hilang',
        to: 'Naga Baru',
      );

      expect(changed, 2);
      expect(
        await storyRepo.getSceneDraft('scene-r'),
        'Naga Hilang polos. \\[[Naga Hilang]] dan [[Naga Baru]] link.',
      );
    });

    test(
      'returns zero and keeps content identical when nothing matches',
      () async {
        const service = LoreBacklinkService();

        final before = await storyRepo.getSceneDraft('scene-1');
        final changed = await service.retargetOccurrences(
          database,
          projectId: 'project-1',
          from: 'Tidak Ada',
          to: 'X',
        );

        expect(changed, 0);
        expect(await storyRepo.getSceneDraft('scene-1'), before);
      },
    );

    test('no-ops when from equals to', () async {
      const service = LoreBacklinkService();

      final changed = await service.retargetOccurrences(
        database,
        projectId: 'project-1',
        from: 'Api',
        to: 'Api',
      );

      expect(changed, 0);
    });

    test('retarget does not mutate another project', () async {
      await database
          .into(database.stories)
          .insert(
            StoriesCompanion.insert(
              assetId: 'story-2',
              projectId: 'project-2',
              title: 'Saga Lain',
            ),
          );
      await database
          .into(database.storyScenes)
          .insert(
            StoryScenesCompanion.insert(
              id: 'scene-other-project',
              storyId: 'story-2',
              chapterId: 'ch-other',
              title: 'Scene lain',
              sceneNumber: 1,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      await database
          .into(database.sceneBeats)
          .insert(
            SceneBeatsCompanion.insert(
              id: 'beat-other-project',
              sceneId: 'scene-other-project',
              content: '[[Naga Hilang]]',
            ),
          );

      const service = LoreBacklinkService();
      final changed = await service.retargetOccurrences(
        database,
        projectId: 'project-1',
        from: 'Naga Hilang',
        to: 'Naga Baru',
      );

      expect(changed, 1);
      final other = await (database.select(
        database.sceneBeats,
      )..where((row) => row.id.equals('beat-other-project'))).getSingle();
      expect(other.content, '[[Naga Hilang]]');
    });

    test(
      'scan -> retarget -> rescan closes the broken link end to end',
      () async {
        const service = LoreBacklinkService();

        final initial = await service.scanIntegrity(
          database,
          projectId: 'project-1',
          catalog: catalog,
        );
        expect(initial.brokenLinks, isNotEmpty);
        expect(initial.isClean, isFalse);

        final changed = await service.retargetOccurrences(
          database,
          projectId: 'project-1',
          from: 'Naga Hilang',
          to: 'Naga Salju',
        );
        expect(changed, 1);

        final healed = await service.scanIntegrity(
          database,
          projectId: 'project-1',
          catalog: catalog,
        );
        expect(healed.brokenLinks, isEmpty);
        expect(healed.isClean, isTrue);
        expect(healed.findings, hasLength(3));
      },
    );
  });
}
