import 'package:drift/drift.dart';

/// Character Scope Layers (Step 145.26, core_mvp_scope_reset_spec.json
/// character_model.layers). One table per layer; every column is nullable so
/// null always means "inherit from the layer below". Each table only carries
/// fields owned by its layer, so a scoped write physically cannot mutate a
/// different layer (override_never_silently_mutates_canonical).
class CharacterCanonicalScopes extends Table {
  TextColumn get characterId => text()();
  TextColumn get identity => text().nullable()();
  TextColumn get baseVoice => text().nullable()();
  TextColumn get baseVisualProfile => text().nullable()();
  TextColumn get baseRelationReferences => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {characterId};
}

class CharacterUniverseTimelineOverrides extends Table {
  TextColumn get characterId => text()();
  TextColumn get alternateHistory => text().nullable()();
  TextColumn get alternateRelationships => text().nullable()();
  TextColumn get eraSpecificFacts => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {characterId};
}

class CharacterNovelStates extends Table {
  TextColumn get characterId => text()();
  TextColumn get role => text().nullable()();
  TextColumn get arc => text().nullable()();
  TextColumn get currentLocation => text().nullable()();
  TextColumn get currentAge => text().nullable()();
  TextColumn get currentStatus => text().nullable()();
  TextColumn get scenePov => text().nullable()();
  TextColumn get novelRelationState => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {characterId};
}
