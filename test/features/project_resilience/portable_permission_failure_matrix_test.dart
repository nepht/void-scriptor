import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/portable_project_service.dart';

/// 145.42 permission-loss evidence matrix (portable export/import paths).
/// A target path occupied by an unusable filesystem object (a directory
/// where a file is expected, or a pre-existing file) mirrors a denied
/// rename/write on Windows. The portable flow must fail loudly, preserve
/// the obstacle (it is not owned by the importer/exporter and must never
/// be treated as its own trash), and never leave staging or partial state
/// behind. Staging-path-as-directory technique proven in run69/run72/run73.
void main() {
  late Directory root;
  late Directory exportTarget;
  late Directory importDestination;
  late ProjectPackage setupPackage;
  late String sourceProjectId;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-14542-perm-');
    exportTarget = Directory('${root.path}/exports')
      ..createSync(recursive: true);
    importDestination = Directory('${root.path}/imports')
      ..createSync(recursive: true);
    setupPackage = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Permission Matrix');
    sourceProjectId = setupPackage.projectId;
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  String exportPath(String projectId) =>
      '${exportTarget.path}/$projectId.voidproject';

  String importPath(String projectId) =>
      '${importDestination.path}/$projectId.voidproject';

  Future<File> buildArchive() => PortableProjectExporter().exportPortable(
    setupPackage,
    destination: Directory('${root.path}/archives')..createSync(),
  );

  Map<String, dynamic> archiveManifest(File archive) =>
      jsonDecode(
            utf8.decode(
              ZipDecoder()
                  .decodeBytes(archive.readAsBytesSync(), verify: true)
                  .find('manifest/project.json')!
                  .readBytes()!,
            ),
          )
          as Map<String, dynamic>;

  test(
    'export into an occupied final path fails loudly and preserves the obstacle',
    () async {
      // A directory at the final archive path makes the staging rename fail
      // deterministically (mirrors a denied rename over an existing target).
      Directory(exportPath(sourceProjectId)).createSync(recursive: true);

      await expectLater(
        PortableProjectExporter().exportPortable(
          setupPackage,
          destination: exportTarget,
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(
        FileSystemEntity.typeSync(exportPath(sourceProjectId)),
        FileSystemEntityType.directory,
        reason:
            'the occupied path is not owned by the exporter; it must '
            'survive verbatim',
      );
      expect(
        Directory(
          exportTarget.path,
        ).listSync().whereType<File>().where((f) => f.path.endsWith('.tmp')),
        isEmpty,
        reason: 'no staging archive may remain after the failed export',
      );
    },
  );

  test(
    'import into an occupied package path fails and never treats the user file as trash',
    () async {
      final archive = await buildArchive();
      final projectId = archiveManifest(archive)['projectId'] as String;
      // A pre-existing file at the exact package path mirrors a denied
      // package-directory creation; the file is not owned by the importer
      // and must survive untouched.
      final occupant = File(importPath(projectId));
      occupant.writeAsStringSync('irreplaceable user file');
      final occupantBytes = occupant.readAsBytesSync();

      await expectLater(
        PortableProjectImporter().importArchive(
          archive,
          destination: importDestination,
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(
        occupant.existsSync(),
        isTrue,
        reason:
            'the pre-existing file is not owned by the importer; it must '
            'survive verbatim',
      );
      expect(occupant.readAsBytesSync(), occupantBytes);
      expect(
        importDestination.listSync().where((e) => e.path.endsWith('manifest')),
        isEmpty,
        reason: 'no partial package contents may be written alongside it',
      );
    },
  );

  test(
    'copy-import registration failure cleans the new package and registers nothing',
    () async {
      final archive = await buildArchive();
      // Extraction succeeds; sabotage the registry staging write so the
      // registration (atomicWrite to projects.json) fails instead.
      Directory('${root.path}/projects.json.tmp').createSync(recursive: true);

      await expectLater(
        PortableProjectImportCoordinator(
          registry: ProjectRegistryService(rootDirectory: root),
        ).importAndRegister(
          archive,
          destination: importDestination,
          asCopy: true,
        ),
        throwsA(isA<FileSystemException>()),
      );

      // Remove the planted obstacle (run72 pattern: retry succeeds after the
      // obstacle is removed) so the registry itself is readable again.
      Directory('${root.path}/projects.json.tmp').deleteSync(recursive: true);
      final projects = await ProjectRegistryService(rootDirectory: root).load();
      expect(
        projects.single.id,
        sourceProjectId,
        reason: 'a failed copy-import must register nothing',
      );
      expect(
        importDestination.listSync().where(
          (e) =>
              FileSystemEntity.typeSync(e.path) ==
              FileSystemEntityType.directory,
        ),
        isEmpty,
        reason:
            'a copy-import has no collision stash; the failed copy-import '
            'must not leave a package directory behind',
      );
    },
  );
}
