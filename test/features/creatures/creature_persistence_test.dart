import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/creatures/application/create_creature_service.dart';
import 'package:void_scriptor/features/creatures/data/creature_repository.dart';
import 'package:void_scriptor/features/creatures/domain/creature_model.dart';

void main() {
  test('creature package and normalized children survive restart', () async {
    final root = await Directory.systemTemp.createTemp('s22-creature-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final databasePath = (await paths.database('project-1')).path;
    final databaseService = ProjectDatabaseService();
    await databaseService.create(databasePath);
    final first = await databaseService.open(databasePath);

    final creatureId =
        await CreateCreatureService(database: first, paths: paths).create(
          projectId: 'project-1',
          name: 'Byte',
          category: CreatureCategory.synthetic,
          description: 'Synthetic companion.',
          behavior: 'Protective and curious.',
          origin: 'Capsule Crash',
        );
    final repository = CreatureRepository(first);
    await repository.savePhysicalProfile(
      CreaturePhysicalProfile(
        creatureId: creatureId,
        heightCm: 190,
        bodyStructure: 'Transforming cube chassis',
        skinMaterial: 'Electric blue alloy',
      ),
    );
    await repository.saveAbility(
      CreatureAbilityModel(
        id: 'ability-electric-core',
        creatureId: creatureId,
        name: 'Electric Core',
        powerSystemId: 'power-electric',
      ),
    );
    for (final mode in const [
      CreatureModeModel(id: 'cube', creatureId: '', name: 'Cube Mode'),
      CreatureModeModel(
        id: 'companion',
        creatureId: '',
        name: 'Companion Mode',
        defaultMode: true,
      ),
      CreatureModeModel(
        id: 'combat',
        creatureId: '',
        name: 'Combat Mode',
        referenceSetId: 'byte-combat-references',
      ),
    ]) {
      await repository.saveMode(mode.copyWith(creatureId: creatureId));
    }
    await first.close();

    final second = await databaseService.open(databasePath);
    addTearDown(second.close);
    final restored = CreatureRepository(second);

    expect(second.schemaVersion, 28);
    expect((await second.assetDao.getById(creatureId))?.type, 'creature');
    expect(
      (await restored.getCreature(creatureId))?.category,
      CreatureCategory.synthetic,
    );
    expect((await restored.getPhysicalProfile(creatureId))?.heightCm, 190);
    expect(
      (await restored.abilitiesFor(creatureId)).single.powerSystemId,
      'power-electric',
    );
    expect((await restored.modesFor(creatureId)).map((mode) => mode.name), [
      'Cube Mode',
      'Companion Mode',
      'Combat Mode',
    ]);
    expect(
      (await restored.modesFor(creatureId)).last.referenceSetId,
      'byte-combat-references',
    );
    expect(
      await Directory(
        '${(await paths.project('project-1')).path}${Platform.pathSeparator}assets${Platform.pathSeparator}creatures${Platform.pathSeparator}$creatureId${Platform.pathSeparator}references${Platform.pathSeparator}detail-sheet',
      ).exists(),
      isTrue,
    );
  });
}
