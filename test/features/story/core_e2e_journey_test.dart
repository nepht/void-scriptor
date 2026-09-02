// Sprint 145.41 - Core Automated Test Pyramid: minimum end-to-end vertical
// journey on a clean, isolated environment (temp root, real SQLite, real
// filesystem). Create -> author -> search -> quick ref -> export ->
// backup -> restore -> reopen, without touching user data locations.
// Headless storage journey: no widgets are pumped, so a plain test() with
// real async I/O is the correct pyramid layer here.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/character/domain/character_identity_profile.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/application/story_txt_exporter.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

void main() {
  test(
    'core e2e: create novel, write, search, quick ref, export, backup, restore',
    () async {
      final tempRoot = await Directory.systemTemp.createTemp('s41-e2e-');
      final packageRoot = Directory('${tempRoot.path}/projects');
      final package = await ProjectPackageService(
        rootDirectory: packageRoot,
      ).create(name: 'E2E Journey');
      final session = await ProjectSessionManager().open(package);
      addTearDown(() async {
        // Sessions/databases are closed inside the journey itself; the
        // teardown only removes the isolated temp root. Windows can keep a
        // handle briefly after close, so deletion failures are not fatal.
        try {
          if (await tempRoot.exists()) {
            await tempRoot.delete(recursive: true);
          }
        } catch (_) {}
      });
      final db = session.database;
      final projectId = package.projectId;

      // 1. Build: character with canon profile + identity notes, story tree.
      final characterRepo = CharacterRepositoryImpl(
        database: db,
        projectId: projectId,
        paths: ProjectPaths(rootDirectory: packageRoot),
      );
      final character = await characterRepo.createCharacter(name: 'Qowner');
      await characterRepo.updateCharacter(
        character.copyWith(
          biography: 'Arsitek Void Scriptor.',
          voice: 'Tenang dan berwibawa.',
        ),
      );
      final identity = await characterRepo.getIdentity(character.assetId);
      await characterRepo.updateIdentity(
        (identity ?? CharacterIdentityProfile(characterId: character.assetId))
            .copyWith(notes: 'Ledger: catatan identitas privat.'),
      );

      final storyService = CreateStoryService(
        database: db,
        paths: ProjectPaths(rootDirectory: packageRoot),
      );
      final storyId = await storyService.createStory(
        projectId: projectId,
        title: 'Void Cube Saga',
      );
      final arcId = await storyService.createArc(
        storyId: storyId,
        title: 'Act I',
      );
      final chapterId = await storyService.createChapter(
        storyId: storyId,
        arcId: arcId,
        title: 'Bab 1 - Pole of Creation',
        chapterNumber: 1,
      );
      final sceneId = await storyService.createScene(
        storyId: storyId,
        chapterId: chapterId,
        title: 'Panggilan Void di Kutub',
        sceneNumber: 1,
      );
      await storyService.addCharacter(
        sceneId: sceneId,
        characterId: character.assetId,
      );

      // 2. Author + autosave durability: persisted draft is readable back.
      final storyRepo = StoryRepositoryImpl(database: db, projectId: projectId);
      const draft = 'Qowner memanggil kubus dari void. Tenang, tanpa suara.';
      await storyRepo.saveSceneDraft(sceneId, draft);
      expect(await storyRepo.getSceneDraft(sceneId), draft);

      // 3. Search across the novel (case-insensitive, trim, cross-scene).
      final hits = await storyRepo.searchNovel('  void ');
      expect(hits, hasLength(1));
      expect(hits.single.sceneId, sceneId);
      expect(hits.single.chapterTitle, 'Bab 1 - Pole of Creation');
      expect(hits.single.matchCount, 2);
      expect(await storyRepo.searchNovel('   '), isEmpty);

      // 4. Quick reference: canon profile + identity notes + scene role.
      final quickRefs = await storyRepo.quickReferenceForScene(sceneId);
      expect(quickRefs, hasLength(1));
      expect(quickRefs.single.name, 'Qowner');
      expect(quickRefs.single.compactDescription, contains('Voice: Tenang'));
      expect(
        quickRefs.single.compactDescription,
        contains('catatan identitas privat'),
      );

      // 5. Export clean manuscript TXT.
      const exporter = StoryTxtExporter();
      final manuscript = await exporter.exportStory(storyRepo, storyId);
      expect(manuscript, contains('Void Cube Saga'));
      expect(manuscript, contains('Bab 1 - Pole of Creation'));
      expect(manuscript, contains(draft));

      // 6. Close the live session before backup; copying an open WAL is unsafe.
      await session.close();

      // 7. Backup with SHA-256 manifest, then mutate the live package.
      final backupService = ProjectBackupService();
      final backup = await backupService.create(
        package: package,
        type: 'manual',
        note: 'before restore journey',
      );
      expect(await backup.exists(), isTrue);
      final metadata =
          jsonDecode(await File('${backup.path}/backup.json').readAsString())
              as Map<String, dynamic>;
      expect(metadata['type'], 'manual');
      expect(
        (metadata['files'] as Map).keys,
        containsAll(['project.json', 'project.db']),
      );

      final dirtyDb = await ProjectDatabaseService().open(
        package.databaseFile.path,
      );
      await CreateStoryService(
        database: dirtyDb,
        paths: ProjectPaths(rootDirectory: packageRoot),
      ).createStory(projectId: package.projectId, title: 'DIRTY');
      await dirtyDb.close();

      // 8. Restore: checksum-verified rollback removes post-backup rows.
      await backupService.restore(package: package, backup: backup);
      final reopened = await ProjectDatabaseService().open(
        package.databaseFile.path,
      );
      final restoredStories = await reopened.select(reopened.stories).get();
      await reopened.close();
      final titles = restoredStories.map((s) => s.title).toSet();
      expect(titles, contains('Void Cube Saga'));
      expect(titles, isNot(contains('DIRTY')));

      // 9. Reopen through the session manager; hierarchy resolves intact.
      final reopenedSession = await ProjectSessionManager().open(package);
      final reopenedRepo = StoryRepositoryImpl(
        database: reopenedSession.database,
        projectId: reopenedSession.package.projectId,
      );
      final hierarchy = await reopenedRepo.getStoryHierarchy(storyId);
      expect(hierarchy.story.title, 'Void Cube Saga');
      expect(hierarchy.chapters.single.title, 'Bab 1 - Pole of Creation');
      expect(
        await reopenedRepo.getSceneDraft(
          hierarchy.chapters.single.scenes.single.id,
        ),
        draft,
      );
      await reopenedSession.close();
    },
  );
}
