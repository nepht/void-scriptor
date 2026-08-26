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

  setUp(() async => root = await Directory.systemTemp.createTemp('ws-mig-'));
  tearDown(() => root.delete(recursive: true));

  test('creates the typed novel workspace directory even when the legacy '
      'story folder is an empty scaffold', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Migration');
    // Empty scaffold: chapters live in SQLite, the documented legacy
    // location holds no files at all.
    Directory(
      '${package.assetsDirectory.path}/stories/story-1',
    ).createSync(recursive: true);
    final database = await ProjectDatabaseService().open(
      package.databaseFile.path,
    );
    addTearDown(database.close);
    final links = NovelCharacterLinkRepository(
      database: database,
      projectId: package.projectId,
    );

    final report =
        await WorkspaceMigrationRunner(
          package: package,
          links: links,
          backups: ProjectBackupService(),
          projections: WorkspaceProjectionCache(loader: links.listForNovel),
        ).migrate(
          storyWorkspaceIds: const {'story-1': 'novel-main'},
          characterAssignments: const [],
        );

    expect(report.validatedCounts, isTrue);
    expect(report.rollbackDrillPassed, isTrue);
    expect(
      Directory(
        '${package.root.path}/workspaces/novels/novel-main',
      ).existsSync(),
      isTrue,
      reason:
          'A migrated Novel must have a home on disk even when the legacy '
          'folder carried zero files.',
    );
  });
}
