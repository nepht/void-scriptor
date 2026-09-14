// 145.42 interrupted_restore — child process kill harness.
//
// Child proses Dart MURNI (tanpa Flutter engine): me-replay persis fase
// penempatan restore dua-fase memakai primitif produksi Flutter-free dari
// lib/core/persistence/restore_staging_journal.dart — staged trees ditulis,
// jurnal RestoreStagingJournal dibuat, area pertama (manifest) ditempatkan
// via placeStagedEntity, lalu proses di-HANG-kan. Parent meng-hard-kill di
// OS level (Windows: TerminateProcess) tepat di dalam jendela swap area
// kedua, kemudian memanggil RestoreCrashRecovery.recover() produksi untuk
// membuktikan roll-forward jurnal pada corpse nyata — bukan simulasi throw
// in-process.
import 'dart:io';
import 'dart:isolate';

import 'package:void_scriptor/core/persistence/restore_staging_journal.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';

Future<void> main(List<String> args) async {
  final packageRoot = args[0];
  final backupRoot = args[1];
  final root = Directory(packageRoot);
  final package = ProjectPackage(projectId: 'kill-harness', root: root);

  // Stage both directory areas exactly like ProjectBackupService phase 1.
  final stagedAssets = Directory('${package.assetsDirectory.path}.tmp');
  final stagedWorkspaces = Directory(
    '${root.path}${Platform.pathSeparator}workspaces.tmp',
  );
  Future<void> copyTree(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(recursive: true)) {
      if (entity is! File) continue;
      final dest = File(
        '${target.path}${entity.path.substring(source.path.length)}',
      );
      await dest.parent.create(recursive: true);
      await entity.copy(dest.path);
    }
  }

  await copyTree(Directory('$backupRoot/assets'), stagedAssets);
  await copyTree(Directory('$backupRoot/workspaces'), stagedWorkspaces);
  final journal = await RestoreStagingJournal.create(
    package,
    staged: {
      RestoreStagingJournal.assetsArea: stagedAssets,
      RestoreStagingJournal.workspacesArea: stagedWorkspaces,
    },
  );
  // Signal: staging + journal durable; placement NOT yet started. Parent
  // kills the process inside the first swap window below.
  stdout.writeln('STAGED');
  await stdout.flush();

  // Place area 1 (assets), then enter the workspaces swap window and never
  // leave it: delete-the-live-target half of the swap runs, the rename
  // never happens because the parent kills us in between.
  await placeStagedEntity(
    staged: journal.stagedEntity(RestoreStagingJournal.assetsArea),
    live: package.assetsDirectory,
  );
  stdout.writeln('ASSETS_PLACED');
  await stdout.flush();
  final workspacesLive = Directory(
    '${root.path}${Platform.pathSeparator}workspaces',
  );
  await workspacesLive.delete(recursive: true);
  // Hang mid-window: ReceivePort never completes; only an OS kill ends us.
  final keepAlive = ReceivePort();
  try {
    await keepAlive.first;
  } finally {
    keepAlive.close();
  }
}
