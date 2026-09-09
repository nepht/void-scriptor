import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_character_filter.dart';

/// Backlog `docs/backlog/character-roles-support.json` phase_one UI item:
/// "Filter character list by role, importance and POV with a clear reset
/// action". Domain contract for matching one character against the filter.
///
/// Semantics (documented on [NarrativeCharacterFilter]):
/// - Each active dimension must be satisfied (AND across dimensions).
/// - Within one dimension, any of the character's assignments may satisfy it
///   (OR across novels — a character can be protagonist in novel A and
///   antagonist in novel B).
/// - `unspecified` importance/POV filter values match characters that have no
///   assignment carrying an explicit value (including characters with no
///   assignment at all).
void main() {
  NarrativeAssignment assignment({
    required String characterId,
    required String novel,
    Set<NarrativeRole> roles = const {},
    NarrativeImportance importance = NarrativeImportance.unspecified,
    NarrativePov pov = NarrativePov.unspecified,
  }) => NarrativeAssignment(
    novelWorkspaceId: novel,
    characterId: characterId,
    roles: roles,
    importance: importance,
    pov: pov,
  );

  test('inactive filter matches every character', () {
    const filter = NarrativeCharacterFilter();
    expect(filter.isActive, isFalse);
    expect(
      filter.matchesCharacter(characterId: 'c1', assignments: const []),
      isTrue,
    );
  });

  test('role filter matches when any assignment carries the role', () {
    const filter = NarrativeCharacterFilter(role: NarrativeRole.protagonist);
    final assignments = [
      assignment(
        characterId: 'c1',
        novel: 'n1',
        roles: {NarrativeRole.antagonist},
      ),
      assignment(
        characterId: 'c1',
        novel: 'n2',
        roles: {NarrativeRole.protagonist},
      ),
    ];
    expect(
      filter.matchesCharacter(characterId: 'c1', assignments: assignments),
      isTrue,
    );
    expect(
      filter.matchesCharacter(
        characterId: 'c2',
        assignments: [
          assignment(
            characterId: 'c2',
            novel: 'n1',
            roles: {NarrativeRole.supporting},
          ),
        ],
      ),
      isFalse,
    );
  });

  test('importance filter matches explicit value across assignments', () {
    const filter = NarrativeCharacterFilter(
      importance: NarrativeImportance.major,
    );
    final assignments = [
      assignment(characterId: 'c1', novel: 'n1'),
      assignment(
        characterId: 'c1',
        novel: 'n2',
        importance: NarrativeImportance.major,
      ),
    ];
    expect(
      filter.matchesCharacter(characterId: 'c1', assignments: assignments),
      isTrue,
    );
    expect(
      filter.matchesCharacter(
        characterId: 'c2',
        assignments: [
          assignment(
            characterId: 'c2',
            novel: 'n1',
            importance: NarrativeImportance.minor,
          ),
        ],
      ),
      isFalse,
    );
    expect(
      filter.matchesCharacter(characterId: 'c3', assignments: const []),
      isFalse,
    );
  });

  test(
    'unspecified importance filter matches only characters without explicit importance',
    () {
      const filter = NarrativeCharacterFilter(
        importance: NarrativeImportance.unspecified,
      );
      expect(
        filter.matchesCharacter(characterId: 'c1', assignments: const []),
        isTrue,
      );
      expect(
        filter.matchesCharacter(
          characterId: 'c2',
          assignments: [assignment(characterId: 'c2', novel: 'n1')],
        ),
        isTrue,
      );
      expect(
        filter.matchesCharacter(
          characterId: 'c3',
          assignments: [
            assignment(
              characterId: 'c3',
              novel: 'n1',
              importance: NarrativeImportance.minor,
            ),
          ],
        ),
        isFalse,
      );
    },
  );

  test('unspecified POV filter follows the same no-explicit-value rule', () {
    const filter = NarrativeCharacterFilter(pov: NarrativePov.unspecified);
    expect(
      filter.matchesCharacter(
        characterId: 'c1',
        assignments: [
          assignment(characterId: 'c1', novel: 'n1', pov: NarrativePov.yes),
        ],
      ),
      isFalse,
    );
    expect(
      filter.matchesCharacter(characterId: 'c2', assignments: const []),
      isTrue,
    );
  });

  test('dimensions combine with AND while novels combine with OR', () {
    // Protagonist in n1 (unspecified importance), antagonist+major in n2.
    final assignments = [
      assignment(
        characterId: 'c1',
        novel: 'n1',
        roles: {NarrativeRole.protagonist},
      ),
      assignment(
        characterId: 'c1',
        novel: 'n2',
        roles: {NarrativeRole.antagonist},
        importance: NarrativeImportance.major,
        pov: NarrativePov.yes,
      ),
    ];
    const protagonistMajor = NarrativeCharacterFilter(
      role: NarrativeRole.protagonist,
      importance: NarrativeImportance.major,
    );
    // Protagonist (n1) and major (n2) come from different novels: per the
    // documented per-dimension OR semantics this still matches.
    expect(
      protagonistMajor.matchesCharacter(
        characterId: 'c1',
        assignments: assignments,
      ),
      isTrue,
    );
    const antagonistYes = NarrativeCharacterFilter(
      role: NarrativeRole.antagonist,
      pov: NarrativePov.yes,
    );
    expect(
      antagonistYes.matchesCharacter(
        characterId: 'c1',
        assignments: assignments,
      ),
      isTrue,
    );
    const backgroundMajor = NarrativeCharacterFilter(
      role: NarrativeRole.background,
      importance: NarrativeImportance.major,
    );
    expect(
      backgroundMajor.matchesCharacter(
        characterId: 'c1',
        assignments: assignments,
      ),
      isFalse,
    );
  });

  test('filter ignores assignments of other characters', () {
    const filter = NarrativeCharacterFilter(role: NarrativeRole.protagonist);
    final assignments = [
      assignment(
        characterId: 'other',
        novel: 'n1',
        roles: {NarrativeRole.protagonist},
      ),
    ];
    expect(
      filter.matchesCharacter(characterId: 'c1', assignments: assignments),
      isFalse,
    );
  });
}
