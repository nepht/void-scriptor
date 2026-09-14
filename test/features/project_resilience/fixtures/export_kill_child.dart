// 145.42 interrupted-export — child process kill harness.
//
// Child Dart MURNI (tanpa Flutter engine): closure produksi
// PortableProjectExporter menarik path_provider -> flutter -> dart:ui yang
// tidak tersedia di VM murni (sudah diprobe), jadi child me-replay persis
// jendela staging produksi memakai PANGGILAN PRODUKSI YANG SAMA
// (`ZipFileEncoder().zipDirectory(temp, filename: '<final>.tmp')`): salin
// paket ke staging systemTemp (meniru _copy exporter) plus payload filler
// ~30 MB, mulai stream zip ke path staging, laporkan ZIPPING begitu staging
// tercipta, lalu HANG. Parent meng-hard-kill (Windows: TerminateProcess)
// segera setelah ZIPPING — kill dijamin mendarat mid-stream karena close()
// (central directory + EOCD) baru ditulis setelah seluruh filler ter-deflate.
// Verifikasi staging dan rename final TIDAK pernah dieksekusi dan jalur
// cleanup in-process (catch + finally) tidak pernah berjalan — persis kondisi
// OS kill. Pemulihan lalu dibuktikan oleh parent lewat `exportPortable`
// produksi NYATA di proses baru.
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final packageRoot = args[0];
  final finalPath = args[1];
  final staging = File('$finalPath.tmp');

  // Stage a faithful copy of the package — the same manifest/database/
  // assets layout PortableProjectExporter copies before zipping — plus
  // incompressible filler so the zip stream is still open when the kill
  // lands.
  final temp = await Directory.systemTemp.createTemp('voidproject-export-');
  stdout.writeln('TEMP ${temp.path}');
  await stdout.flush();
  Future<void> copyTree(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(recursive: true)) {
      final relative = p.relative(entity.path, from: source.path);
      final destination = p.join(target.path, relative);
      if (entity is Directory) {
        await Directory(destination).create(recursive: true);
      } else if (entity is File) {
        await File(destination).parent.create(recursive: true);
        await entity.copy(destination);
      }
    }
  }

  for (final area in <String>['manifest', 'database', 'assets']) {
    final source = Directory(p.join(packageRoot, area));
    if (await source.exists()) {
      await copyTree(source, Directory(p.join(temp.path, area)));
    }
  }

  final random = Random(14542);
  final filler = Uint8List(1 << 20);
  for (var i = 0; i < filler.length; i++) {
    filler[i] = random.nextInt(256);
  }
  final bulk = Directory(p.join(temp.path, 'bulk'))..createSync();
  for (var f = 0; f < 100; f++) {
    await File(
      p.join(bulk.path, 'bulk-$f.bin'),
    ).writeAsBytes(filler, flush: true);
  }

  // Exact production call shape. The handle is created synchronously at
  // 0 bytes when the encoder opens, so the mid-stream marker is real
  // flushed staging bytes (the encoder's 1 MB buffer proves it is inside
  // the addDirectory await loop, long before close/verify/rename).
  unawaited(ZipFileEncoder().zipDirectory(temp, filename: staging.path));
  final deadline = DateTime.now().add(const Duration(seconds: 90));
  while (true) {
    if (staging.existsSync() && staging.lengthSync() >= 4 << 20) break;
    if (DateTime.now().isAfter(deadline)) {
      stderr.writeln('TIMEOUT waiting for mid-stream staging growth');
      exit(2);
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  stdout.writeln('ZIPPING ${staging.lengthSync()}');
  await stdout.flush();

  // Never close the encoder, never verify, never rename, never clean up:
  // only an OS kill ends us, exactly the interrupted-export crash window.
  final keepAlive = ReceivePort();
  await keepAlive.first;
  keepAlive.close();
}

void unawaited(Future<void> future) {}
