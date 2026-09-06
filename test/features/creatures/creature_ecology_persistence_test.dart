import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/creatures/data/creature_ecology_repository.dart';
import 'package:void_scriptor/features/creatures/domain/creature_ecology_state.dart';

void main() {
  test('ecology state survives project database restart', () async {
    final root = await Directory.systemTemp.createTemp('s54-ecology-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final databasePath = (await paths.database('project-1')).path;
    final service = ProjectDatabaseService();

    await service.create(databasePath);
    final first = await service.open(databasePath);
    final repository = CreatureEcologyRepository(first);
    await repository.save(
      const CreatureEcologyState(
        creatureId: 'creature-1',
        speciesId: 'ashborn',
        genomeJson: '{"heatResistance":0.8}',
        phenotypeJson: '{"scale":1.2}',
        needsJson: '{"hunger":0.2}',
        lineageId: 'lineage-1',
        simulationTick: 12,
      ),
    );
    await first.close();

    final second = await service.open(databasePath);
    addTearDown(second.close);
    final restored = await CreatureEcologyRepository(second).get('creature-1');

    expect(restored, isNotNull);
    expect(restored!.speciesId, 'ashborn');
    expect(restored.genomeJson, '{"heatResistance":0.8}');
    expect(restored.simulationTick, 12);
  });
}
