import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

void main() {
  test(
    'release without acquisition preserves another session marker',
    () async {
      final root = await Directory.systemTemp.createTemp('void-lock-owner-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Owner');
      await package.sessionFile.writeAsString('{"sessionId":"other"}');
      await ProjectSessionLock(package).release();
      expect(await package.sessionFile.exists(), isTrue);
    },
  );
  test(
    'failed companion marker write releases only the acquired session',
    () async {
      final root = await Directory.systemTemp.createTemp('void-lock-failure-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Failure');
      await Directory(package.lockFile.path).create();
      await expectLater(
        ProjectSessionManager().open(package),
        throwsA(isA<FileSystemException>()),
      );
      expect(await package.sessionFile.exists(), isFalse);
      expect(await Directory(package.lockFile.path).exists(), isTrue);
    },
  );
  test('read-only close preserves existing writer markers', () async {
    final root = await Directory.systemTemp.createTemp('void-lock-reader-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Reader');
    await package.sessionFile.writeAsString('{"sessionId":"writer"}');
    await package.lockFile.writeAsString('writer-marker');
    final session = await ProjectSessionManager().open(
      package,
      mode: ProjectOpenMode.readOnly,
    );
    await session.close();
    expect(await package.sessionFile.exists(), isTrue);
    expect(await package.lockFile.exists(), isTrue);
  });
}
