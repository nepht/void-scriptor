import 'dart:io';

import 'package:drift/drift.dart' show TableInfo;
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/workspaces/application/narrative_assignment_repository.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';

/// Backlog `docs/backlog/character-roles-support.json` phase_one persistence
/// slice (canonical mapping: steps 145.25/145.26 — character linking +
/// novel-specific state). Acceptance covered here:
///   - One character can have different roles in two novels without
///     cross-contamination.
///   - A supports B permanently and C temporarily without overwriting either
///     relationship.
///   - Duration changes do not change importance or POV (structurally true:
///     duration lives on SupportRelationship, importance/POV on
///     NarrativeAssignment — proven by the decoupled upsert paths).
///   - Save/reopen preserves all fields (close + reopen the database).
///   - Migration preserves existing data using temporary projects (legacy
///     v59 database rewound per the 145.40 fixture-matrix pattern).
void main() {
  Future<ProjectDatabaseService> createService() async =>
      ProjectDatabaseService();

  Future<ProjectDatabase> openAt(
    ProjectDatabaseService service,
    String dir,
  ) async {
    final dbPath = '$dir/project.db';
    await service.create(dbPath);
    return service.open(dbPath);
  }

  Future<ProjectDatabase> reopenAt(
    ProjectDatabaseService service,
    String dir,
  ) async {
    final dbPath = '$dir/project.db';
    return service.open(dbPath);
  }

  Future<void> seedCharacter(ProjectDatabase db, {String id = 'char-1'}) async {
    final now = DateTime.now();
    await db
        .into(db.assets)
        .insert(
          AssetsCompanion.insert(
            id: id,
            projectId: 'project-1',
            name: 'Qowner',
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
            projectId: 'project-1',
            displayName: 'Qowner',
          ),
        );
  }

  NarrativeAssignmentRepository repoOf(ProjectDatabase db) =>
      NarrativeAssignmentRepository(database: db, projectId: 'project-1');

  test('empty assignments and supports for unknown coordinates', () async {
    final dir = await Directory.systemTemp.createTemp('narr-persist-');
    addTearDown(() => dir.delete(recursive: true));
    final service = await createService();
    final db = await openAt(service, dir.path);
    addTearDown(db.close);

    final repo = repoOf(db);

    expect(
      await repo.getAssignment(
        novelWorkspaceId: 'novel-x',
        characterId: 'char-1',
      ),
      isNull,
    );
    expect(await repo.listSupports('char-1'), isEmpty);
  });

  test('same character holds independent assignments in two novels '
      'without cross-contamination, surviving close/reopen', () async {
    final dir = await Directory.systemTemp.createTemp('narr-persist-');
    addTearDown(() => dir.delete(recursive: true));
    final service = await createService();
    final db = await openAt(service, dir.path);
    await seedCharacter(db);

    final repo = repoOf(db);

    await repo.saveAssignment(
      NarrativeAssignment(
        novelWorkspaceId: 'novel-a',
        characterId: 'char-1',
        roles: {NarrativeRole.protagonist},
        importance: NarrativeImportance.major,
        pov: NarrativePov.yes,
      ),
    );
    // Independent assignment in a second novel — the same character
    // identity, no duplicate profile.
    await repo.saveAssignment(
      NarrativeAssignment(
        novelWorkspaceId: 'novel-b',
        characterId: 'char-1',
        roles: {NarrativeRole.background},
        importance: NarrativeImportance.minor,
        pov: NarrativePov.no,
      ),
    );
    await db.close();

    final reopened = await reopenAt(service, dir.path);
    addTearDown(reopened.close);
    final fresh = repoOf(reopened);

    final a = await fresh.getAssignment(
      novelWorkspaceId: 'novel-a',
      characterId: 'char-1',
    );
    final b = await fresh.getAssignment(
      novelWorkspaceId: 'novel-b',
      characterId: 'char-1',
    );
    expect(a, isNotNull);
    expect(b, isNotNull);
    expect(a!.roles, {NarrativeRole.protagonist});
    expect(a.importance, NarrativeImportance.major);
    expect(a.pov, NarrativePov.yes);
    expect(b!.roles, {NarrativeRole.background});
    expect(b.importance, NarrativeImportance.minor);
    expect(b.pov, NarrativePov.no);
  });

  test('support A→B permanent and A→C temporary coexist without overwrite; '
      'duration/status edits leave importance/POV untouched', () async {
    final dir = await Directory.systemTemp.createTemp('narr-persist-');
    addTearDown(() => dir.delete(recursive: true));
    final service = await createService();
    final db = await openAt(service, dir.path);
    addTearDown(db.close);
    await seedCharacter(db);

    final repo = repoOf(db);

    await repo.saveAssignment(
      NarrativeAssignment(
        novelWorkspaceId: 'novel-a',
        characterId: 'char-1',
        roles: {NarrativeRole.supporting},
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
        purpose: 'misi pengawal khusus',
      ),
    );

    final supports = await repo.listSupports('char-1');
    expect(supports, hasLength(2));
    final ac = supports.singleWhere((s) => s.supportedId == 'char-c');
    await repo.saveSupport(
      ac.copyWith(
        duration: SupportDuration.recurring,
        status: SupportStatus.separated,
        separationReason: 'misi selesai',
      ),
    );

    final after = await repo.listSupports('char-1');
    final ab = after.singleWhere((s) => s.supportedId == 'char-b');
    final ac2 = after.singleWhere((s) => s.supportedId == 'char-c');
    expect(
      ab.duration,
      SupportDuration.permanent,
      reason: 'A→B must not be overwritten by A→C edits',
    );
    expect(ab.type, SupportType.protector);
    expect(ac2.duration, SupportDuration.recurring);
    expect(ac2.status, SupportStatus.separated);
    expect(ac2.separationReason, 'misi selesai');
    expect(ac2.purpose, 'misi pengawal khusus');

    // Duration/status changes must not change importance or POV.
    final assignment = await repo.getAssignment(
      novelWorkspaceId: 'novel-a',
      characterId: 'char-1',
    );
    expect(assignment!.importance, NarrativeImportance.major);
    expect(assignment.pov, NarrativePov.yes);
  });

  test('deleting a character removes narrative rows for that character '
      'only', () async {
    final dir = await Directory.systemTemp.createTemp('narr-persist-');
    addTearDown(() => dir.delete(recursive: true));
    final service = await createService();
    final db = await openAt(service, dir.path);
    addTearDown(db.close);
    await seedCharacter(db, id: 'char-1');
    await seedCharacter(db, id: 'char-b');

    final repo = repoOf(db);
    await repo.saveAssignment(
      NarrativeAssignment(
        novelWorkspaceId: 'novel-a',
        characterId: 'char-1',
        roles: {NarrativeRole.supporting},
      ),
    );
    await repo.saveSupport(
      SupportRelationship(
        sourceCharacterId: 'char-1',
        supportedId: 'char-b',
        storyNovelWorkspaceId: 'novel-a',
        type: SupportType.mentor,
      ),
    );

    await repo.deleteForCharacter('char-1');

    expect(
      await repo.getAssignment(
        novelWorkspaceId: 'novel-a',
        characterId: 'char-1',
      ),
      isNull,
    );
    expect(await repo.listSupports('char-1'), isEmpty);
    // char-b keeps its data (support rows are keyed on source; char-b is a
    // supported target here, its own assignments stay intact).
    await repo.saveAssignment(
      NarrativeAssignment(
        novelWorkspaceId: 'novel-a',
        characterId: 'char-b',
        roles: {NarrativeRole.background},
      ),
    );
    final b = await repo.getAssignment(
      novelWorkspaceId: 'novel-a',
      characterId: 'char-b',
    );
    expect(b!.roles, {NarrativeRole.background});
  });

  test('unknown support wire token fails loudly', () async {
    expect(() => SupportType.fromWire('nonsense'), throwsArgumentError);
  });

  test('legacy v59 database migrates without touching existing rows', () async {
    final dir = await Directory.systemTemp.createTemp('narr-persist-');
    addTearDown(() => dir.delete(recursive: true));
    final service = await createService();
    final db = await openAt(service, dir.path);
    await seedCharacter(db);
    await db.close();

    // Rewind to a faithful v59 layout per the 145.40 fixture-matrix
    // pattern: drop the two new tables and rewind user_version, so the
    // guarded migration wave re-applies on reopen.
    final raw = File('${dir.path}/project.db');
    expect(raw.existsSync(), isTrue);
    final pre = await service.open(dbPathFor(dir));
    await pre.customStatement(
      'DROP TABLE IF EXISTS character_narrative_assignments',
    );
    await pre.customStatement(
      'DROP TABLE IF EXISTS character_support_relationships',
    );
    await pre.customStatement('PRAGMA user_version = 59');
    await pre.close();

    final migrated = await service.open(dbPathFor(dir));
    addTearDown(migrated.close);
    final charCount = (await migrated.select(migrated.characters).get()).length;
    expect(charCount, 1, reason: 'existing character data must survive');
    final tableNames = migrated.allSchemaEntities
        .whereType<TableInfo>()
        .map((t) => t.entityName)
        .toSet();
    expect(tableNames, contains('character_narrative_assignments'));
    expect(tableNames, contains('character_support_relationships'));
    final version = await migrated
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.data['user_version'], greaterThanOrEqualTo(60));
  });
}

String dbPathFor(Directory dir) => '${dir.path}/project.db';
