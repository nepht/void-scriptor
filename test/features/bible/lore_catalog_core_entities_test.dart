import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:drift/drift.dart' show Value;
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/bible/application/create_lore_entity_service.dart';
import 'package:uuid/uuid.dart';

/// Step 145.27 Core Worldbuilding Reduction (gap 145.29 unified catalog):
/// katalog lore-link autocomplete harus menyatukan enam entitas prioritas
/// Core, termasuk Characters, Environments/Locations, dan Factions, dan
/// tetap ter-scope per proyek.
void main() {
  late Directory root;
  late ProjectDatabase database;

  setUp(() async {
    root = Directory(
      '${Directory.systemTemp.path}/s145-27-lore-catalog-${DateTime.now().microsecondsSinceEpoch}',
    );
    await root.create(recursive: true);
    final paths = ProjectPaths(rootDirectory: root);
    final service = ProjectDatabaseService();
    final dbPath = (await paths.database('project-1')).path;
    await service.create(dbPath);
    database = await service.open(dbPath);
  });

  tearDown(() async {
    await database.close();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    root.deleteSync(recursive: true);
  });

  test('loadCatalog unifies characters, environments, and factions', () async {
    await database
        .into(database.characters)
        .insert(
          CharactersCompanion.insert(
            assetId: 'char-1',
            projectId: 'project-1',
            displayName: 'Qowner',
            biography: const Value('Penjaga Kubiasi'),
          ),
        );
    await database
        .into(database.environments)
        .insert(
          EnvironmentsCompanion.insert(
            assetId: 'env-1',
            projectId: 'project-1',
            name: 'Kutub Penciptaan',
            description: const Value('Gurun es tempat Void Cube lahir'),
          ),
        );
    await database
        .into(database.factions)
        .insert(
          FactionsCompanion.insert(
            assetId: 'fac-1',
            projectId: 'project-1',
            name: 'Penjaga Kutub',
            ideology: const Value('Melindungi keseimbangan Void Cube'),
          ),
        );

    final catalog = await const CreateLoreEntityService().loadCatalog(
      database,
      'project-1',
    );

    final byName = {for (final ref in catalog) ref.name: ref};

    expect(byName['Qowner']!.kind, 'character');
    expect(byName['Qowner']!.id, 'char-1');
    expect(byName['Qowner']!.detail, 'Penjaga Kubiasi');

    expect(byName['Kutub Penciptaan']!.kind, 'environment');
    expect(byName['Kutub Penciptaan']!.id, 'env-1');
    expect(
      byName['Kutub Penciptaan']!.detail,
      'Gurun es tempat Void Cube lahir',
    );

    expect(byName['Penjaga Kutub']!.kind, 'faction');
    expect(byName['Penjaga Kutub']!.id, 'fac-1');
    expect(
      byName['Penjaga Kutub']!.detail,
      'Melindungi keseimbangan Void Cube',
    );
  });

  test('loadCatalog stays project-scoped', () async {
    await database
        .into(database.characters)
        .insert(
          CharactersCompanion.insert(
            assetId: 'char-a',
            projectId: 'project-1',
            displayName: 'Satria Api',
          ),
        );
    await database
        .into(database.characters)
        .insert(
          CharactersCompanion.insert(
            assetId: 'char-b',
            projectId: 'project-2',
            displayName: 'Bocah Proyek Lain',
          ),
        );
    await database
        .into(database.factions)
        .insert(
          FactionsCompanion.insert(
            assetId: 'fac-a',
            projectId: 'project-1',
            name: 'Faksi Api',
          ),
        );
    await database
        .into(database.factions)
        .insert(
          FactionsCompanion.insert(
            assetId: 'fac-b',
            projectId: 'project-2',
            name: 'Faksi Lain',
          ),
        );

    final catalog = await const CreateLoreEntityService().loadCatalog(
      database,
      'project-1',
    );

    expect(catalog.map((e) => e.name), contains('Satria Api'));
    expect(catalog.map((e) => e.name), contains('Faksi Api'));
    expect(catalog.map((e) => e.name), isNot(contains('Bocah Proyek Lain')));
    expect(catalog.map((e) => e.name), isNot(contains('Faksi Lain')));
  });

  test('duplicate lore creation is blocked by a character name too', () async {
    await database
        .into(database.characters)
        .insert(
          CharactersCompanion.insert(
            assetId: const Uuid().v4(),
            projectId: 'project-1',
            displayName: 'Qowner',
          ),
        );

    const service = CreateLoreEntityService();

    expect(
      service.findExistingName(database, 'project-1', 'qowner'),
      completion('Qowner'),
    );
    await expectLater(
      service.create(database, projectId: 'project-1', name: 'Qowner'),
      throwsStateError,
    );
  });
}
