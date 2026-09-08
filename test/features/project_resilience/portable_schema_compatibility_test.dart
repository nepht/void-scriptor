import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart'
    hide CharacterIdentityProfile;
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/project_resilience/application/portable_project_service.dart';

/// Sprint 145.33 (Portable Import Export) - compatibility/migration policy.
///
/// Evidence slice for the audit gap "Importer membaca schema version tetapi
/// tidak menjalankan migration/compatibility policy". Two version axes are
/// involved in a .voidproject archive:
///   - the manifest format version (VoidProjectFormat.currentSchema = 16),
///     already guarded: a future version is rejected with FormatException
///     (see portable_corrupt_input_test.dart);
///   - the database user_version (ProjectDatabase.currentSchemaVersion = 60),
///     migrated forward by the production open path.
///
/// PASS-first: the behavior below was probed live before this test existed.
/// This file pins the compatibility contract so regressions fail loudly.
void main() {
  late Directory root;
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('hermes-s33-compat-'),
  );
  tearDown(() => root.delete(recursive: true));

  /// Seeds one Core asset + character row at the fresh v59 layout, then
  /// rewinds the structural waves back to v53 so the 53->59 migration
  /// re-applies on open. Mirrors the proven seedV53 recipe in
  /// schema_migration_fixtures_test.dart.
  Future<File> seedV53Database(ProjectPackage package) async {
    final now = DateTime(2026);
    final database = ProjectDatabase(NativeDatabase(package.databaseFile));
    await database.customSelect('SELECT 1').get();
    await database.transaction(() async {
      await database
          .into(database.assets)
          .insert(
            AssetsCompanion.insert(
              id: 'char-1',
              projectId: package.projectId,
              name: 'Qowner',
              type: 'character',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database
          .into(database.characters)
          .insert(
            CharactersCompanion.insert(
              assetId: 'char-1',
              projectId: package.projectId,
              displayName: 'Qowner',
              biography: const Value('born in the Void'),
            ),
          );
    });
    await database.close();

    final rewound = ProjectDatabase(NativeDatabase(package.databaseFile));
    await rewound.customStatement('PRAGMA foreign_keys = OFF');
    await rewound.customStatement(
      'DROP TABLE IF EXISTS creature_ecology_states',
    );
    await rewound.customStatement('DROP TABLE IF EXISTS novel_character_links');
    await rewound.customStatement('DROP TABLE IF EXISTS workflow_definitions');
    await rewound.customStatement('DROP TABLE IF EXISTS workflow_run_records');
    await rewound.customStatement('DROP TABLE IF EXISTS scene_draft_snapshots');
    await rewound.customStatement('ALTER TABLE characters DROP COLUMN voice');
    await rewound.customStatement(
      'DROP TABLE IF EXISTS character_canonical_scopes',
    );
    await rewound.customStatement(
      'DROP TABLE IF EXISTS character_universe_timeline_overrides',
    );
    await rewound.customStatement(
      'DROP TABLE IF EXISTS character_novel_states',
    );
    await rewound.customStatement('PRAGMA user_version = 53');
    await rewound.close();
    return package.databaseFile;
  }

  test(
    'OLD v53 database archive imports and migrates on first production open',
    () async {
      final sourceRoot = Directory('${root.path}/source');
      final package = await ProjectPackageService(
        rootDirectory: sourceRoot,
      ).create(name: 'Compat Old');
      await seedV53Database(package);

      final archive = await PortableProjectExporter().exportPortable(package);
      final imported = await PortableProjectImporter().importArchive(
        archive,
        destination: Directory('${root.path}/dest'),
      );
      expect(
        await File('${imported.root.path}/database/project.db').exists(),
        isTrue,
      );

      final opened = await ProjectDatabaseService().open(
        imported.databaseFile.path,
      );
      final version = await opened
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(
        version.data['user_version'],
        ProjectDatabase.currentSchemaVersion,
        reason: 'the production open path must run the forward migration',
      );
      final assets = await opened.select(opened.assets).get();
      final characters = await opened.select(opened.characters).get();
      expect(assets.single.name, 'Qowner');
      expect(characters.single.displayName, 'Qowner');
      expect(characters.single.biography, 'born in the Void');
      await opened.close();
    },
  );

  test(
    'OLD manifest format (schemaVersion 15) is accepted with forward migration',
    () async {
      final sourceRoot = Directory('${root.path}/source-old');
      final package = await ProjectPackageService(
        rootDirectory: sourceRoot,
      ).create(name: 'Compat Old Format');
      await seedV53Database(package);

      final manifestFile = package.manifestFile;
      final manifestJson =
          jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
      manifestJson['schemaVersion'] =
          (manifestJson['schemaVersion'] as int) - 1;
      await manifestFile.writeAsString(jsonEncode(manifestJson));

      final archive = await PortableProjectExporter().exportPortable(package);
      final imported = await PortableProjectImporter().importArchive(
        archive,
        destination: Directory('${root.path}/dest-old'),
      );

      final importedManifest =
          jsonDecode(await imported.manifestFile.readAsString())
              as Map<String, dynamic>;
      expect(importedManifest['schemaVersion'], 15);

      final opened = await ProjectDatabaseService().open(
        imported.databaseFile.path,
      );
      final version = await opened
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(
        version.data['user_version'],
        ProjectDatabase.currentSchemaVersion,
      );
      final characters = await opened.select(opened.characters).get();
      expect(characters.single.displayName, 'Qowner');
      await opened.close();
    },
  );

  test('CURRENT v59 archive round-trips without needing a migration', () async {
    final sourceRoot = Directory('${root.path}/source-current');
    final package = await ProjectPackageService(
      rootDirectory: sourceRoot,
    ).create(name: 'Compat Current');
    final archive = await PortableProjectExporter().exportPortable(package);
    final imported = await PortableProjectImporter().importArchive(
      archive,
      destination: Directory('${root.path}/dest-current'),
    );

    final opened = await ProjectDatabaseService().open(
      imported.databaseFile.path,
    );
    final version = await opened
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.data['user_version'], ProjectDatabase.currentSchemaVersion);
    final assets = await opened.select(opened.assets).get();
    expect(assets, isEmpty);
    await opened.close();
  });
}
