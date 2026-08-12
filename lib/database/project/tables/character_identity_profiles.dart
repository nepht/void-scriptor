import 'package:drift/drift.dart';

class CharacterIdentityProfiles extends Table {
  TextColumn get characterId => text()();
  BoolColumn get faceLock => boolean().withDefault(const Constant(true))();
  BoolColumn get hairLock => boolean().withDefault(const Constant(true))();
  BoolColumn get bodyLock => boolean().withDefault(const Constant(true))();
  BoolColumn get colorLock => boolean().withDefault(const Constant(true))();
  BoolColumn get outfitLock => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {characterId};
}
