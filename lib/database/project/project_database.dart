import 'package:drift/drift.dart';
import 'tables/asset_tags.dart';
import 'tables/asset_relations.dart';
import 'tables/assets.dart';
import 'tables/character_identity_profiles.dart';
import 'tables/character_references.dart';
import 'tables/characters.dart';
import 'daos/asset_dao.dart';
import 'daos/character_dao.dart';
import 'daos/relation_dao.dart';

part 'project_database.g.dart';

class ProjectMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    ProjectMetadata,
    Assets,
    AssetTags,
    Characters,
    CharacterIdentityProfiles,
    CharacterReferences,
    AssetRelations,
  ],
  daos: [AssetDao, CharacterDao, RelationDao],
)
class ProjectDatabase extends _$ProjectDatabase {
  ProjectDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(assets);
        await m.createTable(assetTags);
        await m.createTable(characters);
        await m.createTable(characterIdentityProfiles);
        await m.createTable(characterReferences);
        await m.createTable(assetRelations);
      }
      if (from >= 2 && from < 3) {
        await m.addColumn(assetRelations, assetRelations.projectId);
        await m.addColumn(assetRelations, assetRelations.createdAt);
      }
    },
  );

  Future<void> initialize() async {
    await customStatement(
      'INSERT OR IGNORE INTO project_metadata (key, value) VALUES (?, ?)',
      ['schemaVersion', schemaVersion.toString()],
    );
  }
}
