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
  });

  // Retained only to read v1 preference files. Factions and relationships are
  // sections inside Worldbuilding, not top-level sidebar modules.
  final bool factions;
  final bool relationshipMap;
  final bool weapons;

  ProjectSidebarModulePreferences copyWith({
    bool? factions,
    bool? relationshipMap,
    bool? weapons,
  }) => ProjectSidebarModulePreferences(
    factions: factions ?? this.factions,
    relationshipMap: relationshipMap ?? this.relationshipMap,
    weapons: weapons ?? this.weapons,
  );

  Map<String, Object> toJson() => {
    'version': 2,
    'factions': false,
    'relationshipMap': false,
    'weapons': weapons,
  };

  static ProjectSidebarModulePreferences? tryFromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final version = value['version'];
    if (version != 1 && version != 2) return null;
    final factions = value['factions'];
    final relationshipMap = value['relationshipMap'];
    if (factions is! bool || relationshipMap is! bool) return null;
    final weapons = value['weapons'];
    if (version == 2 && weapons is! bool) return null;
    return ProjectSidebarModulePreferences(
      factions: false,
      relationshipMap: false,
      weapons: version == 2 ? weapons! as bool : false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProjectSidebarModulePreferences &&
      factions == other.factions &&
      relationshipMap == other.relationshipMap &&
      weapons == other.weapons;

  @override
  int get hashCode => Object.hash(factions, relationshipMap, weapons);
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

  static ProjectSidebarModulePreferences recommend({
    required Iterable<String> genres,
    required bool hasFactions,
    required bool hasRelationships,
    bool hasWeapons = false,
  }) {
    final normalized = genres
        .map((genre) => genre.trim().toLowerCase())
        .where((genre) => genre.isNotEmpty);
    final genreSuggestsWeapons = normalized.any(
      (genre) => _factionGenreTerms.any(genre.contains),
    );
    return ProjectSidebarModulePreferences(
      factions: false,
      relationshipMap: false,
      weapons: hasWeapons || genreSuggestsWeapons,
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
    return ProjectSidebarModulePolicy.recommend(
      genres: stories.map((story) => story.genre),
      hasFactions: factions.isNotEmpty,
      hasRelationships: relationships.isNotEmpty,
      hasWeapons: weapons.isNotEmpty,
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
