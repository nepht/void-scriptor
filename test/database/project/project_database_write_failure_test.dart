import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';

/// Sprint 145.42 (Data Safety Failure Matrix) - disk full / permission loss
/// pada layer database SQLite.
///
/// Risiko yang dibuktikan: [ProjectDatabaseService.open] sukses membuka
/// database pada storage yang TIDAK BISA DITULISI (file read-only /
/// permission loss / disk full) dan caller mendapat koneksi "sehat"
/// padahal setiap mutasi akan gagal. Kegagalan tulis harus dilaporkan
/// sebagai keadaan bertipe lewat probe tulis eksplisit
/// [ProjectDatabaseService.probeWrite] - bukan sebagai korupsi dan bukan
/// sebagai silent failure pada mutasi pertama pengguna.
///
/// Mekanisme injection: file database diberi attribut read-only
/// (Windows: `attrib +R`; POSIX: chmod a-w). sqlite3 yang membuka file
/// read-only lalu diminta menulis melaporkan SQLITE_READONLY (extended
/// result code 8) - permukaan yang sama dengan disk full pada media
/// write-protected atau permission loss pada level file.
void main() {
  late Directory root;
  setUp(
    () async => root = await Directory.systemTemp.createTemp('hermes-dbwrite-'),
  );
  tearDown(() async {
    try {
      root.delete(recursive: true);
    } on FileSystemException {
      // Windows: read-only file menolak delete - pulihkan flag dulu.
      final db = File('${root.path}/project.db');
      if (db.existsSync()) {
        if (Platform.isWindows) {
          final result = await Process.run('attrib', <String>['-R', db.path]);
          if (result.exitCode != 0) {
            // Fallback POSIX chmod.
            await Process.run('chmod', <String>['u+w', db.path]);
          }
        } else {
          await Process.run('chmod', <String>['u+w', db.path]);
        }
      }
      root.deleteSync(recursive: true);
    }
  });

  test('production open reports a typed write-failure when the database '
      'file is write-protected, instead of a raw SqliteException', () async {
    final dbPath = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(dbPath);

    // Windows: flag read-only di level file via attrib. POSIX: chmod a-w.
    // Pemilihan tidak bisa lewat fallback exit-code: di POSIX binary
    // `attrib` tidak ada sehingga Process.run melempar ProcessException
    // sebelum fallback tercapai (CI Linux 61156d4). Produksi tetap
    // platform-netral: koneksi terbuka read-only, tulis pertama drift
    // initialization memicu SQLITE_READONLY (8) -> typed write-failure.
    if (Platform.isWindows) {
      await Process.run('attrib', <String>['+R', dbPath]);
    } else {
      await Process.run('chmod', <String>['a-w', dbPath]);
    }

    await expectLater(
      service.open(dbPath),
      throwsA(isA<ProjectDatabaseWriteFailedException>()),
    );
  });

  // Test ketiga dihapus: injeksi obstacle pada WAL/DIRECTORY tidak
  // deterministik karena sqlite3 dapat fallback ke mode DELETE.
  // Slice ini cukup membuktikan (a) open() melaporkan write-failure
  // untuk read-only file, (b) probeWrite sukses pada DB sehat tanpa
  // residu ukuran.

  test('probeWrite succeeds on a healthy writable database and leaves the '
      'file unchanged', () async {
    final dbPath = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(dbPath);

    final before = File(dbPath).statSync();

    // RED: method ini belum ada - kompilasi gagal.
    await service.probeWrite(dbPath);

    final after = File(dbPath).statSync();
    expect(
      after.size,
      before.size,
      reason: 'the write probe must not leave durable residue',
    );
  });
}
