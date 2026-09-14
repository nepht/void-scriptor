import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_migration_runner.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_projection_cache.dart';

// vs-hunt-20260914-workspaces BUG-6 (run310). Referee verdict: the runner
// discards the Directory returned by backups.create and _runRollbackDrill
// re-discovers a backup by lexicographic path ordering. Backup ids are UUID
// v4, so that ordering is neither creation order nor identity. With more than
// one backup on disk the drill can restore the wrong snapshot and report a
// result unrelated to this migration's pre-state.
//
// Fix direction (referee): capture the exact Directory returned by
// backups.create, pass it to the drill, and add an existence/manifest
// identity check instead of rediscovering backups from the directory listing.
class _ControlledBackupService {
  _ControlledBackupService({required this.backupId, this.materialize = true});

  final String backupId;

  /// When false the service reports a backup directory it never wrote,
  /// simulating a lost or corrupted backup artifact.
  final bool materialize;
  int calls = 0;

  Future<Directory> create({
    required ProjectPackage package,
    required String type,
    String note = '',
    Directory? destinationRoot,
  }) async {
    calls++;
    final root = destinationRoot ?? package.backupDirectory;
    final target = Directory(p.join(root.path, backupId));
    if (!materialize) return target;
    await target.create(recursive: true);
    final liveWorkspaces = Directory(p.join(package.root.path, 'workspaces'));
    if (await liveWorkspaces.exists()) {
      await for (final entity in liveWorkspaces.list(recursive: true)) {
        final relative = p.relative(entity.path, from: liveWorkspaces.path);
        final copied = p.join(target.path, 'workspaces', relative);
        if (entity is Directory) {
          await Directory(copied).create(recursive: true);
        } else if (entity is File) {
          final file = File(copied);
          await file.parent.create(recursive: true);
          await entity.copy(file.path);
        }
      }
    }
    await File(p.join(target.path, 'backup.json')).writeAsString(
      jsonEncode({
        'id': backupId,
        'projectId': package.projectId,
        'type': type,
        'note': note,
      }),
    );
    return target;
  }
}

void main() {
  late Directory root;

  setUp(
    () async => root = await Directory.systemTemp.createTemp('ws-mig-run310-'),
  );
  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  Future<
    ({
      ProjectPackage package,
      NovelCharacterLinkRepository links,
      WorkspaceMigrationRunner Function(_ControlledBackupService backups)
      runner,
    })
  >
  harness(String projectName) async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: projectName);
    final database = await ProjectDatabaseService().open(
      package.databaseFile.path,
    );
    addTearDown(database.close);
    final links = NovelCharacterLinkRepository(
      database: database,
      projectId: package.projectId,
    );
    WorkspaceMigrationRunner build(_ControlledBackupService backups) =>
        WorkspaceMigrationRunner(
          package: package,
          links: links,
          backups: backups,
          projections: WorkspaceProjectionCache(loader: links.listForNovel),
        );
    return (package: package, links: links, runner: build);
  }

  File legacyStoryFile(ProjectPackage package, String storyId, String name) {
    final file = File('${package.assetsDirectory.path}/stories/$storyId/$name')
      ..parent.createSync(recursive: true);
    return file;
  }

  test('BUG-6: the rollback drill restores the exact backup taken by this '
      'migration, not the lexicographically last backup on disk', () async {
    final h = await harness('Wrong Backup Selection');
    legacyStoryFile(
      h.package,
      'story-1',
      'manuscript.md',
    ).writeAsStringSync('# Story');
    // A pre-existing unrelated backup whose name sorts AFTER the migration
    // backup (UUID ordering is arbitrary), holding workspace content that is
    // NOT this migration's pre-state.
    final stale = Directory(
      p.join(h.package.backupDirectory.path, 'ffff-preexisting-backup'),
    )..createSync(recursive: true);
    File(
      p.join(stale.path, 'workspaces', 'stale.txt'),
    ).createSync(recursive: true);
    File(
      p.join(stale.path, 'workspaces', 'stale.txt'),
    ).writeAsStringSync('UNRELATED-LATER-BACKUP');

    final backups = _ControlledBackupService(backupId: '0000-migration-backup');
    final report = await h
        .runner(backups)
        .migrate(
          storyWorkspaceIds: const {'story-1': 'story-1'},
          characterAssignments: const [],
        );

    expect(backups.calls, 1);
    // Lexicographic rediscovery would pick ffffff-preexisting-backup and
    // restore stale.txt into the drill, failing the drill. The runner must
    // use the exact Directory it created (empty workspaces pre-state).
    expect(
      report.rollbackDrillPassed,
      isTrue,
      reason:
          'the drill must restore the captured pre-migration backup, not a '
          'lexicographically later unrelated backup',
    );
    // The unrelated backup is untouched.
    expect(
      File(p.join(stale.path, 'workspaces', 'stale.txt')).existsSync(),
      isTrue,
    );
  });

  test(
    'BUG-6 identity guard: a backup directory that was never materialized '
    'fails the drill instead of silently restoring another snapshot',
    () async {
      final h = await harness('Lost Backup');
      legacyStoryFile(
        h.package,
        'story-1',
        'manuscript.md',
      ).writeAsStringSync('# Story');
      // A different, complete backup exists on disk. Old code would
      // rediscover it and report a passing drill even though THIS
      // migration's backup vanished.
      final other = Directory(
        p.join(h.package.backupDirectory.path, 'aaaaaaaa-other-backup'),
      )..createSync(recursive: true);
      Directory(p.join(other.path, 'workspaces')).createSync(recursive: true);
      await File(
        p.join(other.path, 'backup.json'),
      ).writeAsString(jsonEncode({'id': 'aaaaaaaa-other-backup'}));

      final backups = _ControlledBackupService(
        backupId: 'bbbb-migration-backup',
        materialize: false,
      );
      final report = await h
          .runner(backups)
          .migrate(
            storyWorkspaceIds: const {'story-1': 'story-1'},
            characterAssignments: const [],
          );

      expect(backups.calls, 1);
      expect(
        report.rollbackDrillPassed,
        isFalse,
        reason:
            'a missing captured backup must fail the drill; falling back to '
            'any other backup directory hides a broken recovery path',
      );
    },
  );
}
