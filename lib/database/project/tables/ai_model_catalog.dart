import 'package:drift/drift.dart';

/// Caches provider model catalogs (Step 28.10).
class AiModelCatalog extends Table {
  TextColumn get providerId => text()();
  TextColumn get modelId => text()();
  TextColumn get capabilitiesJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {providerId, modelId};
}
