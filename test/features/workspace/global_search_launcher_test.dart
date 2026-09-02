// Journey proof for step 145.27 (Core Worldbuilding Reduction): one global
// search entry point must surface Characters, Locations (Environments), Story
// assets, and Factions from a live project session, scoped to that project.
// Factions live in their own Factions table (no universal Assets row), so the
// launcher merges both sources deterministically.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/bible/application/create_faction_service.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/environment/application/create_environment_service.dart';
import 'package:void_scriptor/features/environment/domain/environment_type.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/workspace/application/global_search_launcher.dart';

void main() {
  test(
    'launcher merges characters, environments, stories, and factions in one query',
    () async {
      final root = await Directory.systemTemp.createTemp('s27-globalsearch-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Global Search Journey');
      final session = await ProjectSessionManager().open(package);
      addTearDown(session.close);
      final db = session.database;
      final projectId = package.projectId;

      await CharacterRepositoryImpl(
        database: db,
        projectId: projectId,
        paths: ProjectPaths(rootDirectory: root.parent),
      ).createCharacter(name: 'Qowner');
      await CreateEnvironmentService(
        database: db,
        paths: ProjectPaths(rootDirectory: root.parent),
      ).create(
        projectId: projectId,
        name: 'Pole of Creation',
        type: EnvironmentType.landscape,
      );
      await CreateStoryService(
        database: db,
        paths: ProjectPaths(rootDirectory: root.parent),
      ).createStory(projectId: projectId, title: 'Void Cube');
      await const CreateFactionService().create(
        db,
        projectId: projectId,
        name: 'Polar Council',
      );

      final launcher = GlobalSearchLauncher(database: db);

      // One query must cross all four Core domains.
      final hits = await launcher.search('o', projectId: projectId, limit: 10);
      final names = hits.map((hit) => hit.title).toSet();
      expect(
        names,
        containsAll(<String>[
          'Qowner',
          'Pole of Creation',
          'Void Cube',
          'Polar Council',
        ]),
      );

      // Case-insensitive, per-domain filtering keeps scope honest.
      final characters = await launcher.search(
        'qowner',
        projectId: projectId,
        limit: 10,
        types: const {AssetType.character},
      );
      expect(characters, hasLength(1));
      expect(characters.single.title, 'Qowner');

      // Project scoping: a second project must not leak rows.
      final otherPackage = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Other Project');
      final otherSession = await ProjectSessionManager().open(otherPackage);
      addTearDown(otherSession.close);
      await const CreateFactionService().create(
        otherSession.database,
        projectId: otherPackage.projectId,
        name: 'Polar Council Rival',
      );
      final otherHits = await GlobalSearchLauncher(
        database: otherSession.database,
      ).search('polar', projectId: otherPackage.projectId, limit: 10);
      expect(otherHits.map((hit) => hit.title), ['Polar Council Rival']);

      // Empty query yields nothing: the sheet must not render a firehose.
      final empty = await launcher.search('', projectId: projectId, limit: 10);
      expect(empty, isEmpty);
    },
  );
}
