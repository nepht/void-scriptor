import 'package:drift/drift.dart';
import 'tables/asset_tags.dart';
import 'tables/asset_relations.dart';
import 'tables/assets.dart';
import 'tables/character_identity_profiles.dart';
import 'tables/character_references.dart';
import 'tables/characters.dart';
import 'tables/wardrobes.dart';
import 'tables/wardrobe_components.dart';
import 'tables/wardrobe_colors.dart';
import 'tables/wardrobe_variants.dart';
import 'tables/wardrobe_references.dart';
import 'daos/asset_dao.dart';
import 'daos/character_dao.dart';
import 'daos/relation_dao.dart';
import 'daos/wardrobe_dao.dart';

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
    Wardrobes,
    WardrobeComponents,
    WardrobeColors,
    WardrobeVariants,
    WardrobeReferences,
  ],
  daos: [AssetDao, CharacterDao, RelationDao, WardrobeDao],
)
class ProjectDatabase extends _$ProjectDatabase {
  ProjectDatabase(super.executor);

  @override
  int get schemaVersion => 4;

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
      if (from < 4) {
        await m.createTable(wardrobes);
        await m.createTable(wardrobeComponents);
        await m.createTable(wardrobeColors);
        await m.createTable(wardrobeVariants);
        await m.createTable(wardrobeReferences);
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
