import 'package:drift/drift.dart';

import '../project_database.dart';
import '../tables/wardrobes.dart';
import '../tables/wardrobe_components.dart';
import '../tables/wardrobe_colors.dart';
import '../tables/wardrobe_variants.dart';
import '../tables/wardrobe_references.dart';

part 'wardrobe_dao.g.dart';

@DriftAccessor(
  tables: [
    Wardrobes,
    WardrobeComponents,
    WardrobeColors,
    WardrobeVariants,
    WardrobeReferences,
  ],
)
class WardrobeDao extends DatabaseAccessor<ProjectDatabase>
    with _$WardrobeDaoMixin {
  WardrobeDao(super.db);

  Future<Wardrobe?> getWardrobe(String assetId) => (select(
    wardrobes,
  )..where((row) => row.assetId.equals(assetId))).getSingleOrNull();

  Future<List<Wardrobe>> getWardrobes(String projectId) => (select(
    wardrobes,
  )..where((row) => row.projectId.equals(projectId))).get();

  Future<void> insertWardrobe(WardrobesCompanion entry) =>
      into(wardrobes).insert(entry);

  Future<WardrobeVariant?> getDefaultVariant(String wardrobeId) =>
      (select(wardrobeVariants)
            ..where((row) => row.wardrobeId.equals(wardrobeId))
            ..where((row) => row.isDefault.equals(true)))
          .getSingleOrNull();

  Future<List<WardrobeComponent>> getComponents(String wardrobeId) =>
      (select(wardrobeComponents)
            ..where((row) => row.wardrobeId.equals(wardrobeId))
            ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
          .get();

  Future<List<WardrobeColor>> getColors(String wardrobeId) =>
      (select(wardrobeColors)
            ..where((row) => row.wardrobeId.equals(wardrobeId))
            ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
          .get();

  Future<List<WardrobeVariant>> getVariants(String wardrobeId) => (select(
    wardrobeVariants,
  )..where((row) => row.wardrobeId.equals(wardrobeId))).get();

  Future<List<WardrobeReference>> getReferences(String wardrobeId) =>
      (select(wardrobeReferences)
            ..where((row) => row.wardrobeId.equals(wardrobeId))
            ..orderBy([(row) => OrderingTerm.asc(row.priority)]))
          .get();
}
