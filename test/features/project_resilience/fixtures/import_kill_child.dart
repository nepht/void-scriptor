// 145.42 interrupted-import — child process kill harness.
//
// Child Dart MURNI (tanpa Flutter engine): me-replay persis urutan produksi
// PortableProjectImportCoordinator memakai kelas produksi Flutter-free
// ImportClaim — tulis claim sentinel SEBELUM rename paket asli ke stash
// tersembunyi, lalu tulis scratch ekstraksi parsial di path canonical
// (tanpa manifest, persis corpse mid-extract), lalu di-HANG-kan. Parent
// meng-hard-kill di OS level (Windows: TerminateProcess) saat child berada
// di tengah jendela ekstraksi, membuktikan rollback Dart in-process TIDAK
// pernah berjalan — hanya pemulihan produksi lintas-proses yang bisa
// menyelamatkan paket asli pengguna.
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/persistence/import_claim.dart';

Future<void> main(List<String> args) async {
  final destination = args[0];
  final originalPackagePath = args[1];
  final projectId = args[2];

  final dest = Directory(destination);
  final stash = Directory(
    p.join(dest.path, '.$projectId.voidproject.import-backup-killharness'),
  );

  // Production order: claim sentinel FIRST, then the collision stash rename.
  await ImportClaim.create(
    destination: dest,
    projectId: projectId,
    stashPath: stash.path,
  );
  stdout.writeln('CLAIMED');
  await stdout.flush();

  await Directory(originalPackagePath).rename(stash.path);
  stdout.writeln('STASHED');
  await stdout.flush();

  // Partial extraction: scratch at the canonical path with NO manifest —
  // the exact corpse shape that made pre-claim recovery blind forever.
  final canonical = Directory(p.join(dest.path, '$projectId.voidproject'));
  final assets = Directory(p.join(canonical.path, 'assets'))
    ..createSync(recursive: true);
  await File(
    p.join(assets.path, 'partial-1.bin'),
  ).writeAsString('half-extracted scratch 1', flush: true);
  await File(
    p.join(canonical.path, 'database', 'project.db.part'),
  ).parent.create(recursive: true);
  await File(
    p.join(canonical.path, 'database', 'project.db.part'),
  ).writeAsString('half-extracted scratch 2', flush: true);
  stdout.writeln('SCRATCH_WRITTEN');
  await stdout.flush();

  // Mid-extraction: never finish the import. ReceivePort never completes;
  // only an OS kill ends us (claim stays on disk exactly as production
  // leaves it when the process dies).
  final keepAlive = ReceivePort();
  try {
    await keepAlive.first;
  } finally {
    keepAlive.close();
  }
}
