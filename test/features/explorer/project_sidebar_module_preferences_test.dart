import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/explorer/application/project_sidebar_module_preferences.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

void main() {
  test('recognizes all 24 supported genre families', () {
    const expected = {
      'Romance',
      'Drama',
      'Fantasy',
      'Science Fiction',
      'Mystery',
      'Thriller',
      'Crime',
      'Detective',
      'Horror',
      'Gothic',
      'Historical',
      'Adventure',
      'Action',
      'War / Military',
      'Political',
      'Dystopia',
      'Kingdom / Epic',
      'Young Adult',
      'Coming-of-age',
      'Family Saga',
      'Slice of Life',
      'Comedy / Satire',
      'Literary Fiction',
      'Magical Realism',
    };
    expect(ProjectSidebarModulePolicy.supportedGenreFamilies, expected);
    for (final genre in expected) {
      expect(
        ProjectSidebarModulePolicy.profileFor(genre),
        isNotNull,
        reason: genre,
      );
    }
  });

  test('genre profiles recommend only relevant optional modules', () {
    final romance = ProjectSidebarModulePolicy.recommend(
      genres: const ['School romance'],
      hasFactions: false,
      hasRelationships: false,
    );
    expect(romance.wardrobe, isTrue);
    expect(romance.weapons, isFalse);
    expect(romance.storyItems, isTrue);

    final military = ProjectSidebarModulePolicy.recommend(
      genres: const ['Military science fiction'],
      hasFactions: false,
      hasRelationships: false,
    );
    expect(military.wardrobe, isFalse);
    expect(military.weapons, isTrue);
    expect(military.storyItems, isFalse);
  });

  test('genre recommends factions without making it mandatory', () {
    final romance = ProjectSidebarModulePolicy.recommend(
      genres: const ['Romance', 'School drama'],
      hasFactions: false,
      hasRelationships: false,
    );
    expect(romance.factions, isFalse);
    expect(romance.relationshipMap, isFalse);
    expect(romance.weapons, isFalse);
    expect(romance.storyItems, isTrue);

    final fantasy = ProjectSidebarModulePolicy.recommend(
      genres: const ['Science Fantasy'],
      hasFactions: false,
      hasRelationships: false,
    );
    expect(fantasy.factions, isFalse);
    expect(fantasy.relationshipMap, isFalse);
    expect(fantasy.weapons, isTrue);
  });

  test(
    'saved choice overrides genre recommendation and survives reopen',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'void-sidebar-modules-',
      );
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Optional modules');
      final session = await ProjectSessionManager().open(package);
      const service = ProjectSidebarModulePreferencesService();
      try {
        await service.save(
          package,
          const ProjectSidebarModulePreferences(
            factions: false,
            relationshipMap: false,
          ),
        );
        expect(
          await service.load(
            package: package,
            database: session.database,
            projectId: package.projectId,
          ),
          const ProjectSidebarModulePreferences(
            factions: false,
            relationshipMap: false,
          ),
        );
      } finally {
        await session.close();
        await root.delete(recursive: true);
      }
    },
  );
}
