import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/project_resilience/application/portable_project_service.dart';
import 'package:void_scriptor/features/workspaces/application/narrative_assignment_repository.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';

/// Backlog `docs/backlog/character-roles-support.json` acceptance:
/// "Save/reopen and applicable import/export preserve all fields".
///
/// Exercises the REAL production portable archive path (PortableProjectExporter
/// → PortableProjectImporter over a full `.voidproject` zip) so the v60
/// `character_narrative_assignments` / `character_support_relationships` tables
/// are proven to survive export→import, including the import-as-copy project_id
/// rewrite performed by `_rewriteDatabaseProjectId`. All fixtures are
/// disposable temp projects; no user data is touched.
void main() {
  late Directory root;

  setUp(
    () async => root = await Directory.systemTemp.createTemp('hermes-narr-rt-'),
  );
  tearDown(() => root.delete(recursive: true));

  Future<(ProjectPackage, ProjectDatabase, NarrativeAssignmentRepository)>
  seedProject(String name) async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: name);
    final db = await ProjectDatabaseService().open(package.databaseFile.path);
    final now = DateTime.now();
    Future<void> seedCharacter(String id, String displayName) async {
      await db
          .into(db.assets)
          .insert(
            AssetsCompanion.insert(
              id: id,
              projectId: package.projectId,
              name: displayName,
              type: 'character',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              assetId: id,
              projectId: package.projectId,
              displayName: displayName,
            ),
          );
    }

    await seedCharacter('char-1', 'Qowner');
    await seedCharacter('char-b', 'Bram');
    await seedCharacter('char-c', 'Cakra');

    final repo = NarrativeAssignmentRepository(
      database: db,
      projectId: package.projectId,
    );
    await repo.saveAssignment(
      NarrativeAssignment(
        novelWorkspaceId: 'novel-a',
        characterId: 'char-1',
        roles: {NarrativeRole.protagonist, NarrativeRole.supporting},
        importance: NarrativeImportance.major,
        pov: NarrativePov.yes,
      ),
    );
    await repo.saveSupport(
      SupportRelationship(
        sourceCharacterId: 'char-1',
        supportedId: 'char-b',
        storyNovelWorkspaceId: 'novel-a',
        type: SupportType.protector,
        duration: SupportDuration.permanent,
      ),
    );
    await repo.saveSupport(
      SupportRelationship(
        sourceCharacterId: 'char-1',
        supportedId: 'char-c',
        storyNovelWorkspaceId: 'novel-a',
        type: SupportType.mentor,
        duration: SupportDuration.temporary,
        status: SupportStatus.separated,
        purpose: 'misi pengawal khusus',
        separationReason: 'misi selesai',
      ),
    );
    // Close BEFORE export so WAL is checkpointed into project.db and the
    // archive carries a complete database file.
    await db.close();
    return (package, db, repo);
  }

  Future<void> verifyImported(ProjectPackage imported, String projectId) async {
    final db = await ProjectDatabaseService().open(imported.databaseFile.path);
    addTearDown(db.close);
    final repo = NarrativeAssignmentRepository(
      database: db,
      projectId: projectId,
    );

    final assignment = await repo.getAssignment(
      novelWorkspaceId: 'novel-a',
      characterId: 'char-1',
    );
    expect(assignment, isNotNull);
    expect(assignment!.roles, {
      NarrativeRole.protagonist,
      NarrativeRole.supporting,
    });
    expect(assignment.importance, NarrativeImportance.major);
    expect(assignment.pov, NarrativePov.yes);

    final supports = await repo.listSupports('char-1');
    expect(supports, hasLength(2));
    final ab = supports.singleWhere((s) => s.supportedId == 'char-b');
    expect(ab.type, SupportType.protector);
    expect(ab.duration, SupportDuration.permanent);
    expect(ab.status, SupportStatus.unspecified);
    final ac = supports.singleWhere((s) => s.supportedId == 'char-c');
    expect(ac.type, SupportType.mentor);
    expect(ac.duration, SupportDuration.temporary);
    expect(ac.status, SupportStatus.separated);
    expect(ac.purpose, 'misi pengawal khusus');
    expect(ac.separationReason, 'misi selesai');
  }

  test('export → import (same identity) preserves narrative assignment and '
      'support relationships', () async {
    final (package, _, _) = await seedProject('Narrative RT Same');
    final archive = await PortableProjectExporter().exportPortable(package);
    final imported = await PortableProjectImporter().importArchive(
      archive,
      destination: Directory('${root.path}/imported'),
    );
    expect(imported.projectId, package.projectId);
    await verifyImported(imported, package.projectId);
  });

  test('export → import as copy rewrites narrative rows to the new project id '
      'with all fields intact', () async {
    final (package, _, _) = await seedProject('Narrative RT Copy');
    final archive = await PortableProjectExporter().exportPortable(package);
    final imported = await PortableProjectImporter().importArchive(
      archive,
      destination: Directory('${root.path}/copied'),
      asCopy: true,
    );
    expect(imported.projectId, isNot(package.projectId));
    await verifyImported(imported, imported.projectId);
  });
}
