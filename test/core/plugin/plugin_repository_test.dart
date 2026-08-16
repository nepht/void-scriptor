import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/core/plugin/domain/plugin_manifest.dart';
import 'package:void_scriptor/core/plugin/application/plugin_repository.dart';

void main() {
  PluginManifest manifest(String id) => PluginManifest.fromJson({
    'id': id,
    'name': 'Name $id',
    'version': '1.0.0',
    'author': 'a',
    'apiVersion': '1.0',
    'capabilities': ['ui'],
    'permissions': ['storage'],
    'entrypoint': 'main.dart',
  });

  test('save and load plugin descriptor', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PluginRepository(database: db);

    await repo.savePlugin(manifest('com.example.a'));
    final plugins = await repo.listPlugins();
    expect(plugins, hasLength(1));
    expect(plugins.first.id, 'com.example.a');
    expect(plugins.first.status, PluginStatus.disabled);
  });

  test('setEnabled persists state', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PluginRepository(database: db);

    await repo.savePlugin(manifest('com.example.a'));
    await repo.setEnabled('com.example.a', true);
    final plugins = await repo.listPlugins();
    expect(plugins.first.status, PluginStatus.enabled);
  });

  test('settings persist per plugin', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PluginRepository(database: db);

    await repo.savePlugin(manifest('com.example.a'));
    await repo.setSetting('com.example.a', 'theme', 'dark');
    expect(await repo.getSetting('com.example.a', 'theme'), 'dark');
    expect((await repo.settingsFor('com.example.a'))['theme'], 'dark');
  });

  test(
    'restart persistence: close and reopen keeps plugin + settings',
    () async {
      final dir = Directory.systemTemp.createTempSync('vs_plugin_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/project.db');

      final db = ProjectDatabase(NativeDatabase(file));
      final repo = PluginRepository(database: db);
      await repo.savePlugin(manifest('com.example.a'));
      await repo.setEnabled('com.example.a', true);
      await repo.setSetting('com.example.a', 'k', 'v');
      await db.close();

      final db2 = ProjectDatabase(NativeDatabase(file));
      addTearDown(db2.close);
      final repo2 = PluginRepository(database: db2);
      final plugins = await repo2.listPlugins();
      expect(plugins, hasLength(1));
      expect(plugins.first.id, 'com.example.a');
      expect(plugins.first.status, PluginStatus.enabled);
      expect(await repo2.getSetting('com.example.a', 'k'), 'v');
    },
  );
}
