import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';

void main() {
  late Directory root;
  late File databaseFile;
  late ProjectDatabaseService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-s26-index-');
    databaseFile = File('${root.path}/project.db');
    service = ProjectDatabaseService();
  });

  tearDown(() => root.delete(recursive: true));

  test('database exposes hot-query indexes after migration', () async {
    await service.create(databaseFile.path);
    final db = await service.open(databaseFile.path);
    addTearDown(db.close);

    final indexes = await _indexNames(db);

    for (final expected in [
      'idx_assets_project_id',
      'idx_assets_type',
      'idx_assets_name',
      'idx_assets_updated_at',
      'idx_assets_project_type_updated',
      'idx_asset_tags_asset_id',
      'idx_asset_tags_tag',
      'idx_asset_tag_links_asset_id',
      'idx_asset_tag_links_tag_id',
      'idx_asset_relations_source',
      'idx_asset_relations_target',
      'idx_scene_characters_scene_id',
      'idx_timeline_clips_track_id',
      'idx_timeline_clips_start_seconds',
    ]) {
      expect(indexes, contains(expected), reason: 'missing index $expected');
    }
  });

  test('database indexes survive a close and reopen round-trip', () async {
    await service.create(databaseFile.path);
    var db = await service.open(databaseFile.path);
    await db.close();

    db = await service.open(databaseFile.path);
    addTearDown(db.close);
    expect(await _indexNames(db), contains('idx_assets_project_id'));
  });
}

Future<Set<String>> _indexNames(ProjectDatabase db) async {
  final rows = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'",
      )
      .get();
  return rows.map((row) => row.data['name'] as String).toSet();
}
