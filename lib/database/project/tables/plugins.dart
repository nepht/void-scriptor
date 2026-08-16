import 'package:drift/drift.dart';

/// Installed plugins (Step 31.13).
class Plugins extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get version => text()();
  TextColumn get author => text()();
  TextColumn get apiVersion => text()();
  TextColumn get manifestJson => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get installedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Per-plugin settings key-value (Step 31.13).
class PluginSettings extends Table {
  TextColumn get pluginId => text()();
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {pluginId, key};
}
