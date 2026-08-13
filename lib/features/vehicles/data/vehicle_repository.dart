import 'package:drift/drift.dart';
import '../../../database/project/project_database.dart';
import '../../../database/project/tables/vehicles.dart';
import '../domain/vehicle_model.dart' as domain;
part 'vehicle_repository.g.dart';

@DriftAccessor(
  tables: [
    Vehicles,
    VehicleSpecifications,
    VehicleComponents,
    VehicleWeaponMounts,
    VehicleVariants,
  ],
)
class VehicleRepository extends DatabaseAccessor<ProjectDatabase>
    with _$VehicleRepositoryMixin {
  VehicleRepository(super.db);
  Future<domain.VehicleModel?> getVehicle(String id) async {
    final r = await (select(
      vehicles,
    )..where((x) => x.assetId.equals(id))).getSingleOrNull();
    return r == null
        ? null
        : domain.VehicleModel(
            assetId: r.assetId,
            projectId: r.projectId,
            name: r.name,
            category: domain.VehicleCategory.values.firstWhere(
              (x) => x.name == r.category,
              orElse: () => domain.VehicleCategory.other,
            ),
            description: r.description,
            manufacturer: r.manufacturer,
            role: r.role,
          );
  }

  Future<void> saveSpecification(domain.VehicleSpecification v) =>
      into(vehicleSpecifications).insertOnConflictUpdate(
        VehicleSpecificationsCompanion.insert(
          vehicleId: v.vehicleId,
          lengthMeters: Value(v.lengthMeters),
          widthMeters: Value(v.widthMeters),
          heightMeters: Value(v.heightMeters),
          crew: Value(v.crew),
          passengers: Value(v.passengers),
          propulsion: Value(v.propulsion),
          powerSource: Value(v.powerSource),
          maximumSpeed: Value(v.maximumSpeed),
        ),
      );
  Future<domain.VehicleSpecification?> getSpecification(String id) async {
    final r = await (select(
      vehicleSpecifications,
    )..where((x) => x.vehicleId.equals(id))).getSingleOrNull();
    return r == null
        ? null
        : domain.VehicleSpecification(
            vehicleId: r.vehicleId,
            lengthMeters: r.lengthMeters,
            widthMeters: r.widthMeters,
            heightMeters: r.heightMeters,
            crew: r.crew,
            passengers: r.passengers,
            propulsion: r.propulsion,
            powerSource: r.powerSource,
            maximumSpeed: r.maximumSpeed,
          );
  }

  Future<void> saveComponent(domain.VehicleComponentModel v) =>
      into(vehicleComponents).insertOnConflictUpdate(
        VehicleComponentsCompanion.insert(
          id: v.id,
          vehicleId: v.vehicleId,
          name: v.name,
          category: Value(v.category),
          description: Value(v.description),
          sortOrder: Value(v.sortOrder),
        ),
      );
  Future<List<domain.VehicleComponentModel>> componentsFor(String id) async => [
    for (final r
        in await (select(vehicleComponents)
              ..where((x) => x.vehicleId.equals(id))
              ..orderBy([(x) => OrderingTerm.asc(x.sortOrder)]))
            .get())
      domain.VehicleComponentModel(
        id: r.id,
        vehicleId: r.vehicleId,
        name: r.name,
        category: r.category,
        description: r.description,
        sortOrder: r.sortOrder,
      ),
  ];
  Future<void> saveWeaponMount(domain.VehicleWeaponMountModel v) =>
      into(vehicleWeaponMounts).insertOnConflictUpdate(
        VehicleWeaponMountsCompanion.insert(
          id: v.id,
          vehicleId: v.vehicleId,
          weaponId: v.weaponId,
          mountName: v.mountName,
          quantity: Value(v.quantity),
        ),
      );
  Future<List<domain.VehicleWeaponMountModel>> weaponMountsFor(
    String id,
  ) async => [
    for (final r in await (select(
      vehicleWeaponMounts,
    )..where((x) => x.vehicleId.equals(id))).get())
      domain.VehicleWeaponMountModel(
        id: r.id,
        vehicleId: r.vehicleId,
        weaponId: r.weaponId,
        mountName: r.mountName,
        quantity: r.quantity,
      ),
  ];
  Future<void> saveVariant(domain.VehicleVariantModel v) =>
      into(vehicleVariants).insertOnConflictUpdate(
        VehicleVariantsCompanion.insert(
          id: v.id,
          vehicleId: v.vehicleId,
          name: v.name,
          description: Value(v.description),
          referenceSetId: Value(v.referenceSetId),
        ),
      );
  Future<List<domain.VehicleVariantModel>> variantsFor(String id) async => [
    for (final r in await (select(
      vehicleVariants,
    )..where((x) => x.vehicleId.equals(id))).get())
      domain.VehicleVariantModel(
        id: r.id,
        vehicleId: r.vehicleId,
        name: r.name,
        description: r.description,
        referenceSetId: r.referenceSetId,
      ),
  ];
}
