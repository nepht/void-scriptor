// Regression for vs-hunt-20260915-resilience BUG-8 (Referee verdict: REAL BUG,
// Medium, project_resilience_controller.dart 261-280).
//
// Mechanism: retention pruning deleted the on-disk backup directory BEFORE
// removing its project_backups row, with no marker, retry, or reconciliation.
// If the row removal failed, the database kept a row pointing at a directory
// that no longer exists — a dangling backup the restore UI would offer and
// fail on.
//
// Contract proven here: prune writes a pending marker BEFORE the irreversible
// directory deletion, and `reconcileInterruptedPrunes()` finishes or unwinds
// every interrupted prune so no row can outlive its deleted directory.
//
// Fixture: disposable temp packages only; no user data, no real drive.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_controller.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_repository.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

Directory resolveBackupDir(ProjectPackage package, String storedPath) =>
    p.isAbsolute(storedPath)
    ? Directory(storedPath)
    : Directory(package.resolve(storedPath));

void main() {
  test('vs-hunt-20260915-resilience BUG-8: prune interrupted by row-removal '
      'failure leaves a marker, and reconcile finishes the deletion without a '
      'dangling row', () async {
    final root = await Directory.systemTemp.createTemp('hermes-bug8-int-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Bug8Int');
    final session = await ProjectSessionManager().open(package);
    addTearDown(session.close);
    final repository = session.database.projectResilienceRepository;
    final controller = ProjectResilienceController(
      session,
      retentionPolicy: const BackupRetentionPolicy(
        maxAutomatic: 20,
        maxManual: 1,
      ),
    );

    await controller.createBackup(note: 'victim');
    final victim = (await repository.backupsFor(
      package.projectId,
    )).firstWhere((r) => r.note == 'victim');

    // Fail the row removal exactly once, at the moment the original bug
    // became unrecoverable: AFTER the directory delete, BEFORE the delete
    // statement.
    controller.debugFailRemoveBackupForTest = (String id) async {
      if (id == victim.id) {
        throw const FileSystemException('injected removeBackup failure');
      }
    };

    await expectLater(
      controller.createBackup(note: 'trigger'),
      throwsA(isA<FileSystemException>()),
    );

    // The injected interruption state: victim directory is gone, its row
    // survived (the dangling row from the bug report), and a durable
    // marker proves the prune was mid-flight.
    final rowsMid = await repository.backupsFor(package.projectId);
    expect(rowsMid.map((r) => r.id), contains(victim.id));
    expect(
      await resolveBackupDir(package, victim.relativePath).exists(),
      isFalse,
    );
    final marker = File(
      p.join(package.backupDirectory.path, '.prune-${victim.id}.json'),
    );
    expect(await marker.exists(), isTrue);

    final repaired = await controller.reconcileInterruptedPrunes();
    expect(repaired, greaterThanOrEqualTo(1));

    final rowsAfter = await repository.backupsFor(package.projectId);
    expect(rowsAfter.map((r) => r.id), isNot(contains(victim.id)));
    // The newest backup survives untouched.
    expect(rowsAfter.map((r) => r.note), contains('trigger'));
    expect(await marker.exists(), isFalse);
  });

  test('vs-hunt-20260915-resilience BUG-8: marker written before the directory '
      'delete lets reconcile complete an interruption that happened BEFORE the '
      'deletion', () async {
    final root = await Directory.systemTemp.createTemp('hermes-bug8-pre-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Bug8Pre');
    final session = await ProjectSessionManager().open(package);
    addTearDown(session.close);
    final repository = session.database.projectResilienceRepository;
    final controller = ProjectResilienceController(session);

    await controller.createBackup(note: 'kept');
    final row = (await repository.backupsFor(
      package.projectId,
    )).firstWhere((r) => r.note == 'kept');

    // Hand-craft the mid-flight state: marker exists, directory AND row
    // still exist (death happened between marker write and deletion).
    final marker = File(
      p.join(package.backupDirectory.path, '.prune-${row.id}.json'),
    );
    await marker.parent.create(recursive: true);
    await marker.writeAsString(
      '{"backupId":"${row.id}","relativePath":"${row.relativePath}","stage":"pending"}',
    );

    final repaired = await controller.reconcileInterruptedPrunes();
    expect(repaired, greaterThanOrEqualTo(1));

    expect(await resolveBackupDir(package, row.relativePath).exists(), isFalse);
    final rows = await repository.backupsFor(package.projectId);
    expect(rows.map((r) => r.id), isNot(contains(row.id)));
    expect(await marker.exists(), isFalse);
  });

  test(
    'vs-hunt-20260915-resilience BUG-8: stale or structurally invalid markers '
    'are swept without touching recorded backups',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-bug8-stale-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Bug8Stale');
      final session = await ProjectSessionManager().open(package);
      addTearDown(session.close);
      final repository = session.database.projectResilienceRepository;
      final controller = ProjectResilienceController(session);

      await controller.createBackup(note: 'real');
      final row = (await repository.backupsFor(
        package.projectId,
      )).firstWhere((r) => r.note == 'real');

      final junk = File(
        p.join(package.backupDirectory.path, '.prune-junk.json'),
      );
      await junk.parent.create(recursive: true);
      await junk.writeAsString('not-json{');
      final noFields = File(
        p.join(package.backupDirectory.path, '.prune-nofields.json'),
      );
      await noFields.writeAsString('{}');

      await controller.reconcileInterruptedPrunes();

      expect(await junk.exists(), isFalse);
      expect(await noFields.exists(), isFalse);
      // The real backup is untouched: row present, directory present.
      final rows = await repository.backupsFor(package.projectId);
      expect(rows.map((r) => r.id), contains(row.id));
      expect(
        await resolveBackupDir(package, row.relativePath).exists(),
        isTrue,
      );
    },
  );
}
