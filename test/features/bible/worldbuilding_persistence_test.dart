import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart'
    show ProjectDatabase;
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/bible/application/worldbuilding_repository.dart';
import 'package:void_scriptor/features/bible/domain/power_system.dart';
import 'package:void_scriptor/features/bible/domain/species.dart';
import 'package:void_scriptor/features/bible/domain/technology.dart';

void main() {
  test('species technology and power system survive restart', () async {
    final root = await Directory.systemTemp.createTemp('s21-world-');
    addTearDown(() => root.delete(recursive: true));
    final dbPath = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(dbPath);

    final first = await service.open(dbPath);
    final repository = WorldbuildingRepository(first);
    await repository.saveSpecies(
      const SpeciesModel(
        assetId: 'species-1',
        projectId: 'project-1',
        name: 'Voidborn',
        origin: 'The Abyss',
      ),
    );
    await repository.saveTechnology(
      const TechnologyModel(
        assetId: 'technology-1',
        projectId: 'project-1',
        name: 'Void Drive',
        category: 'transport',
      ),
    );
    await repository.savePowerSystem(
      const PowerSystemModel(
        assetId: 'power-1',
        projectId: 'project-1',
        name: 'Void Black',
        source: 'Abyssal',
      ),
    );
    await repository.saveAbility(
      const PowerAbilityModel(
        id: 'ability-1',
        powerSystemId: 'power-1',
        name: 'Void Blade',
        sortOrder: 1,
      ),
    );
    await first.close();

    final second = await service.open(dbPath);
    addTearDown(second.close);
    final reopened = WorldbuildingRepository(second);
    final species = await reopened.getSpecies('species-1');
    final power = await reopened.getPowerSystem('power-1');
    final abilities = await reopened.abilitiesFor('power-1');

    expect(second.schemaVersion, ProjectDatabase.currentSchemaVersion);
    expect(species?.origin, 'The Abyss');
    expect(power?.source, 'Abyssal');
    expect(abilities.single.name, 'Void Blade');
  });
}
