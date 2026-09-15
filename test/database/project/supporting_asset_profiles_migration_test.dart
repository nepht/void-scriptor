import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';

void main() {
  test('migration 61 to 62 adds profiles without losing assets', () async {
    final root = await Directory.systemTemp.createTemp(
      'vs-asset-profile-migration-',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final file = File('${root.path}/project.db');

    var database = ProjectDatabase(NativeDatabase(file));
    await database
        .into(database.assets)
        .insert(
          AssetsCompanion.insert(
            id: 'armor-legacy',
            projectId: 'project-legacy',
            type: 'armor',
            name: 'Legacy Armor',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        );
    await database.customStatement('DROP TABLE supporting_asset_profiles');
    await database.customStatement('PRAGMA user_version = 61');
    await database.close();

    database = ProjectDatabase(NativeDatabase(file));
    addTearDown(database.close);

    final legacyAsset = await (database.select(
      database.assets,
    )..where((row) => row.id.equals('armor-legacy'))).getSingle();
    expect(legacyAsset.name, 'Legacy Armor');

    await database
        .into(database.supportingAssetProfiles)
        .insert(
          SupportingAssetProfilesCompanion.insert(
            assetId: 'armor-legacy',
            assetType: 'armor',
            protection: const Value('Plate'),
          ),
        );
    final profile = await database
        .select(database.supportingAssetProfiles)
        .getSingle();
    expect(profile.protection, 'Plate');

    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.data['user_version'], ProjectDatabase.currentSchemaVersion);
  });
}
