// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wardrobe_dao.dart';

// ignore_for_file: type=lint
mixin _$WardrobeDaoMixin on DatabaseAccessor<ProjectDatabase> {
  $WardrobesTable get wardrobes => attachedDatabase.wardrobes;
  $WardrobeComponentsTable get wardrobeComponents =>
      attachedDatabase.wardrobeComponents;
  $WardrobeColorsTable get wardrobeColors => attachedDatabase.wardrobeColors;
  $WardrobeVariantsTable get wardrobeVariants =>
      attachedDatabase.wardrobeVariants;
  $WardrobeReferencesTable get wardrobeReferences =>
      attachedDatabase.wardrobeReferences;
  WardrobeDaoManager get managers => WardrobeDaoManager(this);
}

class WardrobeDaoManager {
  final _$WardrobeDaoMixin _db;
  WardrobeDaoManager(this._db);
  $$WardrobesTableTableManager get wardrobes =>
      $$WardrobesTableTableManager(_db.attachedDatabase, _db.wardrobes);
  $$WardrobeComponentsTableTableManager get wardrobeComponents =>
      $$WardrobeComponentsTableTableManager(
        _db.attachedDatabase,
        _db.wardrobeComponents,
      );
  $$WardrobeColorsTableTableManager get wardrobeColors =>
      $$WardrobeColorsTableTableManager(
        _db.attachedDatabase,
        _db.wardrobeColors,
      );
  $$WardrobeVariantsTableTableManager get wardrobeVariants =>
      $$WardrobeVariantsTableTableManager(
        _db.attachedDatabase,
        _db.wardrobeVariants,
      );
  $$WardrobeReferencesTableTableManager get wardrobeReferences =>
      $$WardrobeReferencesTableTableManager(
        _db.attachedDatabase,
        _db.wardrobeReferences,
      );
}
