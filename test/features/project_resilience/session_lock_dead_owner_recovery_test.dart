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

  // vs-hunt-20260915-resilience BUG-3 (REAL BUG, Referee otoritas on-disk):
  // recovery hanya percaya liveness PID mentah. PID yang direbut proses lain
  // (pemegang hidup yang DIMULAI SETELAH marker ditulis) membuat proyek
  // terkunci selamanya selama pemegang baru itu hidup — padahal pemilik
  // marker sudah mati. Identitas start-time membuktikan non-kepemilikan.
  test('live PID whose holder started AFTER the marker is a reused PID - '
      'recovery displaces the stale marker', () async {
    final root = await Directory.systemTemp.createTemp('void-reuse-lock-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Reused pid');
    final openedAt = DateTime.utc(2026, 9, 14, 3, 0);
    await package.sessionFile.writeAsString(
      jsonEncode({
        'sessionId': 'dead-owner',
        'projectId': package.projectId,
        'processId': 424242,
        'openedAt': openedAt.toIso8601String(),
      }),
    );

    final lock = ProjectSessionLock(
      package,
      // Pemegang PID masih hidup...
      isProcessAlive: (_) async => true,
      // ...tetapi baru mulai 5 menit SETELAH marker ditulis (jauh di atas
      // grace 60 detik): bukan pemilik marker — PID-nya direbut proses lain.
      processStartMs: (_) async =>
          openedAt.add(const Duration(minutes: 5)).millisecondsSinceEpoch,
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

  test('live PID whose holder started BEFORE the marker is the owner - '
      'remains protected', () async {
    final root = await Directory.systemTemp.createTemp('void-owner-lock-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Live owner');
    final openedAt = DateTime.utc(2026, 9, 14, 3, 0);
    await package.sessionFile.writeAsString(
      jsonEncode({
        'sessionId': 'live-owner',
        'projectId': package.projectId,
        'processId': 42,
        'openedAt': openedAt.toIso8601String(),
      }),
    );

    final lock = ProjectSessionLock(
      package,
      isProcessAlive: (_) async => true,
      // Holder dimulai sebelum marker ditulis -> konsisten dengan pemilik
      // yang masih hidup: lindungi.
      processStartMs: (_) async =>
          openedAt.subtract(const Duration(minutes: 10)).millisecondsSinceEpoch,
    );
    await expectLater(lock.acquire(), throwsStateError);
    expect(await package.sessionFile.readAsString(), contains('live-owner'));
  });

  test(
    'live PID with unknown holder start time remains protected (fail-closed)',
    () async {
      final root = await Directory.systemTemp.createTemp('void-unknown-lock-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Unknown holder');
      final openedAt = DateTime.utc(2026, 9, 14, 3, 0);
      await package.sessionFile.writeAsString(
        jsonEncode({
          'sessionId': 'unknown-holder',
          'projectId': package.projectId,
          'processId': 43,
          'openedAt': openedAt.toIso8601String(),
        }),
      );

      final lock = ProjectSessionLock(
        package,
        isProcessAlive: (_) async => true,
        processStartMs: (_) async => null,
      );
      await expectLater(lock.acquire(), throwsStateError);
      expect(
        await package.sessionFile.readAsString(),
        contains('unknown-holder'),
      );
    },
  );

  test('holder start inside the grace window of the marker write remains '
      'protected (ambiguity favors the owner)', () async {
    final root = await Directory.systemTemp.createTemp('void-grace-lock-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Grace window');
    final openedAt = DateTime.utc(2026, 9, 14, 3, 0);
    await package.sessionFile.writeAsString(
      jsonEncode({
        'sessionId': 'grace-owner',
        'projectId': package.projectId,
        'processId': 44,
        'openedAt': openedAt.toIso8601String(),
      }),
    );

    final lock = ProjectSessionLock(
      package,
      isProcessAlive: (_) async => true,
      // Hanya 1 detik "setelah" marker: di dalam grace — tidak boleh
      // disimpulkan reuse.
      processStartMs: (_) async =>
          openedAt.add(const Duration(seconds: 1)).millisecondsSinceEpoch,
    );
    await expectLater(lock.acquire(), throwsStateError);
    expect(await package.sessionFile.readAsString(), contains('grace-owner'));
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
