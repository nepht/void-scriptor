import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:void_scriptor/database/project/project_database_service.dart';

/// Bug-hunt run94 BUG-07 + BUG-08 (Referee REAL BUG) - write-probe purity.
///
/// Kontrak [ProjectDatabaseService.probeWrite]: probe tulis TIDAK boleh
/// memodifikasi data aplikasi. Temuan run94:
/// - BUG-07: COMMIT probe sebelum DROP membuka jendela crash yang
///   meninggalkan tabel __scriptor_write_probe permanen di DB pengguna.
///   Injeksi deterministik tanpa crash: trigger poison BEFORE DELETE
///   RAISE(ABORT) membuat jalur cleanup lama gagal SETELAH COMMIT
///   pertama - residu tabel terukur. Implementasi satu-transaksi
///   (CREATE+DROP dalam transaksi yang sama) melewati DELETE dan
///   rollback otomatis pada kegagalan apa pun.
/// - BUG-08: sidecar -wal/-shm dihapus tanpa syarat. Pada POSIX,
///   unlink-while-open membuang status transaksi committed milik
///   koneksi WAL lain. Di Windows behavioral RED tidak dapat
///   diproduksi (deleteSync gagal sharing violation saat koneksi
///   hidup), sehingga fix penghapusan loop dibuktikan lewat review
///   kode + test penjaga, bukan RED native Windows.
/// - Purity tambahan run101: PRAGMA journal_mode = WAL mengubah mode
///   jurnal DB pengguna secara permanen (header byte 18-19) untuk
///   database rollback-journal - modifikasi bentuk data aplikasi
///   yang melanggar kontrak yang sama.
void main() {
  late Directory root;
  setUp(
    () async => root = await Directory.systemTemp.createTemp('hermes-dbprobe-'),
  );
  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      root.deleteSync(recursive: true);
    }
  });

  // SQLite file format: byte 18 = write version, byte 19 = read version.
  // 1 = rollback journal, 2 = WAL.
  List<int> journalHeader(String path) =>
      File(path).readAsBytesSync().sublist(18, 20);

  test('probeWrite does not change the journal mode of a rollback-journal '
      'database', () async {
    final dbPath = '${root.path}/project.db';
    // Database rollback-journal (bukan produk create() yang sudah WAL
    // via drift): dibangun manual supaya perubahan mode terukur.
    final seed = sqlite.sqlite3.open(dbPath);
    seed.execute('CREATE TABLE app_data (v INTEGER NOT NULL)');
    seed.execute('INSERT INTO app_data (v) VALUES (1)');
    seed.close();
    expect(journalHeader(dbPath), <int>[1, 1]);

    await service().probeWrite(dbPath);

    expect(
      journalHeader(dbPath),
      <int>[1, 1],
      reason:
          'probe tidak boleh mengubah mode jurnal DB pengguna '
          'secara permanen (WAL di header = modifikasi data aplikasi)',
    );
    expect(
      File('$dbPath-wal').existsSync(),
      isFalse,
      reason:
          'probe pada DB rollback-journal tidak boleh meninggalkan '
          'sidecar WAL',
    );
  });

  test('probeWrite leaves no probe residue when cleanup is sabotaged '
      'mid-probe', () async {
    final dbPath = '${root.path}/project.db';
    await service().create(dbPath);

    // Jebakan deterministik untuk jalur cleanup lama: tabel probe
    // dibuat lebih dulu dengan trigger yang menggagalkan DELETE.
    // Implementasi lama: COMMIT pertama sudah mengunci residu, lalu
    // DELETE meledak -> tabel + trigger tertinggal permanen.
    final trap = sqlite.sqlite3.open(dbPath);
    trap.execute(
      'CREATE TABLE __scriptor_write_probe (id INTEGER PRIMARY KEY)',
    );
    trap.execute(
      'CREATE TRIGGER poison_before_delete '
      'BEFORE DELETE ON __scriptor_write_probe '
      'BEGIN SELECT RAISE(ABORT, \'cleanup sabotaged\'); END',
    );
    trap.close();

    try {
      await service().probeWrite(dbPath);
    } on ProjectDatabaseWriteFailedException {
      // Kegagalan bertipe diperbolehkan; yang dilarang adalah residu.
    }

    final raw = sqlite.sqlite3.open(dbPath);
    try {
      final tables = raw.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name = '__scriptor_write_probe'",
      );
      final triggers = raw.select(
        "SELECT name FROM sqlite_master WHERE type = 'trigger' "
        "AND name = 'poison_before_delete'",
      );
      expect(
        tables,
        isEmpty,
        reason:
            'kegagalan di tengah probe tidak boleh meninggalkan '
            'tabel probe di database pengguna',
      );
      expect(
        triggers,
        isEmpty,
        reason:
            'jebakan cleanup harus ter-bersihkan bersama tabel '
            'probe (satu transaksi, bukan cleanup bertahap)',
      );
    } finally {
      raw.close();
    }
  });

  test('probeWrite leaves no probe-table residue', () async {
    final dbPath = '${root.path}/project.db';
    await service().create(dbPath);

    await service().probeWrite(dbPath);

    final raw = sqlite.sqlite3.open(dbPath);
    try {
      final tables = raw.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name = '__scriptor_write_probe'",
      );
      expect(
        tables,
        isEmpty,
        reason: 'tabel probe tidak boleh tersisa di database pengguna',
      );
    } finally {
      raw.close();
    }
  });

  test('probeWrite never deletes WAL sidecars of a concurrently open '
      'connection', () async {
    // Penjaga Windows: deleteSync terhadap file yang dipegang koneksi
    // hidup gagal sharing violation, jadi test ini membuktikan data
    // committed tetap utuh + sidecar tidak hilang di host ini. Bukti
    // POSIX (unlink-while-open) tidak dapat diproduksi di Windows.
    final dbPath = '${root.path}/project.db';
    await service().create(dbPath);

    final live = sqlite.sqlite3.open(dbPath);
    try {
      live.execute('PRAGMA journal_mode = WAL');
      live.execute('CREATE TABLE committed_data (v INTEGER NOT NULL)');
      live.execute('INSERT INTO committed_data (v) VALUES (7)');

      await service().probeWrite(dbPath);

      expect(
        File('$dbPath-wal').existsSync(),
        isTrue,
        reason: 'sidecar WAL milik koneksi hidup tidak boleh dihapus',
      );
      expect(File('$dbPath-shm').existsSync(), isTrue);

      final row = live.select('SELECT v FROM committed_data');
      expect(row, hasLength(1));
      expect(row.first['v'], 7);

      final fresh = sqlite.sqlite3.open(dbPath);
      try {
        final visible = fresh.select('SELECT v FROM committed_data');
        expect(
          visible,
          hasLength(1),
          reason:
              'data yang sudah di-commit harus tetap terlihat oleh '
              'koneksi baru setelah probe',
        );
        expect(visible.first['v'], 7);
      } finally {
        fresh.close();
      }
    } finally {
      live.close();
    }
  });
}

ProjectDatabaseService service() => ProjectDatabaseService();
