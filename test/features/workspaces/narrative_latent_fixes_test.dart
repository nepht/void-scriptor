import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/workspaces/application/narrative_assignment_repository.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';

/// Regression coverage for the remaining latent hunt-run157 findings
/// (Referee verdict REAL BUG, Low) in the narrative/support domain:
///
/// - BUG-11: strict `fromJson` casts/`fromWire` abort a whole decode on one
///   unknown token; per-entry tolerance keeps valid entries adoptable.
/// - BUG-13: `listSupportsFor` returned insertion-ordered rows; it must match
///   `listSupports`' deterministic (story, supported) ordering.
///
/// (BUG-10 clearX copyWith lives in its own file: pre-fix the missing named
/// parameters fail at compile time, which is the RED for that API gap.)
void main() {
  group('BUG-11 tolerant fromJson decode', () {
    test(
      'NarrativeAssignment.fromJson skips unknown/malformed role entries',
      () {
        final assignment = NarrativeAssignment.fromJson(<String, dynamic>{
          'novel_workspace_id': 'novel-1',
          'character_id': 'char-1',
          'roles': <dynamic>[
            'protagonist',
            42,
            'mentor_from_a_newer_build',
            null,
          ],
          'importance': 'major',
          'pov': 'yes',
        });
        expect(assignment.roles, {NarrativeRole.protagonist});
        expect(assignment.importance, NarrativeImportance.major);
        expect(assignment.pov, NarrativePov.yes);
      },
    );

    test(
      'NarrativeAssignment.fromJson falls back to unspecified for unknown scalars',
      () {
        final assignment = NarrativeAssignment.fromJson(<String, dynamic>{
          'novel_workspace_id': 'novel-1',
          'character_id': 'char-1',
          'roles': <dynamic>['protagonist'],
          'importance': 'crucial_from_a_newer_build',
          'pov': 7,
        });
        expect(assignment.importance, NarrativeImportance.unspecified);
        expect(assignment.pov, NarrativePov.unspecified);
      },
    );

    test('SupportRelationship.fromJson tolerates unknown optional enums', () {
      final support = SupportRelationship.fromJson(<String, dynamic>{
        'source_character_id': 'a',
        'supported_id': 'b',
        'story_novel_workspace_id': 'novel-1',
        'type': 'mentor',
        'duration': 'seasonal_from_a_newer_build',
        'status': 9,
        'purpose': 123,
        'separation_reason': null,
      });
      expect(support.type, SupportType.mentor);
      expect(support.duration, SupportDuration.unspecified);
      expect(support.status, SupportStatus.unspecified);
      expect(support.purpose, isNull);
      expect(support.separationReason, isNull);
    });

    test('round-trip: well-formed JSON still decodes to identical values', () {
      final original = SupportRelationship(
        sourceCharacterId: 'a',
        supportedId: 'b',
        storyNovelWorkspaceId: 'novel-1',
        type: SupportType.informant,
        duration: SupportDuration.temporary,
        status: SupportStatus.active,
        purpose: 'leaks intel',
      );
      final decoded = SupportRelationship.fromJson(original.toJson());
      expect(decoded, original);
    });
  });

  group('BUG-13 listSupportsFor deterministic ordering', () {
    test('rows come back ordered by story then supported id', () async {
      final root = await Directory.systemTemp.createTemp('narr-order-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final service = ProjectDatabaseService();
      final dbFile = await paths.database('project-1');
      await service.create(dbFile.path);
      final db = await service.open(dbFile.path);
      addTearDown(db.close);
      final repository = NarrativeAssignmentRepository(
        database: db,
        projectId: 'project-1',
      );

      // Insert in NON-sorted order; a fresh SQLite select is not required to
      // be sorted, so insertion order is what the pre-fix code returned.
      // listSupportsFor(supportedId) filters on the SUPPORTED character, so
      // every row here supports 'qowner' from a different story.
      await repository.saveSupport(
        SupportRelationship(
          sourceCharacterId: 'a',
          supportedId: 'qowner',
          storyNovelWorkspaceId: 'novel-c',
          type: SupportType.mentor,
        ),
      );
      await repository.saveSupport(
        SupportRelationship(
          sourceCharacterId: 'c',
          supportedId: 'qowner',
          storyNovelWorkspaceId: 'novel-a',
          type: SupportType.informant,
        ),
      );
      await repository.saveSupport(
        SupportRelationship(
          sourceCharacterId: 'd',
          supportedId: 'qowner',
          storyNovelWorkspaceId: 'novel-b',
          type: SupportType.supporter,
        ),
      );

      final rows = await repository.listSupportsFor('qowner');
      expect(
        rows.map((r) => r.storyNovelWorkspaceId).toList(),
        ['novel-a', 'novel-b', 'novel-c'],
        reason: 'BUG-13: rows must be ordered by story id, not insertion order',
      );
    });
  });
}
