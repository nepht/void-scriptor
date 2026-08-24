import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/props/application/create_prop_service.dart';
import 'package:void_scriptor/features/props/data/prop_repository.dart';
import 'package:void_scriptor/features/props/domain/prop_model.dart';

void main() {
  test('prop states and specifications survive database restart', () async {
    final root = await Directory.systemTemp.createTemp('s22-prop-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final path = (await paths.database('p1')).path;
    final service = ProjectDatabaseService();
    await service.create(path);
    final first = await service.open(path);
    final id = await CreatePropService(database: first, paths: paths).create(
      projectId: 'p1',
      name: 'Coffee Cup',
      category: PropCategory.handheld,
      function: 'Carries coffee',
      storyCritical: true,
    );
    final repo = PropRepository(first);
    await repo.saveSpecification(
      PropSpecification(
        propId: id,
        widthCm: 9,
        heightCm: 14,
        material: 'Paper',
        color: 'White',
      ),
    );
    for (final state in [
      PropStateModel(id: 'full', propId: id, name: 'Full', sortOrder: 0),
      PropStateModel(id: 'half', propId: id, name: 'Half', sortOrder: 1),
      PropStateModel(
        id: 'empty',
        propId: id,
        name: 'Empty',
        referenceSetId: 'cup-empty',
        sortOrder: 2,
      ),
    ]) {
      await repo.saveState(state);
    }
    await first.close();
    final second = await service.open(path);
    addTearDown(second.close);
    final restored = PropRepository(second);
    expect(second.schemaVersion, 56);
    expect((await second.assetDao.getById(id))?.type, 'prop');
    expect((await restored.getProp(id))?.storyCritical, isTrue);
    expect((await restored.getSpecification(id))?.material, 'Paper');
    expect((await restored.statesFor(id)).map((x) => x.name), [
      'Full',
      'Half',
      'Empty',
    ]);
    expect((await restored.statesFor(id)).last.referenceSetId, 'cup-empty');
    expect(
      await Directory(
        '${(await paths.project('p1')).path}${Platform.pathSeparator}assets${Platform.pathSeparator}props${Platform.pathSeparator}$id${Platform.pathSeparator}references${Platform.pathSeparator}states',
      ).exists(),
      isTrue,
    );
  });
}
