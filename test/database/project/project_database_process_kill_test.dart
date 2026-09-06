import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/database/project/project_database_service.dart';

import '../../support/real_dart_executable.dart';

/// Sprint 145.42 (Data Safety Failure Matrix) - process kill / power loss
/// pada layer database SQLite melalui harness OS-native (pola yang sudah
/// tervalidasi oleh durable_draft_journal_process_kill_test.dart di
/// step 145.30).
///
/// Kontrak yang dibuktikan pada jalur produksi [ProjectDatabaseService.open]:
/// 1. Data yang sudah COMMIT sebelum proses di-hard-kill selamat (durability
///    anchor synchronous FULL, mode journal rollback bawaan).
/// 2. Transaksi yang terbuka saat kill di-ROLLBACK (tidak pernah muncul
///    sebagai data).
/// 3. Database ber-residue crash (hot journal) TIDAK dilaporkan korup -
///    open() produksi memulihkannya dan database tetap menerima tulisan.
void main() {
  test('data committed before a hard kill survives while the open transaction '
      'rolls back and the production open path recovers the database', () async {
    final root = await Directory.systemTemp.createTemp('s14542-db-prockill-');
    addTearDown(() => root.delete(recursive: true));
    final databasePath = p.join(root.path, 'project.db');

    // `flutter test` tidak selalu mengekspor FLUTTER_ROOT dan
    // Platform.resolvedExecutable menunjuk ke flutter_tester, bukan Dart VM.
    final dartExe = await resolveRealDartExecutable();
    final childScript = File(
      'test/database/project/fixtures/db_process_kill_child.dart',
    );
    expect(
      await childScript.exists(),
      isTrue,
      reason: 'child fixture must exist for the DB kill harness',
    );

    final process = await Process.start(dartExe, <String>[
      'run',
      childScript.absolute.path,
      databasePath,
    ], workingDirectory: Directory.current.path);

    // Tunggu sinyal READY dari child: commit pertama sudah fsync dan
    // transaksi kedua (tidak di-commit) sedang terbuka.
    final readyCompleter = Completer<void>();
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (!readyCompleter.isCompleted && line.trim() == 'READY') {
            readyCompleter.complete();
          }
        });
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          // `dart run` menulis chatter build-hook ke stderr; hanya gagal cepat
          // untuk error nyata sebelum READY.
          if (!readyCompleter.isCompleted &&
              (line.contains('Error:') || line.contains('error:'))) {
            readyCompleter.completeError(
              StateError('child failed before READY: $line'),
            );
          }
        });

    await readyCompleter.future.timeout(const Duration(seconds: 120));

    // Hard kill OS-level TANPA memberi child kesempatan commit/close -
    // transaksi kedua pasti masih terbuka pada saat kill.
    final killed = process.kill();
    expect(killed, isTrue, reason: 'hard kill must succeed');
    final exitCode = await process.exitCode.timeout(
      const Duration(seconds: 15),
    );
    expect(exitCode, isNot(0), reason: 'hard-killed child must exit nonzero');

    // Jalur produksi membuka kembali database ber-residue crash:
    // hot journal di-rollback, data committed dipulihkan.
    final database = await ProjectDatabaseService().open(databasePath);
    addTearDown(database.close);

    final survivors = await database
        .customSelect('SELECT x FROM t ORDER BY x')
        .get();
    expect(
      survivors.map((row) => row.data['x']),
      <dynamic>['committed-before-kill'],
      reason:
          'committed data must survive the kill and the uncommitted '
          'open transaction must roll back',
    );

    // Database hasil pemulihan tetap menerima tulisan baru.
    await database.customStatement("INSERT INTO t VALUES ('post-kill-write')");
    final after = await database
        .customSelect('SELECT x FROM t ORDER BY x')
        .get();
    expect(after.map((row) => row.data['x']), <dynamic>[
      'committed-before-kill',
      'post-kill-write',
    ]);
  }, timeout: const Timeout(Duration(minutes: 4)));

  test('a database file torn by an interrupted write is rejected by the '
      'production open path (failure matrix is not vacuous)', () async {
    final root = await Directory.systemTemp.createTemp('s14542-db-torn-');
    addTearDown(() => root.delete(recursive: true));
    final databasePath = p.join(root.path, 'project.db');
    final sourcePath = p.join(root.path, 'source.db');

    // Bangun database valid lalu potong tepat di tengah tulisan -
    // meniru file yang mati saat checkpoint/write back (torn write).
    // Header SQLite di 16 byte pertama tetap ada sehingga ini benar-benar
    // file database yang terpotong, bukan file format asing.
    await ProjectDatabaseService().create(sourcePath);
    final original = await File(sourcePath).readAsBytes();
    expect(original.length, greaterThan(16));
    await File(
      databasePath,
    ).writeAsBytes(original.sublist(0, original.length ~/ 2));

    await expectLater(
      ProjectDatabaseService().open(databasePath),
      throwsA(isA<ProjectDatabaseUnreadableException>()),
    );
  });
}
