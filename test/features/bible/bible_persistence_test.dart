import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/bible/application/bible_repository.dart';
import 'package:void_scriptor/features/bible/domain/bible_entry.dart';

void main() {
  test('Bible entries survive project database restart', () async {
    final root = await Directory.systemTemp.createTemp('s21-bible-');
    addTearDown(() => root.delete(recursive: true));
    final dbPath = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(dbPath);

    final first = await service.open(dbPath);
    final repository = BibleRepository(first);
    final now = DateTime.utc(2026, 8, 13);
    await repository.saveEntry(
      BibleEntry(
        id: 'entry-1',
        projectId: 'project-1',
        type: BibleEntryType.faction,
        title: 'Clan Kokuen',
        content: 'A surviving void clan.',
        createdAt: now,
        updatedAt: now,
        tags: ['clan', 'void'],
      ),
    );
    await first.close();

    final second = await service.open(dbPath);
    addTearDown(second.close);
    final entries = await BibleRepository(second).listEntries('project-1');

    expect(second.schemaVersion, 59);
    expect(entries.single.title, 'Clan Kokuen');
    expect(entries.single.type, BibleEntryType.faction);
    expect(entries.single.tags, ['clan', 'void']);
  });
}
