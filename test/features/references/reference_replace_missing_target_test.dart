import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_file_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/references/application/reference_repository.dart';
import 'package:void_scriptor/features/references/domain/reference_models.dart';

// vs-hunt-20260913-references REF-BUG-1 (Medium):
// replaceFile copied the stored target into a version snapshot without an
// existence check, so replacing a reference whose file went missing on disk
// (external deletion, moved drive) threw an unhandled FileSystemException
// instead of recovering the reference.
void main() {
  Future<Directory> seedProject(String prefix) async {
    final root = await Directory.systemTemp.createTemp(prefix);
    addTearDown(() async {
      try {
        await root.delete(recursive: true);
      } catch (_) {}
    });
    final paths = ProjectPaths(rootDirectory: root);
    await ProjectFileService(paths: paths).createStructure('p');
    // 145.42: open() no longer silently creates the database file.
    await ProjectDatabaseService().create((await paths.database('p')).path);
    return root;
  }

  test(
    'replaceFile recovers a reference whose stored file is missing on disk',
    () async {
      final root = await seedProject('s20-reference-replace-missing-');
      final paths = ProjectPaths(rootDirectory: root);
      final source = File('${root.path}/source.png')
        ..writeAsBytesSync([1, 2, 3]);
      final replacement = File('${root.path}/replacement.png')
        ..writeAsBytesSync([9, 8, 7]);
      final database = await ProjectDatabaseService().open(
        (await paths.database('p')).path,
      );
      addTearDown(database.close);
      final importer = ReferenceImportService(database: database, paths: paths);
      final imported = await importer.importFile(
        projectId: 'p',
        referenceId: 'face-1',
        sourcePath: source.path,
        name: 'Face One',
        ownerAssetId: 'qowner',
        type: ReferenceType.face,
      );

      // Simulate the documented missing-file state: external deletion of the
      // stored reference file (row still present, file gone).
      final packageRoot = (await paths.project('p')).path;
      await File('$packageRoot/${imported.filePath}').delete();

      // RED: before the fix this threw an unhandled FileSystemException from
      // the snapshot copy, permanently wedging the reference.
      final updated = await importer.replaceFile(
        projectId: 'p',
        referenceId: 'face-1',
        sourcePath: replacement.path,
        changeNote: 'Recovered missing file',
      );

      final current = await database.referenceDao.byId('face-1');
      expect(current, isNotNull);
      expect(await File('$packageRoot/${current!.filePath}').readAsBytes(), [
        9,
        8,
        7,
      ]);
      expect(updated.contentHash, isNotNull);
      // No old content existed, so no phantom version row may be recorded.
      final versions = await database.select(database.referenceVersions).get();
      expect(versions, isEmpty);
    },
  );

  test(
    'replaceFile still snapshots the previous version when the target exists',
    () async {
      final root = await seedProject('s20-reference-replace-present-');
      final paths = ProjectPaths(rootDirectory: root);
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
      await importer.replaceFile(
        projectId: 'p',
        referenceId: 'face-1',
        sourcePath: replacement.path,
        changeNote: 'Updated geometry',
      );
      final version =
          (await database.select(database.referenceVersions).get()).single;
      final packageRoot = (await paths.project('p')).path;
      expect(await File('$packageRoot/${version.filePath}').readAsBytes(), [
        1,
        2,
        3,
      ]);
    },
  );
}
