import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';

void main() {
  test('dead PID marker is backed up and replaced automatically', () async {
    final root = await Directory.systemTemp.createTemp('void-dead-lock-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Dead owner');
    await package.sessionFile.writeAsString(
      jsonEncode({
        'sessionId': 'dead-owner',
        'projectId': package.projectId,
        'processId': 424242,
      }),
    );

    final lock = ProjectSessionLock(
      package,
      isProcessAlive: (_) async => false,
    );
    await lock.acquire();

    final marker = jsonDecode(await package.sessionFile.readAsString());
    expect(marker['sessionId'], isNot('dead-owner'));
    expect(marker['processId'], pid);
    final snapshots = await package.recoveryDirectory
        .list()
        .where((entry) => p.basename(entry.path).startsWith('stale-session-'))
        .toList();
    expect(snapshots, hasLength(1));
    expect(
      await File(p.join(snapshots.single.path, 'session.lock')).readAsString(),
      contains('dead-owner'),
    );
    await lock.release();
  });

  test('live PID marker remains protected', () async {
    final root = await Directory.systemTemp.createTemp('void-live-lock-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Live owner');
    await package.sessionFile.writeAsString(
      jsonEncode({
        'sessionId': 'live-owner',
        'projectId': package.projectId,
        'processId': 42,
      }),
    );

    final lock = ProjectSessionLock(package, isProcessAlive: (_) async => true);
    await expectLater(lock.acquire(), throwsStateError);
    expect(await package.sessionFile.readAsString(), contains('live-owner'));
  });

  test('legacy marker without PID remains protected', () async {
    final root = await Directory.systemTemp.createTemp('void-legacy-lock-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Legacy owner');
    await package.sessionFile.writeAsString('{"sessionId":"legacy"}');

    final lock = ProjectSessionLock(
      package,
      isProcessAlive: (_) async => false,
    );
    await expectLater(lock.acquire(), throwsStateError);
    expect(await package.sessionFile.readAsString(), contains('legacy'));
  });
}
