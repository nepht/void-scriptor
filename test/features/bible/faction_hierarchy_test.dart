import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/bible/domain/faction.dart';
import 'dart:io';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/bible/application/faction_repository.dart';

void main() {
  test('faction unit supports nested hierarchy', () {
    const unit = FactionUnitModel(
      id: 'unit-1',
      factionId: 'faction-1',
      parentUnitId: 'unit-root',
      name: 'Void Researchers',
      description: 'Research division.',
    );

    expect(unit.factionId, 'faction-1');
    expect(unit.parentUnitId, 'unit-root');
    expect(unit.name, 'Void Researchers');
  });

  test('faction units survive restart', () async {
    final root = await Directory.systemTemp.createTemp('s21-units-');
    addTearDown(() => root.delete(recursive: true));
    final path = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(path);
    final first = await service.open(path);
    await FactionRepository(first).saveUnit(
      const FactionUnitModel(
        id: 'unit-1',
        factionId: 'faction-1',
        name: 'Void Researchers',
        parentUnitId: 'unit-root',
      ),
    );
    await first.close();
    final second = await service.open(path);
    addTearDown(second.close);
    final units = await FactionRepository(second).unitsFor('faction-1');
    expect(second.schemaVersion, 52);
    expect(units.single.parentUnitId, 'unit-root');
  });
}
