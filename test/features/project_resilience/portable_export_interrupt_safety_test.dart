import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/portable_project_service.dart';

/// 145.42 interrupted-export safety (portable path): a failed export must
/// never leave a partial archive at the final `.voidproject` path, and a
/// previously valid archive must survive a failed re-export untouched.
void main() {
  late Directory root;
  late Directory exportTarget;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-14542-portable-');
    exportTarget = Directory('${root.path}/out')..createSync(recursive: true);
  });
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('failed portable export never touches the final archive path', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Portable Interrupted');

    // Plant a directory at the exporter's exact final path
    // `<projectId>.voidproject`: a staged exporter must fail while
    // renaming into it and leave the planted path untouched.
    final finalPath = '${exportTarget.path}/${package.projectId}.voidproject';
    Directory(finalPath).createSync(recursive: true);

    Object? caught;
    try {
      await PortableProjectExporter().exportPortable(
        package,
        destination: exportTarget,
      );
    } on Object catch (e) {
      caught = e;
    }
    expect(
      caught,
      isNotNull,
      reason: 'export into an unusable final path must fail loudly',
    );
    expect(
      FileSystemEntity.typeSync(finalPath),
      FileSystemEntityType.directory,
      reason: 'the final path must never be overwritten by a failed export',
    );
    final leftovers = exportTarget
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.tmp'))
        .toList();
    expect(leftovers, isEmpty, reason: 'staging files must be cleaned up');
  });

  test(
    'failed re-export preserves the previous valid archive byte-identical',
    () async {
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Portable Preserve');

      final first = await PortableProjectExporter().exportPortable(
        package,
        destination: exportTarget,
      );
      final before = await first.readAsBytes();

      // Sabotage the staging path so a staged exporter fails at rename time;
      // a direct-to-final writer instead overwrites the previous archive.
      Directory('${first.path}.tmp').createSync(recursive: true);

      Object? caught;
      try {
        await PortableProjectExporter().exportPortable(
          package,
          destination: exportTarget,
        );
      } on Object catch (e) {
        caught = e;
      }
      expect(
        caught,
        isNotNull,
        reason: 're-export over a sabotaged staging path must fail loudly',
      );
      expect(
        await first.readAsBytes(),
        before,
        reason: 'previous valid export must be untouched',
      );
      Directory('${first.path}.tmp').deleteSync(recursive: true);
    },
  );
}
