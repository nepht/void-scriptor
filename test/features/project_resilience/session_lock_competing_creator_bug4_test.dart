import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';

// vs-hunt-20260915-resilience BUG-4 (REAL BUG, Medium, Confidence High —
// verdict Referee on-disk otoritas numbering).
//
// Mekanisme persis di `ProjectSessionLock.acquire()`: recovery pemilik mati
// menghapus marker stale, lalu create(exclusive) KEDUA dieksekusi tanpa
// proteksi. Bila proses lain mengklaim jendela itu, create kedua gagal dan
// FileSystemException mentah lolos — tanpa re-read marker untuk membedakan
// 'owner baru sah' (lindungi, laporkan tertutup bersih) vs 'stale lagi'
// (arsipkan + retry terikat). Kompetitor nyata diinjeksi lewat seam
// @visibleForTesting (pola mapan run323 BUG-8); probe liveness/start
// diinjeksi supaya tes tidak bergantung tasklist/CIM sungguhan.
void main() {
  Future<ProjectPackage> fixture(String name, String stalePidOwner) async {
    final root = await Directory.systemTemp.createTemp('void-contend-lock-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: name);
    await package.sessionFile.writeAsString(
      jsonEncode({
        'sessionId': stalePidOwner,
        'projectId': package.projectId,
        'processId': 424242,
        'openedAt': DateTime.utc(2026, 9, 14, 3, 0).toIso8601String(),
      }),
    );
    return package;
  }

  Future<void> writeRivalMarker(
    ProjectPackage package,
    String sessionId,
    int processId,
  ) async {
    final file = package.sessionFile;
    await file.create(exclusive: true);
    await file.writeAsString(
      jsonEncode({
        'sessionId': sessionId,
        'projectId': package.projectId,
        'processId': processId,
        'openedAt': DateTime.now().toUtc().toIso8601String(),
      }),
      flush: true,
    );
  }

  test('competing creator with a LIVE owner wins the recovery window: '
      'acquire fails closed with StateError, rival marker is preserved, '
      'no raw FileSystemException escapes', () async {
    const rivalPid = 987654;
    final package = await fixture('Contended live', 'old-dead-owner');
    final lock = ProjectSessionLock(
      package,
      // stale-marker owner terbukti mati (recovery jalan); rival setelah
      // jendela dianggap HIDUP dengan start-time tak diketahui -> fail-closed
      // melindungi pemilik baru.
      isProcessAlive: (processId) async => processId == rivalPid,
      processStartMs: (_) async => null,
      afterDeadOwnerMarkerRecoveredForTest: () =>
          writeRivalMarker(package, 'rival-live', rivalPid),
    );

    await expectLater(lock.acquire(), throwsStateError);

    final marker =
        jsonDecode(await package.sessionFile.readAsString())
            as Map<String, dynamic>;
    expect(
      marker['sessionId'],
      'rival-live',
      reason: 'pemilik baru sah tidak boleh disapu sebagai stale',
    );
    await lock.release();
    expect(
      await package.sessionFile.readAsString(),
      contains('rival-live'),
      reason: 'release() milik sesi lain tidak boleh menghapus marker-nya',
    );
  });

  test('competing creator that already died in the window: bounded retry '
      'recovers again and this process acquires cleanly', () async {
    const rivalDeadPid = 987655;
    final package = await fixture('Contended retry', 'old-dead-owner');
    var rivalWritten = false;
    final lock = ProjectSessionLock(
      package,
      isProcessAlive: (processId) async => false,
      processStartMs: (_) async => null,
      // Rival mengklaim jendela pertama lalu MATI sebelum sempat menulis
      // metadata: recovery berikutnya melihat marker mati lagi dan sah.
      afterDeadOwnerMarkerRecoveredForTest: () async {
        if (rivalWritten) return;
        rivalWritten = true;
        await writeRivalMarker(package, 'rival-crashed', rivalDeadPid);
      },
    );

    await lock.acquire();

    final marker =
        jsonDecode(await package.sessionFile.readAsString())
            as Map<String, dynamic>;
    expect(marker['sessionId'], isNot('rival-crashed'));
    expect(marker['sessionId'], isNot('old-dead-owner'));
    expect(marker['processId'], pid);
    final snapshots = await package.recoveryDirectory
        .list()
        .where((entry) => p.basename(entry.path).startsWith('stale-session-'))
        .toList();
    expect(
      snapshots.length,
      greaterThanOrEqualTo(2),
      reason: 'marker stale awal DAN rival crash sama-sama diarsipkan',
    );
    await lock.release();
  });

  test('contention that never clears stays bounded: StateError, not a '
      'livelock and not a raw FileSystemException', () async {
    var rivalPids = 0;
    final package = await fixture('Contended forever', 'old-dead-owner');
    final lock = ProjectSessionLock(
      package,
      isProcessAlive: (_) async => false,
      processStartMs: (_) async => null,
      // Kompetitor mengisi ulang marker mati setiap kali recovery berhasil:
      // retry harus TERIKAT lalu gagal bersih.
      afterDeadOwnerMarkerRecoveredForTest: () =>
          writeRivalMarker(package, 'rival-${++rivalPids}', 987000 + rivalPids),
    );

    final started = DateTime.now();
    await expectLater(lock.acquire(), throwsStateError);
    expect(
      DateTime.now().difference(started).inSeconds,
      lessThan(30),
      reason: 'retry terikat, bukan livelock',
    );
    expect(rivalPids, lessThanOrEqualTo(4), reason: 'percobaan terbatas');
    await lock.release();
    expect(
      await package.sessionFile.readAsString(),
      contains('rival-'),
      reason: 'marker milik pihak lain dipertahankan apa adanya',
    );
  });
}
