import 'dart:io';
import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Step 145.42 - Data Safety Failure Matrix (database layer).
///
/// Child process Dart nyata: membuka database SQLite di path yang diberikan,
/// melakukan satu transaksi yang COMMIT (durability anchor), lalu memulai
/// transaksi kedua yang sengaja TIDAK pernah di-commit, mencetak sinyal
/// READY, dan HANG tanpa exit tanpa close. Parent meng-hard-kill proses ini
/// di level OS (Windows: TerminateProcess) tepat ketika transaksi kedua
/// masih terbuka - simulasi crash/power-loss nyata di tengah tulis database.
Future<void> main(List<String> args) async {
  final databasePath = args[0];
  final db = sqlite.sqlite3.open(databasePath);
  final keepAlive = ReceivePort();
  try {
    db.execute('CREATE TABLE IF NOT EXISTS t (x TEXT)');
    db.execute("INSERT INTO t VALUES ('committed-before-kill')");
    db.execute('BEGIN');
    db.execute("INSERT INTO t VALUES ('uncommitted-must-die')");
    stdout.writeln('READY');
    await stdout.flush();
    // Tidak pernah keluar dengan sendirinya - parent HARUS meng-kill.
    await keepAlive.first;
  } finally {
    keepAlive.close();
    db.close();
  }
}
