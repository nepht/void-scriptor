import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_migration_runner.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_projection_cache.dart';

void main() {
  late Directory root;

  setUp(
    () async => root = await Directory.systemTemp.createTemp('ws-migration-'),
  );
  tearDown(() => root.delete(recursive: true));

  test(
    'migrates mixed storage into typed workspaces with verified rollback drill',
    () async {
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Migration');
      final manuscript = File(
        '${package.assetsDirectory.path}/stories/story-1/manuscript.md',
      )..parent.createSync(recursive: true);
      await manuscript.writeAsString('# Story');
      final profile = File(
        '${package.assetsDirectory.path}/characters/char-1/profile.json',
      )..parent.createSync(recursive: true);
      await profile.writeAsString('{"name":"Qowner"}');
      final database = await ProjectDatabaseService().open(
        package.databaseFile.path,
      );
      addTearDown(database.close);
      final links = NovelCharacterLinkRepository(
        database: database,
        projectId: package.projectId,
      );

      final projections = WorkspaceProjectionCache(loader: links.listForNovel);
      final report =
          await WorkspaceMigrationRunner(
            package: package,
            links: links,
            backups: ProjectBackupService(),
            projections: projections,
          ).migrate(
            storyWorkspaceIds: const {'story-1': 'story-1'},
            characterAssignments: const [
              CharacterNovelAssignment(
                characterId: 'char-1',
                novelWorkspaceId: 'story-1',
              ),
            ],
          );

      expect(report.backupCreated, isTrue);
      expect(report.inventoriedStories, ['story-1']);
      expect(report.inventoriedCharacters, ['char-1']);
      expect(report.copiedStoryFiles, 1);
      expect(report.copiedCharacterFiles, 1);
      expect(report.createdLinks, 1);
      expect(report.validatedCounts, isTrue);
      expect(report.projectionRebuilt, isTrue);
      expect(report.rollbackDrillPassed, isTrue);

      final migratedManuscript = File(
        '${package.root.path}/workspaces/novels/story-1/legacy/manuscript.md',
      );
      expect(await migratedManuscript.readAsString(), '# Story');
      final migratedProfile = File(
        '${package.root.path}/workspaces/characters/char-1/legacy/profile.json',
      );
      expect(await migratedProfile.readAsString(), '{"name":"Qowner"}');
      expect(await manuscript.exists(), isTrue);
      expect(await profile.exists(), isTrue);

      final link = (await links.listForNovel('story-1')).single;
      expect(link.characterWorkspaceId, 'char-1');
      expect(link.characterId, 'char-1');

      final rebuilt = await projections.forNovel('story-1');
      expect(rebuilt.links.single.linkId, link.linkId);
    },
  );

  test('rejects unsafe identifiers before mutating anything', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Unsafe Migration');
    final database = await ProjectDatabaseService().open(
      package.databaseFile.path,
    );
    addTearDown(database.close);
    final links = NovelCharacterLinkRepository(
      database: database,
      projectId: package.projectId,
    );

    await expectLater(
      WorkspaceMigrationRunner(
        package: package,
        links: links,
        backups: ProjectBackupService(),
        projections: WorkspaceProjectionCache(loader: links.listForNovel),
      ).migrate(
        storyWorkspaceIds: const {'story-1': 'story-1'},
        characterAssignments: const [
          CharacterNovelAssignment(
            characterId: '../escape',
            novelWorkspaceId: 'story-1',
          ),
        ],
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      await Directory('${package.root.path}/workspaces').exists(),
      isFalse,
    );
    expect(await links.listForNovel('story-1'), isEmpty);
    final backupEntries = <String>[];
    if (await Directory(package.backupDirectory.path).exists()) {
      await for (final entity in Directory(
        package.backupDirectory.path,
      ).list()) {
        backupEntries.add(entity.path);
      }
    }
    expect(backupEntries, isEmpty);
  });
}
