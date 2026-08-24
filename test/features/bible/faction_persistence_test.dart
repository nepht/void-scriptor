import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/bible/application/faction_repository.dart';
import 'package:void_scriptor/features/bible/domain/faction.dart';

void main() {
  test('faction persists as a project worldbuilding entity', () async {
    final root = await Directory.systemTemp.createTemp('s21-faction-');
    addTearDown(() => root.delete(recursive: true));
    final dbPath = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(dbPath);

    final first = await service.open(dbPath);
    await FactionRepository(first).save(
      const FactionModel(
        assetId: 'faction-1',
        projectId: 'project-1',
        name: 'Clan Kokuen',
        description: 'A void clan.',
        ideology: 'Preserve the Void',
        status: 'destroyed',
        headquarters: 'Mountain Region',
      ),
    );
    await first.close();

    final second = await service.open(dbPath);
    addTearDown(second.close);
    final faction = await FactionRepository(second).get('faction-1');

    expect(second.schemaVersion, 56);
    expect(faction?.name, 'Clan Kokuen');
    expect(faction?.status, 'destroyed');
    expect(faction?.headquarters, 'Mountain Region');
  });
}
