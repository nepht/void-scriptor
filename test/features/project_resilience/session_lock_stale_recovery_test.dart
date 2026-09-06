import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';

void main() {
  for (final age in [Duration.zero, const Duration(days: 30)]) {
    test('unknown owner remains protected at marker age $age', () async {
      final root = await Directory.systemTemp.createTemp('void-safe-lock-');
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Safe');
      const contents = '{"sessionId":"unknown-owner"}';
      await package.sessionFile.writeAsString(contents);
      await package.sessionFile.setLastModified(DateTime.now().subtract(age));
      final contender = ProjectSessionLock(package);
      try {
        await expectLater(contender.acquire(), throwsStateError);
        expect(await package.sessionFile.readAsString(), contents);
      } finally {
        await contender.release();
        await root.delete(recursive: true);
      }
    });
  }

  test('suspended owner cannot be displaced by elapsed time', () async {
    final root = await Directory.systemTemp.createTemp('void-sleep-lock-');
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Sleep');
    final owner = ProjectSessionLock(package);
    final contender = ProjectSessionLock(package);
    try {
      await owner.acquire();
      final original = await package.sessionFile.readAsString();
      await package.sessionFile.setLastModified(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      await expectLater(contender.acquire(), throwsStateError);
      expect(await package.sessionFile.readAsString(), original);
      await owner.release();
      await contender.acquire();
    } finally {
      await owner.release();
      await contender.release();
      await root.delete(recursive: true);
    }
  });

  test('concurrent acquisition has exactly one owner', () async {
    final root = await Directory.systemTemp.createTemp('void-race-lock-');
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Race');
    final contenders = List.generate(12, (_) => ProjectSessionLock(package));
    try {
      final results = await Future.wait(
        contenders.map((lock) async {
          try {
            await lock.acquire();
            return true;
          } on StateError {
            return false;
          }
        }),
      );
      expect(results.where((won) => won), hasLength(1));
    } finally {
      for (final lock in contenders) {
        await lock.release();
      }
      await root.delete(recursive: true);
    }
  });
}
