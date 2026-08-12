import 'package:drift/drift.dart';

import '../project_database.dart';
import '../tables/environments.dart';
import '../tables/environment_zones.dart';
import '../tables/environment_architectures.dart';
import '../tables/environment_weather_profiles.dart';
import '../tables/environment_lighting_profiles.dart';
import '../tables/environment_colors.dart';
import '../tables/environment_props.dart';
import '../tables/environment_continuity_states.dart';
import '../tables/environment_physics_profiles.dart';
import '../tables/environment_references.dart';

part 'environment_dao.g.dart';

@DriftAccessor(
  tables: [
    Environments,
    EnvironmentZones,
    EnvironmentArchitectures,
    EnvironmentWeatherProfiles,
    EnvironmentLightingProfiles,
    EnvironmentColors,
    EnvironmentProps,
    EnvironmentContinuityStates,
    EnvironmentPhysicsProfiles,
    EnvironmentReferences,
  ],
)
class EnvironmentDao extends DatabaseAccessor<ProjectDatabase>
    with _$EnvironmentDaoMixin {
  EnvironmentDao(super.db);

  Future<List<Environment>> getEnvironments(String projectId) =>
      (select(environments)
            ..where((row) => row.projectId.equals(projectId))
            ..orderBy([(row) => OrderingTerm(expression: row.name)]))
          .get();

  Future<Environment?> getEnvironment(String assetId) => (select(
    environments,
  )..where((row) => row.assetId.equals(assetId))).getSingleOrNull();

  Future<void> insertEnvironment(EnvironmentsCompanion environment) =>
      into(environments).insert(environment);

  Future<List<EnvironmentZone>> getZones(String environmentId) =>
      (select(environmentZones)
            ..where((row) => row.environmentId.equals(environmentId))
            ..orderBy([(row) => OrderingTerm(expression: row.sortOrder)]))
          .get();

  Future<List<EnvironmentWeatherProfile>> getWeatherProfiles(
    String environmentId,
  ) =>
      (select(environmentWeatherProfiles)
            ..where((row) => row.environmentId.equals(environmentId))
            ..orderBy([
              (row) => OrderingTerm(
                expression: row.isDefault,
                mode: OrderingMode.desc,
              ),
            ]))
          .get();

  Future<List<EnvironmentLightingProfile>> getLightingProfiles(
    String environmentId,
  ) => (select(
    environmentLightingProfiles,
  )..where((row) => row.environmentId.equals(environmentId))).get();

  Future<List<EnvironmentProp>> getProps(String environmentId) => (select(
    environmentProps,
  )..where((row) => row.environmentId.equals(environmentId))).get();

  Future<List<EnvironmentContinuityState>> getContinuityStates(
    String environmentId,
  ) =>
      (select(environmentContinuityStates)
            ..where((row) => row.environmentId.equals(environmentId))
            ..orderBy([(row) => OrderingTerm(expression: row.createdAt)]))
          .get();

  Future<List<EnvironmentReference>> getReferences(String environmentId) =>
      (select(environmentReferences)
            ..where((row) => row.environmentId.equals(environmentId))
            ..orderBy([(row) => OrderingTerm(expression: row.priority)]))
          .get();

  Future<void> removeEnvironmentData(String assetId) async {
    await (delete(
      environmentZones,
    )..where((row) => row.environmentId.equals(assetId))).go();
    await (delete(
      environmentArchitectures,
    )..where((row) => row.environmentId.equals(assetId))).go();
    await (delete(
      environmentWeatherProfiles,
    )..where((row) => row.environmentId.equals(assetId))).go();
    await (delete(
      environmentLightingProfiles,
    )..where((row) => row.environmentId.equals(assetId))).go();
    await (delete(
      environmentColors,
    )..where((row) => row.environmentId.equals(assetId))).go();
    await (delete(
      environmentProps,
    )..where((row) => row.environmentId.equals(assetId))).go();
    await (delete(
      environmentContinuityStates,
    )..where((row) => row.environmentId.equals(assetId))).go();
    await (delete(
      environmentPhysicsProfiles,
    )..where((row) => row.environmentId.equals(assetId))).go();
    await (delete(
      environmentReferences,
    )..where((row) => row.environmentId.equals(assetId))).go();
    await (delete(
      environments,
    )..where((row) => row.assetId.equals(assetId))).go();
  }
}
