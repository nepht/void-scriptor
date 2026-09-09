import 'narrative_assignment.dart';

/// Backlog `docs/backlog/character-roles-support.json` phase_one UI item:
/// "Filter character list by role, importance and POV with a clear reset
/// action".
///
/// Matching semantics (locked by `narrative_character_filter_test.dart`):
/// - Dimensions combine with AND: a character matches only when every active
///   dimension is satisfied.
/// - Within one dimension, the character's assignments combine with OR: any
///   assignment may satisfy the dimension (a character can be protagonist in
///   one novel and antagonist in another without cross-contamination).
/// - The `unspecified` importance/POV filter values match characters with no
///   assignment carrying an explicit value, including characters with no
///   assignment at all (optional fields default to unspecified).
class NarrativeCharacterFilter {
  const NarrativeCharacterFilter({this.role, this.importance, this.pov});

  /// Required narrative role in any assignment, or null for no filter.
  final NarrativeRole? role;

  /// Required importance value (may be `unspecified` to match characters
  /// without an explicit importance), or null for no filter.
  final NarrativeImportance? importance;

  /// Required POV value (may be `unspecified` to match characters without an
  /// explicit POV), or null for no filter.
  final NarrativePov? pov;

  bool get isActive => role != null || importance != null || pov != null;

  /// Whether the character with [characterId] — holding [assignments] in this
  /// project — satisfies every active filter dimension.
  bool matchesCharacter({
    required String characterId,
    required Iterable<NarrativeAssignment> assignments,
  }) {
    final own = assignments
        .where((assignment) => assignment.characterId == characterId)
        .toList(growable: false);
    if (role != null) {
      final hasRole = own.any((assignment) => assignment.roles.contains(role));
      if (!hasRole) return false;
    }
    if (importance != null) {
      // `unspecified` means "no assignment carries an explicit value", so it
      // must hold for every assignment (vacuously true with no assignments).
      final matches = importance == NarrativeImportance.unspecified
          ? own.every((assignment) => assignment.importance == importance)
          : own.any((assignment) => assignment.importance == importance);
      if (!matches) return false;
    }
    if (pov != null) {
      final matches = pov == NarrativePov.unspecified
          ? own.every((assignment) => assignment.pov == pov)
          : own.any((assignment) => assignment.pov == pov);
      if (!matches) return false;
    }
    return true;
  }
}
