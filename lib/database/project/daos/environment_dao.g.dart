// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environment_dao.dart';

// ignore_for_file: type=lint
mixin _$EnvironmentDaoMixin on DatabaseAccessor<ProjectDatabase> {
  $EnvironmentsTable get environments => attachedDatabase.environments;
  $EnvironmentZonesTable get environmentZones =>
      attachedDatabase.environmentZones;
  $EnvironmentArchitecturesTable get environmentArchitectures =>
      attachedDatabase.environmentArchitectures;
  $EnvironmentWeatherProfilesTable get environmentWeatherProfiles =>
      attachedDatabase.environmentWeatherProfiles;
  $EnvironmentLightingProfilesTable get environmentLightingProfiles =>
      attachedDatabase.environmentLightingProfiles;
  $EnvironmentColorsTable get environmentColors =>
      attachedDatabase.environmentColors;
  $EnvironmentPropsTable get environmentProps =>
      attachedDatabase.environmentProps;
  $EnvironmentContinuityStatesTable get environmentContinuityStates =>
      attachedDatabase.environmentContinuityStates;
  $EnvironmentPhysicsProfilesTable get environmentPhysicsProfiles =>
      attachedDatabase.environmentPhysicsProfiles;
  $EnvironmentReferencesTable get environmentReferences =>
      attachedDatabase.environmentReferences;
  EnvironmentDaoManager get managers => EnvironmentDaoManager(this);
}

class EnvironmentDaoManager {
  final _$EnvironmentDaoMixin _db;
  EnvironmentDaoManager(this._db);
  $$EnvironmentsTableTableManager get environments =>
      $$EnvironmentsTableTableManager(_db.attachedDatabase, _db.environments);
  $$EnvironmentZonesTableTableManager get environmentZones =>
      $$EnvironmentZonesTableTableManager(
        _db.attachedDatabase,
        _db.environmentZones,
      );
  $$EnvironmentArchitecturesTableTableManager get environmentArchitectures =>
      $$EnvironmentArchitecturesTableTableManager(
        _db.attachedDatabase,
        _db.environmentArchitectures,
      );
  $$EnvironmentWeatherProfilesTableTableManager
  get environmentWeatherProfiles =>
      $$EnvironmentWeatherProfilesTableTableManager(
        _db.attachedDatabase,
        _db.environmentWeatherProfiles,
      );
  $$EnvironmentLightingProfilesTableTableManager
  get environmentLightingProfiles =>
      $$EnvironmentLightingProfilesTableTableManager(
        _db.attachedDatabase,
        _db.environmentLightingProfiles,
      );
  $$EnvironmentColorsTableTableManager get environmentColors =>
      $$EnvironmentColorsTableTableManager(
        _db.attachedDatabase,
        _db.environmentColors,
      );
  $$EnvironmentPropsTableTableManager get environmentProps =>
      $$EnvironmentPropsTableTableManager(
        _db.attachedDatabase,
        _db.environmentProps,
      );
  $$EnvironmentContinuityStatesTableTableManager
  get environmentContinuityStates =>
      $$EnvironmentContinuityStatesTableTableManager(
        _db.attachedDatabase,
        _db.environmentContinuityStates,
      );
  $$EnvironmentPhysicsProfilesTableTableManager
  get environmentPhysicsProfiles =>
      $$EnvironmentPhysicsProfilesTableTableManager(
        _db.attachedDatabase,
        _db.environmentPhysicsProfiles,
      );
  $$EnvironmentReferencesTableTableManager get environmentReferences =>
      $$EnvironmentReferencesTableTableManager(
        _db.attachedDatabase,
        _db.environmentReferences,
      );
}
