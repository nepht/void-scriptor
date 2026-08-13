import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_file_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/references/application/reference_repository.dart';
import 'package:void_scriptor/features/references/domain/reference_models.dart';

void main() {
  test(
    'import copies reference, hashes content, and enforces one primary per type',
    () async {
      final root = await Directory.systemTemp.createTemp(
        's20-reference-import-',
      );
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      await ProjectFileService(paths: paths).createStructure('p');
      final source = File('${root.path}/source.png')
        ..writeAsBytesSync([1, 2, 3, 4]);
      final databasePath = await paths.database('p');
      final database = await ProjectDatabaseService().open(databasePath.path);
      addTearDown(database.close);
      final importer = ReferenceImportService(database: database, paths: paths);
      await importer.importFile(
        projectId: 'p',
        referenceId: 'face-1',
        sourcePath: source.path,
        name: 'Face One',
        ownerAssetId: 'qowner',
        type: ReferenceType.face,
        primary: true,
      );
      await importer.importFile(
        projectId: 'p',
        referenceId: 'face-2',
        sourcePath: source.path,
        name: 'Face Two',
        ownerAssetId: 'qowner',
        type: ReferenceType.face,
        primary: true,
        allowDuplicate: true,
      );
      final references = await database.referenceDao.list(
        ownerAssetId: 'qowner',
      );
      expect(
        references.singleWhere((item) => item.id == 'face-2').primaryReference,
        isTrue,
      );
      expect(
        references.singleWhere((item) => item.id == 'face-1').primaryReference,
        isFalse,
      );
      expect(
        references.every((item) => item.contentHash?.isNotEmpty == true),
        isTrue,
      );
      expect(
        await File('${root.path}/p/${references.first.filePath}').exists(),
        isTrue,
      );
    },
  );

  test(
    'duplicate hash is rejected and replacement preserves reference id with history',
    () async {
      final root = await Directory.systemTemp.createTemp(
        's20-reference-version-',
      );
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      await ProjectFileService(paths: paths).createStructure('p');
      final source = File('${root.path}/source.png')
        ..writeAsBytesSync([1, 2, 3]);
      final replacement = File('${root.path}/replacement.png')
        ..writeAsBytesSync([4, 5, 6]);
      final database = await ProjectDatabaseService().open(
        (await paths.database('p')).path,
      );
      addTearDown(database.close);
      final importer = ReferenceImportService(database: database, paths: paths);
      await importer.importFile(
        projectId: 'p',
        referenceId: 'face-1',
        sourcePath: source.path,
        name: 'Face One',
        ownerAssetId: 'qowner',
        type: ReferenceType.face,
      );
      expect(
        () => importer.importFile(
          projectId: 'p',
          referenceId: 'face-duplicate',
          sourcePath: source.path,
          name: 'Duplicate',
          ownerAssetId: 'qowner',
          type: ReferenceType.face,
        ),
        throwsStateError,
      );
      final updated = await importer.replaceFile(
        projectId: 'p',
        referenceId: 'face-1',
        sourcePath: replacement.path,
        changeNote: 'Updated geometry',
      );
      expect(updated.id, 'face-1');
      expect(
        (await database.select(database.referenceVersions).get())
            .single
            .changeNote,
        'Updated geometry',
      );
    },
  );
}
