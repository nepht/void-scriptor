import '../../../database/project/project_database.dart' as data;
import '../domain/narrative_assignment.dart';
import 'narrative_assignment_repository.dart';

/// One cast row for the Novel Workspace Cast section: the character's
/// display name, its narrative assignment for the selected novel, and the
/// description fields (biography/personality) authored in the Character
/// Workspace.
class StoryCastEntry {
  const StoryCastEntry({
    required this.characterId,
    required this.displayName,
    required this.assignment,
    this.biography = '',
    this.personality = '',
  });

  final String characterId;
  final String displayName;
  final NarrativeAssignment assignment;
  final String biography;
  final String personality;

  /// How much narrative weight this row carries (backing store value).
  NarrativeImportance get importance => assignment.importance;
}

/// Backlog `character-roles-support` phase_one (novel-side view): pure
/// read-only loader behind the Story Workspace Cast section. Joins the
/// novel's narrative assignments with character display names from the
/// `characters` table; rows are project-scoped and never mutate anything.
/// Ordering mirrors narrative weight: major, supporting, minor, then
/// unspecified; ties break alphabetically by display name.
class StoryCastLoader {
  const StoryCastLoader({required this.database, required this.projectId});

  final data.ProjectDatabase database;
  final String projectId;

  Future<List<StoryCastEntry>> load(String novelWorkspaceId) async {
    final repository = NarrativeAssignmentRepository(
      database: database,
      projectId: projectId,
    );
    final assignments = await repository.listAssignments();
    final characters = await database.characterDao.getAllCharacters(projectId);
    final profiles = <String, data.Character>{
      for (final character in characters) character.assetId: character,
    };
    final entries = <StoryCastEntry>[];
    for (final assignment in assignments) {
      if (assignment.novelWorkspaceId != novelWorkspaceId) continue;
      final character = profiles[assignment.characterId];
      if (character == null) {
        // Assignment without a matching character row (deleted character or
        // version-skewed portable import): skip the row, never fail the list.
        continue;
      }
      entries.add(
        StoryCastEntry(
          characterId: assignment.characterId,
          displayName: character.displayName,
          assignment: assignment,
          biography: character.biography,
          personality: character.personality,
        ),
      );
    }
    int rank(NarrativeImportance importance) => switch (importance) {
      NarrativeImportance.major => 0,
      NarrativeImportance.supporting => 1,
      NarrativeImportance.minor => 2,
      NarrativeImportance.unspecified => 3,
    };
    entries.sort((a, b) {
      final byRank = rank(a.importance).compareTo(rank(b.importance));
      if (byRank != 0) return byRank;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return List.unmodifiable(entries);
  }
}
