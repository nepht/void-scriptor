import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_recovery_service.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';

/// core-hunt-20260906 BUG-6: the creation marker is staged BEFORE the
/// database and manifest are written, so a crash mid-creation left a
/// marker-only (or db-only) folder that admission happily registered as a
/// complete project. Admission must require package completeness.
void main() {
  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp(
      'core-hunt-20260906-bug6-',
    );
  });

  tearDown(() async {
    try {
      await tempRoot.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  Future<ProjectPackage> createComplete(String name) => ProjectPackageService(
    rootDirectory: tempRoot,
    appVersion: 'test',
  ).create(name: name);

  group('core-hunt-20260906 creation completeness (BUG-6)', () {
    test(
      'a marker-only package (crash before database) is NOT admitted',
      () async {
        final package = await createComplete('Half Built');
        // Simulate the crash window: kill the database and manifest, keep
        // the staged marker — exactly the on-disk state of a process death
        // right after marker staging.
        await package.databaseFile.delete();
        await package.manifestFile.delete();

        const recovery = ProjectRecoveryService();
        final admitted = await recovery.admitMarkedCreations(tempRoot, {});

        expect(
          admitted,
          isEmpty,
          reason: 'BUG-6: incomplete package admitted as a project',
        );
        // Left untouched for manual inspection, like every corrupt-marker path.
        final marker = File(
          '${package.root.path}${Platform.pathSeparator}'
          '${ProjectRecoveryService.creationMarkerName}',
        );
        expect(await marker.exists(), isTrue);
      },
    );

    test(
      'a package with database but no manifest (crash mid-assembly) is NOT admitted',
      () async {
        final package = await createComplete('No Manifest');
        await package.manifestFile.delete();

        const recovery = ProjectRecoveryService();
        final admitted = await recovery.admitMarkedCreations(tempRoot, {});
        expect(admitted, isEmpty);
      },
    );

    test(
      'a complete package is admitted (recovery contract preserved)',
      () async {
        final package = await createComplete('Finished Orphan');

        const recovery = ProjectRecoveryService();
        final admitted = await recovery.admitMarkedCreations(tempRoot, {});

        expect(admitted.single.id, package.projectId);
        expect(admitted.single.name, 'Finished Orphan');
      },
    );

    test(
      'a manifest whose id disagrees with the folder is NOT admitted',
      () async {
        final package = await createComplete('Id Drift');
        // Rewrite the manifest file with a different id inside the same
        // complete package: folder name and manifest must agree.
        final manifestJson =
            jsonDecode(await package.manifestFile.readAsString())
                as Map<String, dynamic>;
        manifestJson['projectId'] = 'someone-else';
        await package.manifestFile.writeAsString(
          jsonEncode(manifestJson),
          flush: true,
        );

        const recovery = ProjectRecoveryService();
        final admitted = await recovery.admitMarkedCreations(tempRoot, {});
        expect(admitted, isEmpty);
      },
    );
  });
}
