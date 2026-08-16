import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';
import '../domain/plugin_manifest.dart';

/// Persists installed plugins and their settings (Step 31.14).
class PluginRepository {
  PluginRepository({required this.database});

  final ProjectDatabase database;

  Future<void> savePlugin(PluginManifest manifest) async {
    await database
        .into(database.plugins)
        .insertOnConflictUpdate(
          PluginsCompanion.insert(
            id: manifest.id,
            name: manifest.name,
            version: manifest.version,
            author: manifest.author,
            apiVersion: manifest.apiVersion.toString(),
            manifestJson: jsonEncode(manifest.toJson()),
            installedAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<List<PluginDescriptor>> listPlugins() async {
    final rows = await database.select(database.plugins).get();
    return rows
        .map(
          (row) => PluginDescriptor(
            manifest: PluginManifest.fromJson(
              jsonDecode(row.manifestJson) as Map<String, dynamic>,
            ),
            status: row.enabled ? PluginStatus.enabled : PluginStatus.disabled,
          ),
        )
        .toList();
  }

  Future<void> setEnabled(String pluginId, bool enabled) async {
    await (database.update(database.plugins)
          ..where((row) => row.id.equals(pluginId)))
        .write(PluginsCompanion(enabled: Value(enabled)));
  }

  Future<void> setSetting(String pluginId, String key, String value) async {
    await database
        .into(database.pluginSettings)
        .insertOnConflictUpdate(
          PluginSettingsCompanion.insert(
            pluginId: pluginId,
            key: key,
            value: value,
          ),
        );
  }

  Future<String?> getSetting(String pluginId, String key) async {
    final query = database.select(database.pluginSettings)
      ..where((row) => row.pluginId.equals(pluginId) & row.key.equals(key));
    final rows = await query.get();
    return rows.isEmpty ? null : rows.single.value;
  }

  Future<Map<String, String>> settingsFor(String pluginId) async {
    final query = database.select(database.pluginSettings)
      ..where((row) => row.pluginId.equals(pluginId));
    final rows = await query.get();
    return {for (final row in rows) row.key: row.value};
  }
}
