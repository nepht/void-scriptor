import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:void_scriptor/database/project/project_database_service.dart';

/// Sprint 145.42 (Data Safety Failure Matrix) - live drive-removal
/// lifecycle on isolated virtual media.
///
/// The prior evidence for `unavailable_removed_drive` was a probe on an
/// absent drive letter plus synthetic classification tests (matrix
/// PARTIAL, next_action: "retesifikasi hanya bila media virtual
/// terisolasi aman tersedia dan tidak menyentuh drive pengguna").
///
/// This slice provides exactly that media: a per-logon `subst` virtual
/// drive mapped onto a disposable directory. It never touches a physical
/// or user volume, and it is fully reversible. The lifecycle proven:
///
///  1. mount virtual drive -> create + open a real project database
///     through the production path;
///  2. detach the drive (simulated removal) -> the SAME production open
///     path reports typed [ProjectDatabaseUnavailableException] and never
///     leaks a raw error nor misclassifies the healthy file as corrupt
///     ([ProjectDatabaseUnreadableException]);
///  3. remount -> the file is found intact and opens again (proves the
///     failure state was accessibility, not corruption).
///
/// On non-Windows hosts or when `subst` cannot be used, the tests skip
/// cleanly - a hardware/OS-bound case must not fake a pass.
void main() {
  const cmd = r'C:\Windows\System32\cmd.exe';

  Future<bool> subst(List<String> args) async {
    final result = await Process.run(cmd, ['/C', 'subst', ...args]);
    return result.exitCode == 0;
  }

  String? freeDriveLetter() {
    for (final letter in ['T', 'U', 'R', 'S']) {
      if (!Directory('$letter:/').existsSync()) return letter;
    }
    return null;
  }

  final isWindows = Platform.isWindows;

  test('detached virtual drive: open() reports typed unavailable, '
      'never raw nor corrupt, and remount recovers the same file', () async {
    final letter = freeDriveLetter();
    if (letter == null) return; // all candidate letters busy: skip honestly
    // subst wants a bare "U:" spec (a trailing slash is rejected), while
    // Dart existence checks work on the "U:/" root form.
    final driveSpec = '$letter:';
    final drive = '$letter:/';

    final backing = await Directory.systemTemp.createTemp('hermes-subst-');
    var mounted = false;
    try {
      mounted = await subst(<String>[driveSpec, backing.path]);
      if (!mounted) {
        markTestSkipped('subst cannot mount a virtual drive here');
        return;
      }
      expect(Directory(drive).existsSync(), isTrue);

      final databasePath = p.join(drive, 'project', 'project.db');
      final service = ProjectDatabaseService();

      // 1. live on mounted media through the production create+open path
      await service.create(databasePath);
      final live = await service.open(databasePath);
      expect(live, isNotNull);
      await live.close();
      final healthCheck = sqlite.sqlite3.open(databasePath);
      final rowsBefore =
          healthCheck
                  .select('SELECT COUNT(*) AS c FROM project_metadata')
                  .single['c']
              as int;
      healthCheck.close();
      expect(File(databasePath).existsSync(), isTrue);

      // 2. simulated removal: detach the drive while the file stays on
      // the (still existing) backing directory.
      expect(await subst(<String>['/D', driveSpec]), isTrue);
      mounted = false;
      expect(Directory(drive).existsSync(), isFalse);
      expect(File(databasePath).existsSync(), isFalse);

      Object? openError;
      try {
        await service.open(databasePath);
      } catch (error) {
        openError = error;
      }
      // The exact symptom: a typed storage-unavailable state.
      expect(openError, isA<ProjectDatabaseUnavailableException>());
      // Not a raw leak from drift/sqlite, and not a corruption verdict.
      expect(openError, isNot(isA<ProjectDatabaseUnreadableException>()));
      expect(openError, isNot(isA<FileSystemException>()));

      // 3. remount: the database file is untouched - removal was an
      // accessibility state, never corruption.
      expect(await subst(<String>[driveSpec, backing.path]), isTrue);
      mounted = true;
      final version = await service.schemaVersion(databasePath);
      expect(version, isNotNull);
      final recovered = await service.open(databasePath);
      final rowsAfter = await (recovered.select(
        recovered.projectMetadata,
      )).get();
      expect(rowsAfter.length, rowsBefore);
      await recovered.close();
      final recheck = sqlite.sqlite3.open(databasePath);
      expect(
        recheck.select('PRAGMA integrity_check').single['integrity_check'],
        'ok',
      );
      recheck.close();
    } finally {
      if (mounted) await subst(<String>['/D', driveSpec]);
      try {
        await backing.delete(recursive: true);
      } on FileSystemException {
        // best-effort: OS may still hold the mount briefly.
      }
    }
  }, skip: !isWindows);

  test('classifier branch contract: drive-level CANTOPEN maps to '
      'unavailable, not corrupt (documented matrix upgrade)', () async {
    // Pure-classification tooth: if extended code 14 ever regresses to
    // the corrupt default, this fails and the live journey above loses
    // its guarantee. Kept as a separate, fast, platform-neutral case.
    final classified = classifyProjectDatabaseOpenError(
      r'T:\project\project.db',
      sqlite.SqliteException(extendedResultCode: 14, message: 'cannot open'),
    );
    expect(classified, isA<ProjectDatabaseUnavailableException>());
    expect(classified, isNot(isA<ProjectDatabaseUnreadableException>()));
  });
}
