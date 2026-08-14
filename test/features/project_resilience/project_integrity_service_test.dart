import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_integrity_service.dart';

void main() {
  late Directory root;
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('hermes-s24-integrity-'),
  );
  tearDown(() => root.delete(recursive: true));

  test(
    'integrity reports missing and orphan files and migrates internal paths',
    () async {
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Integrity');
      await File(
        '${package.assetsDirectory.path}/images/referenced.txt',
      ).writeAsString('ok');
      await File(
        '${package.assetsDirectory.path}/images/orphan.txt',
      ).writeAsString('orphan');
      final report = await ProjectIntegrityService(package).scan(
        referencedPaths: {
          'assets/images/referenced.txt',
          'assets/images/missing.txt',
        },
      );
      expect(report.manifestValid, isTrue);
      expect(report.missingFiles, 1);
      expect(report.orphanFiles, 1);
      expect(
        ProjectPathMigrator(
          package,
        ).migrate('${package.root.path}/assets/images/referenced.txt'),
        'assets/images/referenced.txt',
      );
      expect(
        ProjectPathMigrator(package).migrate('/external/file.png'),
        isNull,
      );
    },
  );
}
