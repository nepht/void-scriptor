import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:void_scriptor/database/project/project_database_service.dart';

/// Sprint 145.42 - klasifikasi kode hasil sqlite pada jalur open
/// (bug-hunt run94, BUG-13).
///
/// Sebelumnya open() membandingkan kode yang sudah dimask `& 0xFF`
/// terhadap literal extended 778 (SQLITE_IOERR_WRITE). 778 & 0xFF = 10,
/// sehingga cabang itu tidak pernah match dan seluruh keluarga
/// SQLITE_IOERR (primary 10) jatuh ke klasifikasi korut
/// ([ProjectDatabaseUnreadableException]) di jalur open produksi.
///
/// Kontrak diuji langsung pada fungsi klasifikasi murni tanpa I/O:
/// IOERR = media tulis bermasalah (write-failure), bukan korupsi.
void main() {
  const databasePath = '/tmp/hermes-test/project.db';

  sqlite.SqliteException synthetic(int extended) => sqlite.SqliteException(
    extendedResultCode: extended,
    message: 'synthetic sqlite failure $extended',
  );

  test('SQLITE_IOERR_WRITE (extended 778) diklasifikasikan write-failure, '
      'bukan korupsi', () {
    expect(
      classifyProjectDatabaseOpenError(databasePath, synthetic(778)),
      isA<ProjectDatabaseWriteFailedException>(),
    );
  });

  test('seluruh keluarga SQLITE_IOERR (primary 10: 10/266/522/778/1034) '
      'diklasifikasikan write-failure', () {
    for (final extended in const <int>[10, 266, 522, 778, 1034]) {
      expect(
        classifyProjectDatabaseOpenError(databasePath, synthetic(extended)),
        isA<ProjectDatabaseWriteFailedException>(),
        reason:
            'extended $extended (primary ${extended & 0xFF}) '
            'harus write-failure',
      );
    }
  });

  test('SQLITE_NOTADB (26) tetap diklasifikasikan korut', () {
    expect(
      classifyProjectDatabaseOpenError(databasePath, synthetic(26)),
      isA<ProjectDatabaseUnreadableException>(),
    );
  });

  test('SQLITE_CORRUPT (11) tetap diklasifikasikan korut', () {
    expect(
      classifyProjectDatabaseOpenError(databasePath, synthetic(11)),
      isA<ProjectDatabaseUnreadableException>(),
    );
  });

  test('klasifikasi non-IOERR yang sudah ada dipertahankan', () {
    final cases = <int, Type>{
      5: ProjectDatabaseLockedException,
      8: ProjectDatabaseWriteFailedException,
      13: ProjectDatabaseWriteFailedException,
      14: ProjectDatabaseUnavailableException,
    };
    cases.forEach((extended, type) {
      final classified = classifyProjectDatabaseOpenError(
        databasePath,
        synthetic(extended),
      );
      expect(
        classified.runtimeType,
        type,
        reason: 'extended $extended harus $type',
      );
    });
  });
}
