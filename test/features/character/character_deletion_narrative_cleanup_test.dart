import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/workspaces/application/narrative_assignment_repository.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';

/// Regression for bug-hunt run157 BUG-02 (hunt-ID `void-scriptor-hunt-20260909
/// BUG-02`, Medium, Referee verdict REAL BUG): `deleteForCharacter` existed
/// with a doc claiming "Used by character deletion cleanup" but had ZERO
/// production callers — deleting a character permanently orphaned its rows in
/// `character_narrative_assignments` and `character_support_relationships`
/// (no FKs, no cascade), surfacing as raw-UUID entries on other characters'
/// sections and riding along in export/import.
///
/// The RED here reproduces the exact mechanism: a real character deletion
/// through `CharacterRepositoryImpl.deleteCharacter` must leave NO narrative
/// rows behind, while the other character's rows stay untouched.
void main() {
  test('deleting a character removes its narrative assignment rows', () async {
    final root = await Directory.systemTemp.createTemp('del-narr-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final service = ProjectDatabaseService();
    final dbFile = await paths.database('project-1');
    await service.create(dbFile.path);
    final db = await service.open(dbFile.path);
    addTearDown(db.close);

    final characters = CharacterRepositoryImpl(
      database: db,
      projectId: 'project-1',
      paths: paths,
    );
    final narrative = NarrativeAssignmentRepository(
      database: db,
      projectId: 'project-1',
    );

    final qowner = await characters.createCharacter(name: 'Qowner');
    final lyra = await characters.createCharacter(name: 'Lyra');

    await narrative.saveAssignment(
      NarrativeAssignment(
        novelWorkspaceId: 'novel-a',
        characterId: qowner.assetId,
        roles: {NarrativeRole.protagonist},
        importance: NarrativeImportance.major,
        pov: NarrativePov.yes,
      ),
    );
    await narrative.saveAssignment(
      NarrativeAssignment(
        novelWorkspaceId: 'novel-b',
        characterId: lyra.assetId,
        roles: {NarrativeRole.supporting},
      ),
    );

    await characters.deleteCharacter(qowner.assetId);

    // Ground truth through a fresh close/reopen, not just in-process state.
    await db.close();
    final reopened = await service.open(dbFile.path);
    addTearDown(reopened.close);
    final after = NarrativeAssignmentRepository(
      database: reopened,
      projectId: 'project-1',
    );

    final remaining = await after.listAssignments();
    expect(
      remaining.map((assignment) => assignment.characterId),
      isNot(contains(qowner.assetId)),
      reason: 'BUG-02: assignment rows survive character deletion (orphan)',
    );
    expect(remaining.map((a) => a.characterId), [lyra.assetId]);
    expect(
      await after.getAssignment(
        novelWorkspaceId: 'novel-b',
        characterId: lyra.assetId,
      ),
      isNotNull,
      reason: 'cleanup must not touch the other character',
    );
  });

  test(
    'deleting a character removes support rows as source AND target',
    () async {
      final root = await Directory.systemTemp.createTemp('del-support-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final service = ProjectDatabaseService();
      final dbFile = await paths.database('project-1');
      await service.create(dbFile.path);
      final db = await service.open(dbFile.path);
      addTearDown(db.close);

      final characters = CharacterRepositoryImpl(
        database: db,
        projectId: 'project-1',
        paths: paths,
      );
      final narrative = NarrativeAssignmentRepository(
        database: db,
        projectId: 'project-1',
      );

      final qowner = await characters.createCharacter(name: 'Qowner');
      final lyra = await characters.createCharacter(name: 'Lyra');
      final dinoq = await characters.createCharacter(name: 'Dinoq');

      // Qowner supports Lyra (Qowner is the source) and is supported by
      // Dinoq (Qowner is the target). Deleting Qowner must clear BOTH.
      await narrative.saveSupport(
        SupportRelationship(
          sourceCharacterId: qowner.assetId,
          supportedId: lyra.assetId,
          storyNovelWorkspaceId: 'novel-a',
          type: SupportType.protector,
          duration: SupportDuration.permanent,
        ),
      );
      await narrative.saveSupport(
        SupportRelationship(
          sourceCharacterId: dinoq.assetId,
          supportedId: qowner.assetId,
          storyNovelWorkspaceId: 'novel-a',
          type: SupportType.mentor,
          duration: SupportDuration.temporary,
        ),
      );
      // Lyra <-> Dinoq must survive untouched.
      await narrative.saveSupport(
        SupportRelationship(
          sourceCharacterId: lyra.assetId,
          supportedId: dinoq.assetId,
          storyNovelWorkspaceId: 'novel-a',
          type: SupportType.informant,
        ),
      );

      await characters.deleteCharacter(qowner.assetId);

      await db.close();
      final reopened = await service.open(dbFile.path);
      addTearDown(reopened.close);
      final after = NarrativeAssignmentRepository(
        database: reopened,
        projectId: 'project-1',
      );

      expect(
        await after.listSupports(qowner.assetId),
        isEmpty,
        reason: 'BUG-02: rows where the deleted character is source survive',
      );
      expect(
        await after.listSupportsFor(qowner.assetId),
        isEmpty,
        reason: 'BUG-02: rows where the deleted character is target survive',
      );
      final survivors = await after.listSupports(lyra.assetId);
      expect(survivors, hasLength(1));
      expect(survivors.single.supportedId, dinoq.assetId);
    },
  );
}
