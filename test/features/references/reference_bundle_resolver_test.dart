import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_file_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:drift/drift.dart';
import 'package:void_scriptor/features/ai/application/reference_bundle_resolver.dart';
import 'package:void_scriptor/features/references/application/reference_repository.dart';
import 'package:void_scriptor/features/references/domain/reference_models.dart';

void main() {
  test(
    'reference bundle resolver selects primary/priority references and locks',
    () async {
      final root = await Directory.systemTemp.createTemp(
        's20-reference-bundle-',
      );
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      await ProjectFileService(paths: paths).createStructure('p');
      final database = await ProjectDatabaseService().open(
        (await paths.database('p')).path,
      );
      addTearDown(database.close);
      final importer = ReferenceImportService(database: database, paths: paths);
      final source = File('${root.path}/face.png')..writeAsBytesSync([1, 2, 3]);
      await importer.importFile(
        projectId: 'p',
        referenceId: 'face',
        sourcePath: source.path,
        name: 'Face',
        ownerAssetId: 'qowner',
        type: ReferenceType.face,
        priority: 100,
        primary: true,
      );
      await database.referenceDao.saveLock(
        const PreservationLockModel(
          id: 'lock',
          assetId: 'qowner',
          type: PreservationLockType.face,
          enabled: true,
          priority: 100,
          instruction: 'Preserve jawline.',
        ),
      );
      final bundle = await ReferenceBundleResolver(
        database,
      ).resolve(assetId: 'qowner');
      expect(bundle.references.single.id, 'face');
      expect(bundle.locks.single.type, PreservationLockType.face);
      expect(bundle.promptInstructions.single, contains('Preserve jawline'));
    },
  );

  test(
    'mode reference set overrides character reference deterministically',
    () async {
      final root = await Directory.systemTemp.createTemp('s20-mode-set-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      await ProjectFileService(paths: paths).createStructure('p');
      final database = await ProjectDatabaseService().open(
        (await paths.database('p')).path,
      );
      addTearDown(database.close);
      final importer = ReferenceImportService(database: database, paths: paths);
      final base = File('${root.path}/base.png')..writeAsBytesSync([1]);
      final mode = File('${root.path}/mode.png')..writeAsBytesSync([2]);
      await importer.importFile(
        projectId: 'p',
        referenceId: 'base-hair',
        sourcePath: base.path,
        name: 'Base Hair',
        ownerAssetId: 'qowner',
        type: ReferenceType.hair,
      );
      await importer.importFile(
        projectId: 'p',
        referenceId: 'mode-hair',
        sourcePath: mode.path,
        name: 'Mode Hair',
        ownerAssetId: 'qowner',
        type: ReferenceType.hair,
      );
      await database
          .into(database.referenceSets)
          .insert(
            ReferenceSetsCompanion.insert(
              id: 'combat-set',
              projectId: 'p',
              ownerAssetId: const Value('qowner'),
              name: 'Combat',
              createdAt: DateTime.now(),
            ),
          );
      await database.referenceDao.addToSet(
        setId: 'combat-set',
        referenceId: 'mode-hair',
      );
      await database
          .into(database.characterModes)
          .insert(
            CharacterModesCompanion.insert(
              id: 'combat-mode',
              projectId: 'p',
              characterId: 'qowner',
              name: 'Combat',
              referenceSetId: const Value('combat-set'),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      final bundle = await ReferenceBundleResolver(
        database,
      ).resolve(assetId: 'qowner', modeId: 'combat-mode');
      expect(bundle.references.single.id, 'mode-hair');
    },
  );
}
