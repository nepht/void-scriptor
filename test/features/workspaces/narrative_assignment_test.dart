// Backlog character-roles-support (docs/backlog/character-roles-support.json)
// phase_one domain vocabulary slice. Canonical mapping: narrative assignment
// per novel belongs to steps 145.25/145.26 (character linking + novel-specific
// state); storage homes identified without schema mutation:
// novel_character_links (v55) and character_novel_states (v59). This slice
// proves the controlled vocabulary and value semantics only; persistence and
// UI wiring land in later slices.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';

void main() {
  group('NarrativeAssignment defaults', () {
    test('optional fields default to unspecified with no roles', () {
      final assignment = NarrativeAssignment(
        novelWorkspaceId: 'novel-1',
        characterId: 'char-1',
      );
      expect(assignment.roles, isEmpty);
      expect(assignment.importance, NarrativeImportance.unspecified);
      expect(assignment.pov, NarrativePov.unspecified);
    });

    test('multiple roles are allowed on one assignment', () {
      final assignment = NarrativeAssignment(
        novelWorkspaceId: 'novel-1',
        characterId: 'char-1',
        roles: {NarrativeRole.protagonist, NarrativeRole.antagonist},
      );
      expect(assignment.roles, hasLength(2));
      expect(
        assignment.roles,
        containsAll(<NarrativeRole>[
          NarrativeRole.protagonist,
          NarrativeRole.antagonist,
        ]),
      );
    });

    test('blank or empty coordinates are rejected', () {
      expect(
        () => NarrativeAssignment(novelWorkspaceId: ' ', characterId: 'c'),
        throwsArgumentError,
      );
      expect(
        () => NarrativeAssignment(novelWorkspaceId: 'n', characterId: ''),
        throwsArgumentError,
      );
    });
  });

  group('NarrativeAssignment value semantics', () {
    test('two novels keep independent assignments for one character', () {
      final inNovelOne = NarrativeAssignment(
        novelWorkspaceId: 'novel-1',
        characterId: 'char-1',
        roles: {NarrativeRole.protagonist},
      );
      final inNovelTwo = NarrativeAssignment(
        novelWorkspaceId: 'novel-2',
        characterId: 'char-1',
        roles: {NarrativeRole.background},
        importance: NarrativeImportance.minor,
        pov: NarrativePov.no,
      );
      expect(inNovelOne, isNot(equals(inNovelTwo)));
      expect(inNovelOne.roles, <NarrativeRole>{NarrativeRole.protagonist});
      expect(inNovelOne.importance, NarrativeImportance.unspecified);
      expect(inNovelOne.pov, NarrativePov.unspecified);
    });

    test('equal assignments compare equal regardless of role set order', () {
      final left = NarrativeAssignment(
        novelWorkspaceId: 'n',
        characterId: 'c',
        roles: {NarrativeRole.supporting, NarrativeRole.background},
        importance: NarrativeImportance.supporting,
      );
      final right = NarrativeAssignment(
        novelWorkspaceId: 'n',
        characterId: 'c',
        roles: {NarrativeRole.background, NarrativeRole.supporting},
        importance: NarrativeImportance.supporting,
      );
      expect(left, equals(right));
      expect(left.hashCode, right.hashCode);
    });

    test('json round-trip preserves roles, importance and pov', () {
      final assignment = NarrativeAssignment(
        novelWorkspaceId: 'novel-9',
        characterId: 'char-7',
        roles: {NarrativeRole.antagonist, NarrativeRole.supporting},
        importance: NarrativeImportance.major,
        pov: NarrativePov.yes,
      );
      final restored = NarrativeAssignment.fromJson(assignment.toJson());
      expect(restored, equals(assignment));
    });

    test('unknown stored role values are rejected, not silently dropped', () {
      final json = <String, dynamic>{
        'novel_workspace_id': 'n',
        'character_id': 'c',
        'roles': <String>['sidekick'],
        'importance': 'major',
        'pov': 'unspecified',
      };
      expect(() => NarrativeAssignment.fromJson(json), throwsArgumentError);
    });

    test('unknown stored importance values are rejected', () {
      final json = <String, dynamic>{
        'novel_workspace_id': 'n',
        'character_id': 'c',
        'roles': <String>[],
        'importance': 'legendary',
        'pov': 'unspecified',
      };
      expect(() => NarrativeAssignment.fromJson(json), throwsArgumentError);
    });
  });

  group('SupportRelationship', () {
    test('duration and status default to unspecified, purpose optional', () {
      final relationship = SupportRelationship(
        sourceCharacterId: 'source-1',
        supportedId: 'target-1',
        storyNovelWorkspaceId: 'novel-1',
        type: SupportType.mentor,
      );
      expect(relationship.duration, SupportDuration.unspecified);
      expect(relationship.status, SupportStatus.unspecified);
      expect(relationship.purpose, isNull);
      expect(relationship.separationReason, isNull);
    });

    test('blank coordinates are rejected', () {
      expect(
        () => SupportRelationship(
          sourceCharacterId: '',
          supportedId: 't',
          storyNovelWorkspaceId: 'n',
          type: SupportType.protector,
        ),
        throwsArgumentError,
      );
      expect(
        () => SupportRelationship(
          sourceCharacterId: 's',
          supportedId: ' ',
          storyNovelWorkspaceId: 'n',
          type: SupportType.protector,
        ),
        throwsArgumentError,
      );
      expect(
        () => SupportRelationship(
          sourceCharacterId: 's',
          supportedId: 't',
          storyNovelWorkspaceId: '',
          type: SupportType.protector,
        ),
        throwsArgumentError,
      );
    });

    test('changing duration keeps status and type unchanged', () {
      final relationship = SupportRelationship(
        sourceCharacterId: 's',
        supportedId: 't',
        storyNovelWorkspaceId: 'n',
        type: SupportType.travelCompanion,
        duration: SupportDuration.permanent,
        status: SupportStatus.active,
      );
      final changed = relationship.copyWith(
        duration: SupportDuration.temporary,
      );
      expect(changed.duration, SupportDuration.temporary);
      expect(changed.status, SupportStatus.active);
      expect(changed.type, SupportType.travelCompanion);
      // The original value object is immutable.
      expect(relationship.duration, SupportDuration.permanent);
    });

    test(
      'supporting B permanently and C temporarily are two relationships',
      () {
        final withB = SupportRelationship(
          sourceCharacterId: 'a',
          supportedId: 'b',
          storyNovelWorkspaceId: 'n',
          type: SupportType.supporter,
          duration: SupportDuration.permanent,
          status: SupportStatus.active,
        );
        final withC = SupportRelationship(
          sourceCharacterId: 'a',
          supportedId: 'c',
          storyNovelWorkspaceId: 'n',
          type: SupportType.supporter,
          duration: SupportDuration.temporary,
          status: SupportStatus.active,
        );
        expect(withB, isNot(equals(withC)));
        expect(withB.duration, SupportDuration.permanent);
        expect(withC.duration, SupportDuration.temporary);
      },
    );

    test('json round-trip preserves all fields including optional notes', () {
      final relationship = SupportRelationship(
        sourceCharacterId: 's',
        supportedId: 't',
        storyNovelWorkspaceId: 'novel-3',
        type: SupportType.informant,
        duration: SupportDuration.recurring,
        status: SupportStatus.separated,
        purpose: 'Menyimpan rahasia keluarga.',
        separationReason: 'Saling kecewa setelah pengkhianatan.',
      );
      final restored = SupportRelationship.fromJson(relationship.toJson());
      expect(restored, equals(relationship));
    });

    test('unknown stored support type values are rejected', () {
      final json = <String, dynamic>{
        'source_character_id': 's',
        'supported_id': 't',
        'story_novel_workspace_id': 'n',
        'type': 'henchman',
        'duration': 'unspecified',
        'status': 'unspecified',
        'purpose': null,
        'separation_reason': null,
      };
      expect(() => SupportRelationship.fromJson(json), throwsArgumentError);
    });
  });
}
