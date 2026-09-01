import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/bible/application/create_faction_service.dart';
import 'package:void_scriptor/features/bible/application/faction_repository.dart';
import 'package:void_scriptor/features/bible/domain/faction.dart';

void main() {
  test('blank faction name is rejected', () async {
    final root = await Directory.systemTemp.createTemp('s145-27-blank-');
    addTearDown(() => root.delete(recursive: true));
    final dbPath = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final db = await service.open(dbPath);
    addTearDown(db.close);

    expect(
      () => const CreateFactionService().create(
        db,
        projectId: 'project-1',
        name: '   ',
      ),
      throwsArgumentError,
    );
  });

  test('duplicate faction name (case-insensitive) is rejected', () async {
    final root = await Directory.systemTemp.createTemp('s145-27-dup-');
    addTearDown(() => root.delete(recursive: true));
    final dbPath = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final db = await service.open(dbPath);
    addTearDown(db.close);

    await const CreateFactionService().create(
      db,
      projectId: 'project-1',
      name: 'Clan Kokuen',
    );

    await expectLater(
      const CreateFactionService().create(
        db,
        projectId: 'project-1',
        name: '  clan kokuen ',
      ),
      throwsStateError,
    );
  });

  test('created faction persists and is listed after restart', () async {
    final root = await Directory.systemTemp.createTemp('s145-27-create-');
    addTearDown(() => root.delete(recursive: true));
    final dbPath = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(dbPath);

    final first = await service.open(dbPath);
    final created = await const CreateFactionService().create(
      first,
      projectId: 'project-1',
      name: 'Clan Kokuen',
      ideology: 'Preserve the Void',
      status: 'active',
      headquarters: 'Mountain Region',
    );
    expect(created.assetId, isNotEmpty);
    expect(created.assetId, isNot('project-1'));
    expect(created.name, 'Clan Kokuen');
    await first.close();

    final second = await service.open(dbPath);
    addTearDown(second.close);
    final factions = await FactionRepository(
      second,
    ).listForProject('project-1');
    expect(factions, hasLength(1));
    expect(factions.single.assetId, created.assetId);
    expect(factions.single.ideology, 'Preserve the Void');
    expect(factions.single.status, 'active');
    expect(factions.single.headquarters, 'Mountain Region');

    final fetched = await FactionRepository(second).get(created.assetId);
    expect(fetched?.name, 'Clan Kokuen');
  });

  test('listForProject only returns factions of the given project', () async {
    final root = await Directory.systemTemp.createTemp('s145-27-scope-');
    addTearDown(() => root.delete(recursive: true));
    final dbPath = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final db = await service.open(dbPath);
    addTearDown(db.close);

    await FactionRepository(db).save(
      const FactionModel(
        assetId: 'faction-a',
        projectId: 'project-1',
        name: 'Alpha Clan',
      ),
    );
    await FactionRepository(db).save(
      const FactionModel(
        assetId: 'faction-b',
        projectId: 'project-2',
        name: 'Beta Clan',
      ),
    );

    final projectOne = await FactionRepository(db).listForProject('project-1');
    expect(projectOne.map((f) => f.name), ['Alpha Clan']);
  });
}
