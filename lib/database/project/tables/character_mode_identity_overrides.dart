import 'package:drift/drift.dart';

class CharacterModeIdentityOverrides extends Table {
  TextColumn get modeId => text()();
  BoolColumn get faceLock => boolean().nullable()();
  BoolColumn get hairLock => boolean().nullable()();
  BoolColumn get bodyLock => boolean().nullable()();
  BoolColumn get colorLock => boolean().nullable()();
  BoolColumn get outfitLock => boolean().nullable()();
  BoolColumn get weaponLock => boolean().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {modeId};
}
