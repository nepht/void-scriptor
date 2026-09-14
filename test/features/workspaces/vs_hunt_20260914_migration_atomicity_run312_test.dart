import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_migration_runner.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_projection_cache.dart';
import 'package:void_scriptor/features/workspaces/domain/novel_character_link.dart';

// vs-hunt-20260914-workspaces BUG-1 (High) + BUG-5 (Medium), run312.
// Referee verdict (referee_report_workspaces_run308.md): the migration
// mutates filesystem and database after the backup with no transaction and no
// compensation — a later copy failure, link-insert conflict, or checksum
// mismatch leaves earlier copied directories and earlier inserted links behind,
// and a failed verification only flips `validatedCounts` while the runner
// still returns a success-shaped report.
//
// Fix direction enforced here: DB link writes run inside one database
// transaction; filesystem output installed by the run is compensated (deleted)
// on any failure; verification is a gate that throws; the rollback drill runs
// BEFORE any mutation so a broken backup aborts a pristine package; the
// pre-migration backup is always retained.
void main() {
  late Directory root;

  setUp(
    () async => root = await Directory.systemTemp.createTemp('ws-mig-run312-'),
  );
  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  Future<
    ({
      ProjectPackage package,
      NovelCharacterLinkRepository links,
      WorkspaceMigrationRunner runner,
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
    final runner = WorkspaceMigrationRunner(
      package: package,
      links: links,
      backups: ProjectBackupService(),
      projections: WorkspaceProjectionCache(loader: links.listForNovel),
    );
    return (package: package, links: links, runner: runner);
  }

  File legacyStoryFile(ProjectPackage package, String storyId, String name) {
    final file = File('${package.assetsDirectory.path}/stories/$storyId/$name')
      ..parent.createSync(recursive: true);
    file.writeAsStringSync('# $storyId body');
    return file;
  }

  File legacyCharacterFile(ProjectPackage package, String id, String name) {
    final file = File('${package.assetsDirectory.path}/characters/$id/$name')
      ..parent.createSync(recursive: true);
    file.writeAsStringSync('{"name":"$id"}');
    return file;
  }

  test('BUG-1: a filesystem copy failure mid-migration compensates earlier '
      'copied workspaces, leaves no links, and retains the backup', () async {
    final h = await harness('Copy Failure');
    legacyStoryFile(h.package, 'story-1', 'manuscript.md');
    legacyStoryFile(h.package, 'story-2', 'manuscript.md');
    // story-2's typed target is occupied by a FILE, so creating that
    // workspace directory fails after story-1 was already copied.
    File(
      p.join(h.package.root.path, 'workspaces', 'novels', 'story-2'),
    ).createSync(recursive: true);

    Object? failure;
    try {
      await h.runner.migrate(
        storyWorkspaceIds: const {'story-1': 'story-1', 'story-2': 'story-2'},
        characterAssignments: const [],
      );
    } catch (error) {
      failure = error;
    }
    expect(
      failure,
      isA<WorkspaceMigrationFailure>(),
      reason:
          'a mid-migration filesystem failure must surface as the '
          'documented compensation failure, not a raw FileSystemException',
    );
    final migrationFailure = failure! as WorkspaceMigrationFailure;
    expect(migrationFailure.stage, 'copy');
    // story-1 was copied before the throw; it must not remain.
    expect(
      Directory(
        p.join(h.package.root.path, 'workspaces', 'novels', 'story-1'),
      ).existsSync(),
      isFalse,
      reason: 'BUG-1: earlier copied typed workspaces must be compensated',
    );
    expect(
      await h.links.listForNovel('story-1'),
      isEmpty,
      reason: 'links must never exist while the copy set is incomplete',
    );
    // Legacy sources are untouched and the pre-migration backup is retained.
    expect(
      File(
        p.join(
          h.package.assetsDirectory.path,
          'stories',
          'story-1',
          'manuscript.md',
        ),
      ).existsSync(),
      isTrue,
    );
    expect(
      await Directory(h.package.backupDirectory.path).list().length,
      greaterThanOrEqualTo(1),
      reason: 'the pre-migration backup must be retained for recovery',
    );
  });

  test('BUG-1: a colliding link insert rolls back the whole link set — '
      'no earlier inserted link survives without the later one', () async {
    final h = await harness('Link Conflict');
    legacyStoryFile(h.package, 'story-1', 'manuscript.md');
    legacyStoryFile(h.package, 'story-2', 'manuscript.md');
    legacyCharacterFile(h.package, 'char-2', 'profile.json');
    legacyCharacterFile(h.package, 'char-1', 'profile.json');
    // Pre-existing link occupies the deterministic id of the SECOND
    // assignment, so the first insert commits (at HEAD) and the second
    // throws — exactly the partial-state window BUG-1 describes.
    await h.links.create(
      NovelCharacterLink.create(
        linkId: 'migration-story-1-char-1',
        novelWorkspaceId: 'story-1',
        characterWorkspaceId: 'char-1',
        characterId: 'char-1',
        role: 'migrated',
        visibility: 'visible',
      ),
    );

    Object? failure;
    try {
      await h.runner.migrate(
        storyWorkspaceIds: const {'story-1': 'story-1', 'story-2': 'story-2'},
        characterAssignments: const [
          CharacterNovelAssignment(
            characterId: 'char-2',
            novelWorkspaceId: 'story-2',
          ),
          CharacterNovelAssignment(
            characterId: 'char-1',
            novelWorkspaceId: 'story-1',
          ),
        ],
      );
    } catch (error) {
      failure = error;
    }
    expect(
      failure,
      isA<WorkspaceMigrationFailure>(),
      reason:
          'a link-insert conflict must surface as WorkspaceMigrationFailure',
    );
    expect((failure! as WorkspaceMigrationFailure).stage, 'database');
    expect(
      await h.links.listForNovel('story-2'),
      isEmpty,
      reason:
          'BUG-1: the link for the successful earlier assignment must be '
          'rolled back with the failed one (single database transaction)',
    );
    expect(
      Directory(
        p.join(h.package.root.path, 'workspaces', 'novels', 'story-1'),
      ).existsSync(),
      isFalse,
    );
    expect(
      Directory(
        p.join(h.package.root.path, 'workspaces', 'characters', 'char-2'),
      ).existsSync(),
      isFalse,
      reason: 'filesystem output must be compensated when the DB fails',
    );
    expect(
      File(
        p.join(
          h.package.root.path,
          'workspaces',
          'novels',
          'story-1',
          'legacy',
          'manuscript.md',
        ),
      ).existsSync(),
      isFalse,
    );
  });

  test('BUG-5: a failed copy verification aborts the migration instead of '
      'returning a success-shaped report with committed links', () async {
    final h = await harness('Verify Failure');
    legacyStoryFile(h.package, 'story-1', 'manuscript.md');
    // Pre-existing content in the target's legacy namespace makes the
    // verified file count differ from the source count.
    final preexisting = File(
      p.join(
        h.package.root.path,
        'workspaces',
        'novels',
        'story-1',
        'legacy',
        'pre-existing.txt',
      ),
    )..createSync(recursive: true);
    preexisting.writeAsStringSync('mine');

    Object? failure;
    try {
      await h.runner.migrate(
        storyWorkspaceIds: const {'story-1': 'story-1'},
        characterAssignments: const [],
      );
    } catch (error) {
      failure = error;
    }
    expect(
      failure,
      isA<WorkspaceMigrationFailure>(),
      reason:
          'BUG-5: a validation mismatch must be a failure, not a '
          'validatedCounts:false success report',
    );
    expect((failure! as WorkspaceMigrationFailure).stage, 'verification');
    expect(
      await h.links.listForNovel('story-1'),
      isEmpty,
      reason: 'links must not be committed for unverified copies',
    );
    expect(
      File(
        p.join(
          h.package.root.path,
          'workspaces',
          'novels',
          'story-1',
          'legacy',
          'manuscript.md',
        ),
      ).existsSync(),
      isFalse,
      reason: 'files installed by the failed run must be compensated',
    );
    expect(
      preexisting.existsSync(),
      isTrue,
      reason: 'compensation must only remove what this run installed',
    );
  });
}
