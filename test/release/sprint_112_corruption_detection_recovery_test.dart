import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/corruption_detection_recovery.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-11230-');
  });
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('scans corruption and repairs through backup and quarantine', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Corruption fixture');
    final hero = File('${package.assetsDirectory.path}/images/hero.txt');
    hero.createSync(recursive: true);
    hero.writeAsStringSync('hero');
    final orphan = File('${package.assetsDirectory.path}/images/orphan.txt');
    orphan.writeAsStringSync('orphan');
    final index = File('${package.root.path}/cache/index.json');
    index.writeAsStringSync(
      jsonEncode({
        'paths': ['assets/images/stale.txt'],
      }),
    );
    final service = CorruptionDetectionRecoveryService(package);

    final report = await service.scan(
      referencedPaths: {'assets/images/hero.txt', 'assets/images/missing.txt'},
      indexFile: index,
    );
    expect(report.schemaValid, isTrue);
    expect(report.missingPaths, contains('assets/images/missing.txt'));
    expect(report.orphanPaths, contains('assets/images/orphan.txt'));
    expect(report.indexSynchronized, isFalse);
    expect(
      report.repairPreview.quarantinePaths,
      contains('assets/images/orphan.txt'),
    );

    final result = await service.recover(
      report.repairPreview,
      backupDestination: Directory('${root.path}/pre-repair'),
      indexFile: index,
      referencedPaths: {'assets/images/hero.txt', 'assets/images/missing.txt'},
    );
    expect(result.backupDirectory.existsSync(), isTrue);
    expect(
      File('${package.root.path}/trash/assets/images/orphan.txt').existsSync(),
      isTrue,
    );
    expect(
      File('${package.root.path}/cache/index.json').readAsStringSync(),
      contains('assets/images/hero.txt'),
    );
    expect(result.recoveryLog.existsSync(), isTrue);
  });
}
