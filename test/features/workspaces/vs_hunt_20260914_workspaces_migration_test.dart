import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_migration_runner.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_projection_cache.dart';

// vs-hunt-20260914-workspaces (run308). Referee verdicts BUG-2/3/4 are REAL;
// this slice enforces pre-mutation validation in WorkspaceMigrationRunner:
//  - BUG-2: legacy trees containing symlinked content are refused; traversal
//    never follows links into bytes outside the package.
//  - BUG-3: one character may be assigned to two different mapped novels;
//    duplicate detection is keyed by (novelWorkspaceId, characterId) pairs.
//  - BUG-4: two legacy story IDs mapping to one target Novel workspace would
//    merge directories; duplicate targets and deterministic link-ID collisions
//    are rejected before any backup or mutation.
void main() {
  late Directory root;

  setUp(
    () async => root = await Directory.systemTemp.createTemp('ws-mig-run308-'),
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

  Future<int> backupCount(ProjectPackage package) async {
    if (!await package.backupDirectory.exists()) return 0;
    var count = 0;
    await for (final _ in package.backupDirectory.list()) {
      count++;
    }
    return count;
  }

  File legacyStoryFile(ProjectPackage package, String storyId, String name) {
    final file = File('${package.assetsDirectory.path}/stories/$storyId/$name')
      ..parent.createSync(recursive: true);
    return file;
  }

  File legacyCharacterFile(ProjectPackage package, String characterId) {
    final file = File(
      '${package.assetsDirectory.path}/characters/$characterId/profile.json',
    )..parent.createSync(recursive: true);
    return file;
  }

  test('BUG-2: refuses migration when legacy content contains a symlink '
      'before any backup or mutation', () async {
    final h = await harness('Symlink Guard');
    final manuscript = legacyStoryFile(h.package, 'story-1', 'manuscript.md')
      ..writeAsStringSync('# Story');
    expect(manuscript.existsSync(), isTrue);
    final outside = File('${root.path}/outside-r308.txt')
      ..writeAsStringSync('OUTSIDE-PACKAGE-BYTES');
    final inLegacy = Link(
      '${h.package.assetsDirectory.path}/stories/story-1/escape.txt',
    );
    try {
      inLegacy.createSync(outside.path);
    } catch (e) {
      // Some Windows setups deny unprivileged symlink creation; skip the
      // case honestly instead of pretending it passed.
      stderr.writeln('SKIP BUG-2: symlink creation failed: $e');
      return;
    }

    await expectLater(
      h.runner.migrate(
        storyWorkspaceIds: const {'story-1': 'story-1'},
        characterAssignments: const [],
      ),
      throwsA(isA<ArgumentError>()),
    );
    // Rejected pre-mutation: no typed workspace tree, no backup, no links.
    expect(
      await Directory('${h.package.root.path}/workspaces').exists(),
      isFalse,
    );
    expect(await backupCount(h.package), 0);
    expect(await h.links.listForNovel('story-1'), isEmpty);
  });

  test('BUG-3: the same character assigned to two different mapped novels '
      'migrates as two independent links', () async {
    final h = await harness('Cross Novel Character');
    legacyCharacterFile(
      h.package,
      'char-1',
    ).writeAsStringSync('{"name":"Qowner"}');

    final report = await h.runner.migrate(
      storyWorkspaceIds: const {'story-1': 'novel-a', 'story-2': 'novel-b'},
      characterAssignments: const [
        CharacterNovelAssignment(
          characterId: 'char-1',
          novelWorkspaceId: 'novel-a',
        ),
        CharacterNovelAssignment(
          characterId: 'char-1',
          novelWorkspaceId: 'novel-b',
        ),
      ],
    );

    expect(report.createdLinks, 2);
    // One legacy character directory was copied once, not twice.
    expect(report.copiedCharacterFiles, 1);
    expect(
      (await h.links.listForNovel('novel-a')).single.characterId,
      'char-1',
    );
    expect(
      (await h.links.listForNovel('novel-b')).single.characterId,
      'char-1',
    );
    expect(report.validatedCounts, isTrue);
  });

  test('BUG-3 guard: a duplicated (novel, character) pair is still rejected '
      'before mutating anything', () async {
    final h = await harness('Duplicate Pair');
    await expectLater(
      h.runner.migrate(
        storyWorkspaceIds: const {'story-1': 'novel-a'},
        characterAssignments: const [
          CharacterNovelAssignment(
            characterId: 'char-1',
            novelWorkspaceId: 'novel-a',
          ),
          CharacterNovelAssignment(
            characterId: 'char-1',
            novelWorkspaceId: 'novel-a',
          ),
        ],
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(await backupCount(h.package), 0);
    expect(await h.links.listForNovel('novel-a'), isEmpty);
  });

  test('BUG-4: two legacy story IDs mapped to one target novel workspace are '
      'rejected before any backup or mutation', () async {
    final h = await harness('Duplicate Target');
    await expectLater(
      h.runner.migrate(
        storyWorkspaceIds: const {
          'story-1': 'novel-main',
          'story-2': 'novel-main',
        },
        characterAssignments: const [],
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      await Directory('${h.package.root.path}/workspaces').exists(),
      isFalse,
    );
    expect(await backupCount(h.package), 0);
  });

  test('BUG-4 guard: dash-ambiguous IDs producing one deterministic link ID '
      'are rejected before mutation', () async {
    final h = await harness('Link Id Collision');
    legacyCharacterFile(h.package, 'b-c').writeAsStringSync('{"name":"x"}');
    legacyCharacterFile(h.package, 'c').writeAsStringSync('{"name":"y"}');

    await expectLater(
      h.runner.migrate(
        storyWorkspaceIds: const {'s1': 'a-b', 's2': 'a'},
        characterAssignments: const [
          CharacterNovelAssignment(characterId: 'c', novelWorkspaceId: 'a-b'),
          CharacterNovelAssignment(characterId: 'b-c', novelWorkspaceId: 'a'),
        ],
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(await backupCount(h.package), 0);
  });
}
