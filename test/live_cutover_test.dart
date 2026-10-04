import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_file_namespace.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_migration_runner.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_projection_cache.dart';

// Operator-gated live cutover (G4, ADR-WS-001). NEVER runs in the ordinary
// suite: the body is a no-op unless VOID_SCRIPTOR_LIVE_CUTOVER=1.
//
//   VOID_SCRIPTOR_LIVE_CUTOVER=1 flutter test test/live_cutover_test.dart
void main() {
  test('live cutover: Test Novel package → typed workspaces', () async {
    if (Platform.environment['VOID_SCRIPTOR_LIVE_CUTOVER'] != '1') {
      return; // no-op in the ordinary suite
    }
    const packageRoot =
        '/home/nepht/VoidScriptor/Projects/778f5427-9019-4dd9-9fad-f3b96733d5c1.voidproject';
    const projectId = '778f5427-9019-4dd9-9fad-f3b96733d5c1';
    const legacyStoryId = '7335a9f2-0f5c-4adc-8e41-bcc55277b3c8';
    const novelWorkspaceId = 'novel-main';

    final package = ProjectPackage(
      projectId: projectId,
      root: Directory(packageRoot),
    );
    final database = await ProjectDatabaseService().open(
      package.databaseFile.path,
    );
    try {
      final links = NovelCharacterLinkRepository(
        database: database,
        projectId: projectId,
      );
      final projections = WorkspaceProjectionCache(loader: links.listForNovel);
      final report =
          await WorkspaceMigrationRunner(
            package: package,
            links: links,
            backups: ProjectBackupService(),
            projections: projections,
          ).migrate(
            storyWorkspaceIds: const {legacyStoryId: novelWorkspaceId},
            characterAssignments: const [],
          );

      // Emit machine-readable evidence for the gate doc.
      void line(String name, Object value) => stdout.writeln('$name=$value');
      line('backupCreated', report.backupCreated);
      line('inventoriedStories', report.inventoriedStories);
      line('inventoriedCharacters', report.inventoriedCharacters);
      line('copiedStoryFiles', report.copiedStoryFiles);
      line('copiedCharacterFiles', report.copiedCharacterFiles);
      line('createdLinks', report.createdLinks);
      line('validatedCounts', report.validatedCounts);
      line('projectionRebuilt', report.projectionRebuilt);
      line('rollbackDrillPassed', report.rollbackDrillPassed);

      expect(report.backupCreated, isTrue);
      expect(report.validatedCounts, isTrue);
      expect(report.rollbackDrillPassed, isTrue);
      expect(
        Directory(
          '${Directory(packageRoot).path}/workspaces/novels/$novelWorkspaceId',
        ).existsSync(),
        isTrue,
      );
      expect(
        WorkspaceFileNamespace.isValidWorkspaceIdentifier(novelWorkspaceId),
        isTrue,
      );
    } finally {
      await database.close();
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
