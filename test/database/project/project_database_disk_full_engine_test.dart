import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:void_scriptor/database/project/project_database_service.dart';

/// Sprint 145.42 (Data Safety Failure Matrix) - case `explicit_disk_full`,
/// engine-path evidence.
///
/// Matriks memegang case ini sebagai PARTIAL dengan bukti injection
/// extended result code sintetis (run89). Slice ini menaikkan buktinya ke
/// level engine: SQLite yang sama dengan produksi (sqlite3_flutter_libs)
/// memancarkan SQLITE_FULL (13) **asli** dari jalur allokasi halaman, dan
/// exception asli engine itu diklasifikasikan typed di
/// [classifyProjectDatabaseOpenError] - cabang produksi yang sama dengan
/// READONLY (8), yang wiring open()-nya sudah dibuktikan engine-real oleh
/// `project_database_write_failure_test.dart` (attrib +R).
///
/// Mekanisme: `PRAGMA max_page_count = N` membatasi halaman yang boleh
/// dialokasikan per koneksi. Ketika tulisan harus menumbuhkan file melebihi
/// batas, engine gagal mengalokasi dan melaporkan SQLITE_FULL (13) - kode
/// permukaan yang sama dengan volume yang benar-benar penuh, tanpa media
/// virtual dan tanpa menyentuh disk pengguna (dilarang 2026-09-08). Batas
/// hanya hidup di koneksi injeksi; file fixture <= 3 halaman.
///
/// Batas jujur: volume-level live (VFS write() gagal ENOSPC) tidak
/// dieksekusi; itu tetap menunggu media virtual terisolasi.
void main() {
  late Directory root;
  setUp(
    () async => root = await Directory.systemTemp.createTemp('hermes-dbfull-'),
  );
  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // Windows: kunci file bisa bertahan sejenak setelah close.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      try {
        root.deleteSync(recursive: true);
      } on FileSystemException {
        // Fixture disposable; jangan gagalkan suite karena race kunci.
      }
    }
  });

  test('SQLite engine memancarkan SQLITE_FULL (13) asli saat tulis tidak '
      'dapat mengalokasi halaman baru', () {
    final dbPath = '${root.path}/fresh.db';
    final engine = sqlite.sqlite3.open(dbPath);
    addTearDown(engine.close);
    engine.execute('PRAGMA max_page_count = 1');

    // sqlite_master menempati halaman 1; root page tabel baru butuh
    // halaman berikutnya -> melewati batas -> SQLITE_FULL dari engine.
    expect(
      () => engine.execute('CREATE TABLE t (id INTEGER PRIMARY KEY)'),
      throwsA(
        isA<sqlite.SqliteException>().having(
          (e) => e.extendedResultCode,
          'extendedResultCode',
          13,
        ),
      ),
    );
  });

  test('exception SQLITE_FULL asli dari engine diklasifikasikan '
      'ProjectDatabaseWriteFailedException, bukan korupsi', () async {
    final dbPath = '${root.path}/classify.db';
    final service = ProjectDatabaseService();
    await service.create(dbPath);

    final engine = sqlite.sqlite3.open(dbPath);
    addTearDown(engine.close);
    engine.execute('PRAGMA max_page_count = 1');

    // Tangkap exception ASLI engine (bukan objek sintetis) dari
    // kegagalan allokasi yang sama dengan kondisi disk penuh.
    sqlite.SqliteException? engineError;
    try {
      engine.execute('CREATE TABLE t (id INTEGER PRIMARY KEY)');
    } on sqlite.SqliteException catch (error) {
      engineError = error;
    }
    expect(engineError, isNotNull);
    expect(engineError!.extendedResultCode, 13);

    expect(
      classifyProjectDatabaseOpenError(dbPath, engineError),
      isA<ProjectDatabaseWriteFailedException>(),
    );
  });

  test('kegagalan allokasi saat disk full tidak merusak data yang sudah '
      'di-commit dan tidak meninggalkan residu (integrity_check ok)', () {
    final dbPath = '${root.path}/residue.db';
    final engine = sqlite.sqlite3.open(dbPath);
    addTearDown(engine.close);

    // Seed sehat (CREATE + INSERT kecil) TANPA batas, lalu kunci batas ke
    // jumlah halaman yang sudah terpakai: INSERT berikutnya yang butuh
    // halaman tambahan -> SQLITE_FULL dari engine (bukan injeksi kode).
    engine.execute(
      'CREATE TABLE project_metadata (key TEXT NOT NULL, value TEXT NOT '
      'NULL, PRIMARY KEY (key))',
    );
    engine.execute(
      "INSERT INTO project_metadata (key, value) VALUES ('seed', 'ok')",
    );
    final pageCount =
        engine.select('PRAGMA page_count').single['page_count'] as int;
    engine.execute('PRAGMA max_page_count = $pageCount');

    expect(
      () => engine.execute(
        "INSERT INTO project_metadata (key, value) VALUES ('overflow', "
        " '${'x' * 8192}')",
      ),
      throwsA(
        isA<sqlite.SqliteException>().having(
          (e) => e.extendedResultCode,
          'extendedResultCode',
          13,
        ),
      ),
    );

    // Statement gagal dibatalkan; data committed utuh; database sehat.
    final integrity =
        engine.select('PRAGMA integrity_check').single['integrity_check']
            as String;
    expect(integrity, 'ok');
    final seed = engine.select(
      "SELECT value FROM project_metadata WHERE key = 'seed'",
    );
    expect(seed.single['value'], 'ok');
    final failed = engine.select(
      "SELECT count(*) AS n FROM project_metadata WHERE key = 'overflow'",
    );
    expect(failed.single['n'] as int, 0);

    // File tetap terbatas (<= 3 halaman): kegagalan tidak menumbuhkan
    // file secara liar.
    final size = File(dbPath).statSync().size;
    expect(size, lessThanOrEqualTo(3 * 4096));
  });
}
