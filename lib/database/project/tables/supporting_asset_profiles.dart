import 'package:drift/drift.dart';

/// Type-specific fields for stand-alone Core loadout assets.
///
/// The base [Assets] row remains the shared catalogue identity. This table
/// stores only fields owned by a specialized Armor, Accessory, Item, or Hair
/// Variation editor so those fields never get encoded into description text.
class SupportingAssetProfiles extends Table {
  TextColumn get assetId => text()();
  TextColumn get assetType => text()();

  // Armor fields (first vertical slice).
  TextColumn get protection => text().nullable()();
  TextColumn get material => text().nullable()();
  TextColumn get condition => text().nullable()();

  // Accessory fields.
  TextColumn get category => text().nullable()();
  TextColumn get significance => text().nullable()();

  // Item fields.
  TextColumn get purpose => text().nullable()();
  TextColumn get usageRules => text().nullable()();
  TextColumn get itemState => text().nullable()();

  // Hair Variation fields.
  TextColumn get hairStyle => text().nullable()();
  TextColumn get hairColor => text().nullable()();
  TextColumn get hairLength => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {assetId};
}
