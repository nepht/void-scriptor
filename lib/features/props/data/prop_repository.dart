import 'package:drift/drift.dart';
import '../../../database/project/project_database.dart';
import '../../../database/project/tables/props.dart';
import '../domain/prop_model.dart' as domain;
part 'prop_repository.g.dart';

@DriftAccessor(tables: [Props, PropSpecifications, PropStates])
class PropRepository extends DatabaseAccessor<ProjectDatabase>
    with _$PropRepositoryMixin {
  PropRepository(super.db);

  Future<List<domain.PropModel>> listForProject(String projectId) async {
    final rows =
        await (select(props)
              ..where((row) => row.projectId.equals(projectId))
              ..orderBy([(row) => OrderingTerm.asc(row.name)]))
            .get();
    return [
      for (final row in rows)
        domain.PropModel(
          assetId: row.assetId,
          projectId: row.projectId,
          name: row.name,
          category: domain.PropCategory.values.firstWhere(
            (value) => value.name == row.category,
            orElse: () => domain.PropCategory.other,
          ),
          description: row.description,
          function: row.function,
          storyCritical: row.storyCritical,
        ),
    ];
  }

  Future<domain.PropModel?> getProp(String id) async {
    final r = await (select(
      props,
    )..where((x) => x.assetId.equals(id))).getSingleOrNull();
    return r == null
        ? null
        : domain.PropModel(
            assetId: r.assetId,
            projectId: r.projectId,
            name: r.name,
            category: domain.PropCategory.values.firstWhere(
              (x) => x.name == r.category,
              orElse: () => domain.PropCategory.other,
            ),
            description: r.description,
            function: r.function,
            storyCritical: r.storyCritical,
          );
  }

  Future<void> saveSpecification(domain.PropSpecification v) =>
      into(propSpecifications).insertOnConflictUpdate(
        PropSpecificationsCompanion.insert(
          propId: v.propId,
          widthCm: Value(v.widthCm),
          heightCm: Value(v.heightCm),
          depthCm: Value(v.depthCm),
          weightKg: Value(v.weightKg),
          material: Value(v.material),
          color: Value(v.color),
        ),
      );
  Future<domain.PropSpecification?> getSpecification(String id) async {
    final r = await (select(
      propSpecifications,
    )..where((x) => x.propId.equals(id))).getSingleOrNull();
    return r == null
        ? null
        : domain.PropSpecification(
            propId: r.propId,
            widthCm: r.widthCm,
            heightCm: r.heightCm,
            depthCm: r.depthCm,
            weightKg: r.weightKg,
            material: r.material,
            color: r.color,
          );
  }

  Future<void> saveState(domain.PropStateModel v) =>
      into(propStates).insertOnConflictUpdate(
        PropStatesCompanion.insert(
          id: v.id,
          propId: v.propId,
          name: v.name,
          description: Value(v.description),
          referenceSetId: Value(v.referenceSetId),
          sortOrder: Value(v.sortOrder),
        ),
      );
  Future<List<domain.PropStateModel>> statesFor(String id) async => [
    for (final r
        in await (select(propStates)
              ..where((x) => x.propId.equals(id))
              ..orderBy([(x) => OrderingTerm.asc(x.sortOrder)]))
            .get())
      domain.PropStateModel(
        id: r.id,
        propId: r.propId,
        name: r.name,
        description: r.description,
        referenceSetId: r.referenceSetId,
        sortOrder: r.sortOrder,
      ),
  ];
}
