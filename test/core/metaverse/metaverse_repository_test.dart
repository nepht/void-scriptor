import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/core/metaverse/persistence/metaverse_repository.dart';

void main() {
  test('saveWorld and listWorlds roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = MetaverseRepository(database: db);

    await repo.saveWorld(id: 'w1', name: 'Void Cube', description: 'universe');
    final worlds = await repo.listWorlds();
    expect(worlds, hasLength(1));
    expect(worlds.first.name, 'Void Cube');
  });

  test('saveZone and listZones roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = MetaverseRepository(database: db);

    await repo.saveZone(
      id: 'z1',
      worldId: 'w1',
      regionId: 'r1',
      name: 'Frozen Pole',
      x: 0,
      y: 0,
      z: 0,
    );
    final zones = await repo.listZones('w1');
    expect(zones, hasLength(1));
    expect(zones.first.name, 'Frozen Pole');
  });

  test('restart persistence keeps worlds', () async {
    final dir = Directory.systemTemp.createTempSync('vs_meta_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/project.db');

    final db = ProjectDatabase(NativeDatabase(file));
    final repo = MetaverseRepository(database: db);
    await repo.saveWorld(id: 'w1', name: 'Void Cube', description: 'universe');
    await db.close();

    final db2 = ProjectDatabase(NativeDatabase(file));
    addTearDown(db2.close);
    final repo2 = MetaverseRepository(database: db2);
    expect((await repo2.listWorlds()), hasLength(1));
  });
}
