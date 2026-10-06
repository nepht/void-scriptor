import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

void main() {
  test(
    'concurrent releases of the owned marker never throw a zone error',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'void-lock-release-race-',
      );
      addTearDown(() async {
        try {
          await root.delete(recursive: true);
        } catch (_) {}
      });
      final package = ProjectPackage(projectId: 'p-release-race', root: root);
      final lock = ProjectSessionLock(package);
      await lock.acquire(appVersion: 'test');

      // Two closes racing (e.g. an awaited close and a fire-and-forget
      // session teardown) both observe the owned marker; exactly one delete
      // can win, the other must observe the release as already complete.
      final outcome = await Future.wait([
        lock.release(),
        lock.release(),
      ]).then((_) => 'both-ok', onError: (Object error) => 'threw:$error');

      expect(outcome, 'both-ok');
      expect(await package.sessionFile.exists(), isFalse);
      // A trailing release is still a safe no-op.
      await lock.release();
    },
  );

  test(
    'ProjectSession.close handles concurrent directory cleanup without zone error',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'void-session-lock-race-',
      );
      addTearDown(() async {
        try {
          await root.delete(recursive: true);
        } catch (_) {}
      });
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Session Lock Race');
      final session = await ProjectSessionManager().open(package);

      // Concurrently run session.close() and directory deletion, simulating
      // test teardown where root.delete races with lock file deletion.
      final outcome = await Future.wait([
        session.close(),
        root.delete(recursive: true),
      ]).then((_) => 'both-ok', onError: (Object error) => 'threw:$error');

      expect(outcome, 'both-ok');
    },
  );
}
