import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_controller.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/project_resilience/application/backup_restore_verification.dart';

void main() {
  test('112.28 verifies complete backup and clean-install restore', () async {
    final root = await Directory.systemTemp.createTemp('hermes-11228-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Restore fixture', description: 'preserved settings');
    final media = File(package.resolve('assets/images/portrait.txt'))
      ..parent.createSync(recursive: true);
    await media.writeAsString('media payload');
    final session = await ProjectSessionManager().open(package);
    addTearDown(session.close);
    final backup = await ProjectResilienceController(
      session,
    ).createBackup(note: '112.28 verification');

    final report = await BackupRestoreVerificationService().verify(
      package: package,
      backup: backup,
      cleanInstallRoot: Directory('${root.path}/clean-install'),
    );

    expect(report.completeBackup, isTrue);
    expect(report.mediaIncluded, isTrue);
    expect(report.restoreCleanInstall, isTrue);
    expect(report.linksPreserved, isTrue);
    expect(report.settingsPreserved, isTrue);
    expect(report.warnings, isEmpty);
    expect(await media.readAsString(), 'media payload');
  });
}
