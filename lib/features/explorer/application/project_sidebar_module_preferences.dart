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
    this.wardrobe = true,
  });

  // Retained only to read v1 preference files. Factions and relationships are
  // sections inside Worldbuilding, not top-level sidebar modules.
  final bool factions;
  final bool relationshipMap;
  final bool weapons;
  final bool storyItems;
  final bool wardrobe;

  ProjectSidebarModulePreferences copyWith({
    bool? factions,
    bool? relationshipMap,
    bool? weapons,
    bool? storyItems,
    bool? wardrobe,
  }) => ProjectSidebarModulePreferences(
    factions: factions ?? this.factions,
    relationshipMap: relationshipMap ?? this.relationshipMap,
    weapons: weapons ?? this.weapons,
    storyItems: storyItems ?? this.storyItems,
    wardrobe: wardrobe ?? this.wardrobe,
  );

  Map<String, Object> toJson() => {
    'version': 4,
    'factions': false,
    'relationshipMap': false,
    'weapons': weapons,
    'storyItems': storyItems,
    'wardrobe': wardrobe,
  };

  static ProjectSidebarModulePreferences? tryFromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final version = value['version'];
    if (version != 1 && version != 2 && version != 3 && version != 4) {
      return null;
    }
    final factions = value['factions'];
    final relationshipMap = value['relationshipMap'];
    if (factions is! bool || relationshipMap is! bool) return null;
    final weapons = value['weapons'];
    final storyItems = value['storyItems'];
    final wardrobe = value['wardrobe'];
    if (version >= 2 && weapons is! bool) return null;
    if (version >= 3 && storyItems is! bool) return null;
    if (version == 4 && wardrobe is! bool) return null;
    return ProjectSidebarModulePreferences(
      factions: false,
      relationshipMap: false,
      weapons: version >= 2 ? weapons! as bool : false,
      storyItems: version >= 3 ? storyItems! as bool : false,
      wardrobe: version == 4 ? wardrobe! as bool : true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProjectSidebarModulePreferences &&
      factions == other.factions &&
      relationshipMap == other.relationshipMap &&
      weapons == other.weapons &&
      storyItems == other.storyItems &&
      wardrobe == other.wardrobe;

  @override
  int get hashCode =>
      Object.hash(factions, relationshipMap, weapons, storyItems, wardrobe);
}

class SidebarGenreProfile {
  const SidebarGenreProfile({
    required this.family,
    this.wardrobe = false,
    this.weapons = false,
    this.storyItems = false,
  });

  final String family;
  final bool wardrobe;
  final bool weapons;
  final bool storyItems;
}

class ProjectSidebarModulePolicy {
  static const _profiles = <String, SidebarGenreProfile>{
    'romance': SidebarGenreProfile(
      family: 'Romance',
      wardrobe: true,
      storyItems: true,
    ),
    'drama': SidebarGenreProfile(
      family: 'Drama',
      wardrobe: true,
      storyItems: true,
    ),
    'fantasy': SidebarGenreProfile(
      family: 'Fantasy',
      wardrobe: true,
      weapons: true,
      storyItems: true,
    ),
    'science fiction': SidebarGenreProfile(
      family: 'Science Fiction',
      weapons: true,
    ),
    'mystery': SidebarGenreProfile(family: 'Mystery', storyItems: true),
    'thriller': SidebarGenreProfile(family: 'Thriller', storyItems: true),
    'crime': SidebarGenreProfile(family: 'Crime', storyItems: true),
    'detective': SidebarGenreProfile(family: 'Detective', storyItems: true),
    'horror': SidebarGenreProfile(family: 'Horror', storyItems: true),
    'gothic': SidebarGenreProfile(
      family: 'Gothic',
      wardrobe: true,
      storyItems: true,
    ),
    'historical': SidebarGenreProfile(
      family: 'Historical',
      wardrobe: true,
      weapons: true,
      storyItems: true,
    ),
    'adventure': SidebarGenreProfile(
      family: 'Adventure',
      weapons: true,
      storyItems: true,
    ),
    'action': SidebarGenreProfile(family: 'Action', weapons: true),
    'war / military': SidebarGenreProfile(
      family: 'War / Military',
      weapons: true,
    ),
    'political': SidebarGenreProfile(family: 'Political', storyItems: true),
    'dystopia': SidebarGenreProfile(family: 'Dystopia', weapons: true),
    'kingdom / epic': SidebarGenreProfile(
      family: 'Kingdom / Epic',
      wardrobe: true,
      weapons: true,
      storyItems: true,
    ),
    'young adult': SidebarGenreProfile(
      family: 'Young Adult',
      wardrobe: true,
      storyItems: true,
    ),
    'coming-of-age': SidebarGenreProfile(
      family: 'Coming-of-age',
      wardrobe: true,
      storyItems: true,
    ),
    'family saga': SidebarGenreProfile(
      family: 'Family Saga',
      wardrobe: true,
      storyItems: true,
    ),
    'slice of life': SidebarGenreProfile(
      family: 'Slice of Life',
      wardrobe: true,
      storyItems: true,
    ),
    'comedy / satire': SidebarGenreProfile(
      family: 'Comedy / Satire',
      wardrobe: true,
      storyItems: true,
    ),
    'literary fiction': SidebarGenreProfile(
      family: 'Literary Fiction',
      storyItems: true,
    ),
    'magical realism': SidebarGenreProfile(
      family: 'Magical Realism',
      wardrobe: true,
      storyItems: true,
    ),
  };

  static Set<String> get supportedGenreFamilies =>
      _profiles.values.map((profile) => profile.family).toSet();

  static SidebarGenreProfile? profileFor(String genre) {
    final normalized = genre.trim().toLowerCase();
    SidebarGenreProfile? best;
    var bestLength = -1;
    for (final entry in _profiles.entries) {
      final aliases = switch (entry.key) {
        'science fiction' => const [
          'science fiction',
          'sci-fi',
          'science fantasy',
        ],
        'war / military' => const ['war', 'military'],
        'kingdom / epic' => const ['kingdom', 'epic'],
        'comedy / satire' => const ['comedy', 'satire'],
        _ => [entry.key],
      };
      for (final alias in aliases) {
        if (normalized.contains(alias) && alias.length > bestLength) {
          best = entry.value;
          bestLength = alias.length;
        }
      }
    }
    return best;
  }

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
    bool hasWardrobe = false,
  }) {
    final normalized = genres
        .map((genre) => genre.trim().toLowerCase())
        .where((genre) => genre.isNotEmpty)
        .toList(growable: false);
    final profiles = normalized
        .map(profileFor)
        .whereType<SidebarGenreProfile>()
        .toList(growable: false);
    bool matches(Set<String> terms) =>
        normalized.any((genre) => terms.any(genre.contains));
    return ProjectSidebarModulePreferences(
      factions: false,
      relationshipMap: false,
      wardrobe: hasWardrobe || profiles.any((profile) => profile.wardrobe),
      weapons:
          hasWeapons ||
          profiles.any((profile) => profile.weapons) ||
          matches(_factionGenreTerms),
      storyItems:
          hasStoryItems ||
          profiles.any((profile) => profile.storyItems) ||
          matches(_storyItemGenreTerms),
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
    final wardrobes = await database.wardrobeDao.getWardrobes(projectId);
    final props = await (database.select(
      database.props,
    )..where((row) => row.projectId.equals(projectId))).get();
    return ProjectSidebarModulePolicy.recommend(
      genres: stories.map((story) => story.genre),
      hasFactions: factions.isNotEmpty,
      hasRelationships: relationships.isNotEmpty,
      hasWeapons: weapons.isNotEmpty,
      hasStoryItems: props.isNotEmpty,
      hasWardrobe: wardrobes.isNotEmpty,
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
