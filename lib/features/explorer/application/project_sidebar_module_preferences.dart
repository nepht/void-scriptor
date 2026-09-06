import 'dart:convert';
import 'dart:io';

import '../../../core/persistence/project_recovery_service.dart';
import '../../../core/project_package/project_package.dart';
import '../../../database/project/project_database.dart';

class ProjectSidebarModulePreferences {
  const ProjectSidebarModulePreferences({
    required this.factions,
    required this.relationshipMap,
    this.weapons = false,
    this.storyItems = false,
  });

  // Retained only to read v1 preference files. Factions and relationships are
  // sections inside Worldbuilding, not top-level sidebar modules.
  final bool factions;
  final bool relationshipMap;
  final bool weapons;
  final bool storyItems;

  ProjectSidebarModulePreferences copyWith({
    bool? factions,
    bool? relationshipMap,
    bool? weapons,
    bool? storyItems,
  }) => ProjectSidebarModulePreferences(
    factions: factions ?? this.factions,
    relationshipMap: relationshipMap ?? this.relationshipMap,
    weapons: weapons ?? this.weapons,
    storyItems: storyItems ?? this.storyItems,
  );

  Map<String, Object> toJson() => {
    'version': 3,
    'factions': false,
    'relationshipMap': false,
    'weapons': weapons,
    'storyItems': storyItems,
  };

  static ProjectSidebarModulePreferences? tryFromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final version = value['version'];
    if (version != 1 && version != 2 && version != 3) return null;
    final factions = value['factions'];
    final relationshipMap = value['relationshipMap'];
    if (factions is! bool || relationshipMap is! bool) return null;
    final weapons = value['weapons'];
    final storyItems = value['storyItems'];
    if (version >= 2 && weapons is! bool) return null;
    if (version == 3 && storyItems is! bool) return null;
    return ProjectSidebarModulePreferences(
      factions: false,
      relationshipMap: false,
      weapons: version >= 2 ? weapons! as bool : false,
      storyItems: version == 3 ? storyItems! as bool : false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProjectSidebarModulePreferences &&
      factions == other.factions &&
      relationshipMap == other.relationshipMap &&
      weapons == other.weapons &&
      storyItems == other.storyItems;

  @override
  int get hashCode =>
      Object.hash(factions, relationshipMap, weapons, storyItems);
}

class ProjectSidebarModulePolicy {
  static const _factionGenreTerms = <String>{
    'fantasy',
    'science fiction',
    'sci-fi',
    'science fantasy',
    'political',
    'politics',
    'historical',
    'war',
    'military',
    'dystopia',
    'kingdom',
    'epic',
  };

  static const _storyItemGenreTerms = <String>{
    'romance',
    'romantic',
    'drama',
    'mystery',
    'thriller',
    'crime',
    'detective',
    'historical',
    'fantasy',
    'horror',
    'gothic',
    'adventure',
  };

  static ProjectSidebarModulePreferences recommend({
    required Iterable<String> genres,
    required bool hasFactions,
    required bool hasRelationships,
    bool hasWeapons = false,
    bool hasStoryItems = false,
  }) {
    final normalized = genres
        .map((genre) => genre.trim().toLowerCase())
        .where((genre) => genre.isNotEmpty)
        .toList(growable: false);
    bool matches(Set<String> terms) =>
        normalized.any((genre) => terms.any(genre.contains));
    return ProjectSidebarModulePreferences(
      factions: false,
      relationshipMap: false,
      weapons: hasWeapons || matches(_factionGenreTerms),
      storyItems: hasStoryItems || matches(_storyItemGenreTerms),
    );
  }
}

class ProjectSidebarModulePreferencesService {
  const ProjectSidebarModulePreferencesService();

  static const relativePath = 'manifest/sidebar_modules.json';

  Future<ProjectSidebarModulePreferences> load({
    required ProjectPackage package,
    required ProjectDatabase database,
    required String projectId,
  }) async {
    final file = File(package.resolve(relativePath));
    await const ProjectRecoveryService().recoverIfInterrupted(file);
    if (await file.exists()) {
      try {
        final parsed = ProjectSidebarModulePreferences.tryFromJson(
          jsonDecode(await file.readAsString()),
        );
        if (parsed != null) return parsed;
      } on FormatException {
        // A preference file must never block access to the project.
      }
    }

    final stories = await (database.select(
      database.stories,
    )..where((row) => row.projectId.equals(projectId))).get();
    final factions = await (database.select(
      database.factions,
    )..where((row) => row.projectId.equals(projectId))).get();
    final relationships = await database.relationDao.getProjectRelations(
      projectId,
    );
    final weapons = await database.weaponDao.getWeapons(projectId);
    final props = await (database.select(
      database.props,
    )..where((row) => row.projectId.equals(projectId))).get();
    return ProjectSidebarModulePolicy.recommend(
      genres: stories.map((story) => story.genre),
      hasFactions: factions.isNotEmpty,
      hasRelationships: relationships.isNotEmpty,
      hasWeapons: weapons.isNotEmpty,
      hasStoryItems: props.isNotEmpty,
    );
  }

  Future<void> save(
    ProjectPackage package,
    ProjectSidebarModulePreferences preferences,
  ) => const ProjectRecoveryService().atomicWrite(
    target: File(package.resolve(relativePath)),
    content:
        '${const JsonEncoder.withIndent('  ').convert(preferences.toJson())}\n',
  );
}
