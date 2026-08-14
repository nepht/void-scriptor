import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/portable_project_service.dart';

void main() {
  late Directory root;
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('hermes-s24-archive-'),
  );
  tearDown(() => root.delete(recursive: true));

  test(
    'exports archive without disposable cache and imports it as a copy',
    () async {
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Portable');
      await File(
        '${package.assetsDirectory.path}/images/hero.txt',
      ).writeAsString('asset');
      await File(
        '${package.cacheDirectory.path}/waveforms/disposable',
      ).writeAsString('cache');
      final archive = await PortableProjectExporter().exportPortable(package);
      expect(await archive.exists(), isTrue);
      final imported = await PortableProjectImporter().importArchive(
        archive,
        destination: root,
        asCopy: true,
      );
      expect(
        await File('${imported.root.path}/manifest/project.json').exists(),
        isTrue,
      );
      expect(
        await File('${imported.root.path}/database/project.db').exists(),
        isTrue,
      );
      expect(
        await File(
          '${imported.root.path}/assets/images/hero.txt',
        ).readAsString(),
        'asset',
      );
      expect(imported.projectId, isNot(package.projectId));
    },
  );
}
