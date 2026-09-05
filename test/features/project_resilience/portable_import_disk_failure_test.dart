import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:archive/archive.dart';
import 'package:void_scriptor/features/project_resilience/application/portable_project_service.dart';

/// 145.42 disk-full evidence matrix (portable import path): a write failure
/// in the middle of archive extraction (disk full, permission loss) must
/// fail loudly, remove the partially extracted package, and never register
/// or admit leftover state.
void main() {
  late Directory root;
  late Directory importDestination;
  late File archive;
  late String sourceProjectId;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-14542-import-');
    importDestination = Directory('${root.path}/imports')
      ..createSync(recursive: true);
    final archives = Directory('${root.path}/archives')
      ..createSync(recursive: true);
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Import Disk Full');
    sourceProjectId = package.projectId;
    archive = await PortableProjectExporter().exportPortable(
      package,
      destination: archives,
    );
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  String finalPath(String projectId) =>
      '${importDestination.path}/$projectId.voidproject';

  /// Plants a directory at an in-package file path so the extraction write
  /// to that exact path fails deterministically (staging-path-as-directory
  /// technique proven in run69/run72).
  void plantBlocker(String projectId, String relativeFile) {
    Directory(
      '${finalPath(projectId)}/$relativeFile',
    ).createSync(recursive: true);
  }

  test(
    'disk-full on the first extracted file leaves no partial package',
    () async {
      final manifest =
          jsonDecode(
                utf8.decode(
                  ZipDecoder()
                      .decodeBytes(archive.readAsBytesSync(), verify: true)
                      .find('manifest/project.json')!
                      .readBytes()!,
                ),
              )
              as Map<String, dynamic>;
      final projectId = manifest['projectId'] as String;
      plantBlocker(projectId, 'manifest/project.json');

      await expectLater(
        PortableProjectImporter().importArchive(
          archive,
          destination: importDestination,
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(
        FileSystemEntity.typeSync(finalPath(projectId)),
        isNot(FileSystemEntityType.directory),
        reason: 'a failed extraction must remove the partial package',
      );
    },
  );

  test(
    'disk-full on a later file removes files extracted before the failure',
    () async {
      final manifest =
          jsonDecode(
                utf8.decode(
                  ZipDecoder()
                      .decodeBytes(archive.readAsBytesSync(), verify: true)
                      .find('manifest/project.json')!
                      .readBytes()!,
                ),
              )
              as Map<String, dynamic>;
      final projectId = manifest['projectId'] as String;
      plantBlocker(projectId, 'database/project.db');

      await expectLater(
        PortableProjectImporter().importArchive(
          archive,
          destination: importDestination,
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(
        FileSystemEntity.typeSync(finalPath(projectId)),
        isNot(FileSystemEntityType.directory),
        reason:
            'cleanup must remove already-extracted files, not only skip '
            'the failing one',
      );
    },
  );

  test('coordinator-level registration failure registers nothing and leaves '
      'no partial package', () async {
    final manifest =
        jsonDecode(
              utf8.decode(
                ZipDecoder()
                    .decodeBytes(archive.readAsBytesSync(), verify: true)
                    .find('manifest/project.json')!
                    .readBytes()!,
              ),
            )
            as Map<String, dynamic>;
    final projectId = manifest['projectId'] as String;

    // Extraction will succeed; sabotage the registry staging write so
    // the registration (atomicWrite to projects.json) fails instead.
    Directory('${root.path}/projects.json.tmp').createSync(recursive: true);

    await expectLater(
      PortableProjectImportCoordinator(
        registry: ProjectRegistryService(rootDirectory: root),
      ).importAndRegister(archive, destination: importDestination),
      throwsA(isA<FileSystemException>()),
    );

    // Remove the planted obstacle (run72 pattern: retry succeeds after
    // the obstacle is removed) so the registry itself is readable again.
    Directory('${root.path}/projects.json.tmp').deleteSync(recursive: true);
    final projects = await ProjectRegistryService(rootDirectory: root).load();
    expect(
      projects.single.id,
      sourceProjectId,
      reason:
          'a failed import must never register the imported project; '
          'only the pre-existing setup project remains',
    );
    expect(
      FileSystemEntity.typeSync(finalPath(projectId)),
      isNot(FileSystemEntityType.directory),
      reason:
          'the coordinator must remove the extracted package when '
          'registration fails',
    );
    expect(
      importDestination.listSync(),
      everyElement(
        predicate<dynamic>(
          (e) => !e.path.contains('.import-backup-'),
          'no import-backup stash remains',
        ),
      ),
    );
  });
}
