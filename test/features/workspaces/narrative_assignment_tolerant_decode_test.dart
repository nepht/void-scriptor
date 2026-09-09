import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/workspaces/application/narrative_assignment_repository.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';

/// Regression: `void-scriptor-hunt-20260909` BUG-06 (Referee REAL BUG,
/// Medium). One unknown enum token — the realistic trigger is a
/// portable-import vocabulary skew or a manual DB edit, since no write path
/// produces unknown tokens — must not abort `listAssignments()` wholesale.
/// Decode is per-row and per-token tolerant: healthy rows survive untouched
/// and a corrupted row keeps its (novel, character) identity.
void main() {
  late Directory dir;
  late ProjectDatabase db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('narr-tolerant-');
    final service = ProjectDatabaseService();
    final dbPath = '${dir.path}${Platform.pathSeparator}project.db';
    await service.create(dbPath);
    db = await service.open(dbPath);
  });

  tearDown(() async {
    await db.close();
    try {
      await dir.delete(recursive: true);
    } on FileSystemException {
      // Windows file-watch lag on a disposable fixture; deletion is best
      // effort and never part of the assertion.
    }
  });

  Future<void> seedRow({
    required String novel,
    required String character,
    String? roles,
    String? importance,
    String? pov,
  }) async {
    await db
        .into(db.characterNarrativeAssignments)
        .insert(
          CharacterNarrativeAssignmentsCompanion.insert(
            projectId: 'project-1',
            novelWorkspaceId: novel,
            characterId: character,
            roles: Value(roles),
            importance: Value(importance),
            pov: Value(pov),
          ),
        );
  }

  test(
    'one unknown token skips that token; healthy tokens and rows survive',
    () async {
      await seedRow(
        novel: 'novel-1',
        character: 'c-hero',
        roles: 'protagonist,time-lord',
        importance: 'legendary',
        pov: 'sometimes',
      );
      await seedRow(
        novel: 'novel-1',
        character: 'c-side',
        roles: 'antagonist',
        importance: 'major',
        pov: 'no',
      );

      final repo = NarrativeAssignmentRepository(
        database: db,
        projectId: 'project-1',
      );
      final assignments = await repo.listAssignments();

      expect(assignments, hasLength(2));

      final corrupted = assignments.singleWhere(
        (assignment) => assignment.characterId == 'c-hero',
      );
      // Row identity survives even though every wire token is unknown.
      expect(corrupted.novelWorkspaceId, 'novel-1');
      // Unknown role token is skipped; the known one is kept.
      expect(corrupted.roles, {NarrativeRole.protagonist});
      // Unknown scalars fall back to `unspecified`, matching the "no
      // explicit value" filter semantics.
      expect(corrupted.importance, NarrativeImportance.unspecified);
      expect(corrupted.pov, NarrativePov.unspecified);

      final healthy = assignments.singleWhere(
        (assignment) => assignment.characterId == 'c-side',
      );
      expect(healthy.roles, {NarrativeRole.antagonist});
      expect(healthy.importance, NarrativeImportance.major);
      expect(healthy.pov, NarrativePov.no);
    },
  );

  test(
    'unknown-only and whitespace role tokens decode to an empty role set',
    () async {
      await seedRow(
        novel: 'novel-2',
        character: 'c-unknown',
        roles: ' , time-lord ,,',
      );

      final repo = NarrativeAssignmentRepository(
        database: db,
        projectId: 'project-1',
      );
      final assignments = await repo.listAssignments();

      final row = assignments.single;
      expect(row.novelWorkspaceId, 'novel-2');
      expect(row.characterId, 'c-unknown');
      expect(row.roles, isEmpty);
      expect(row.importance, NarrativeImportance.unspecified);
      expect(row.pov, NarrativePov.unspecified);
    },
  );
}
