import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/portable_project_service.dart';

import '../../support/real_dart_executable.dart';

/// 145.42 interrupted-export (portable path) — hard process kill NYATA pada
/// jendela staging-vs-rename. Child Dart murni me-replay panggilan produksi
/// yang sama (`ZipFileEncoder().zipDirectory(temp, filename: '<final>.tmp')`)
/// lalu di-TerminateProcess oleh parent selagi stream zip berjalan:
/// verifikasi staging, rename final, dan cleanup in-process terbukti TIDAK
/// pernah berjalan. Kontrak yang dipulihkan (retry-safe + cross-process
/// sweep): export berikutnya di proses baru HARUS tetap sukses, memakan
/// corpse `<final>.tmp`, menghasilkan arsip valid byte-verified, dan namespace
/// exports kembali bersih. Ini bukan simulasi throw in-process — OS kill nyata
/// atas corpse nyata.
void main() {
  test(
    'OS kill mid-export: next exportPortable heals the real staging corpse',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-export-kill-');
      addTearDown(() {
        try {
          root.deleteSync(recursive: true);
        } on FileSystemException {
          // Best-effort: child's open handle may still linger post-kill.
        }
      });
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Export Kill Harness');
      final exportDir = package.exportDirectory;
      await exportDir.create(recursive: true);
      final finalPath = '${exportDir.path}/${package.projectId}.voidproject';
      final staging = File('$finalPath.tmp');

      final dartExe = await resolveRealDartExecutable();
      final childScript = File(
        'test/features/project_resilience/fixtures/export_kill_child.dart',
      );
      expect(
        await childScript.exists(),
        isTrue,
        reason: 'child script fixture must exist for the kill harness',
      );

      final process = await Process.start(dartExe, <String>[
        childScript.absolute.path,
        package.root.path,
        finalPath,
      ], workingDirectory: Directory.current.path);
      final zipping = Completer<void>();
      final tempDir = Completer<String>();
      final stderrText = StringBuffer();
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            final trimmed = line.trim();
            if (trimmed.startsWith('TEMP ') && !tempDir.isCompleted) {
              tempDir.complete(trimmed.substring(5));
            }
            if (trimmed.startsWith('ZIPPING') && !zipping.isCompleted) {
              zipping.complete();
            }
          });
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(stderrText.writeln);

      await zipping.future.timeout(const Duration(seconds: 120));
      // Child sits mid-zip with the staging handle open and the final path
      // untouched: kill it at the OS level.
      final killed = process.kill();
      expect(killed, isTrue, reason: 'hard kill must succeed');
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 15),
      );
      expect(
        exitCode,
        isNot(0),
        reason: 'hard-killed child must exit nonzero (stderr: $stderrText)',
      );

      // Corpse preconditions: a PARTIAL staging archive exists (the child
      // had opened the encoder), the final path never materialized.
      expect(
        await staging.exists(),
        isTrue,
        reason: 'killed export must leave the staging corpse on disk',
      );
      final corpseSize = await staging.length();
      expect(
        corpseSize,
        greaterThan(0),
        reason: 'the corpse must carry genuinely written bytes',
      );
      expect(
        await File(finalPath).exists(),
        isFalse,
        reason: 'an interrupted export must never reach the final path',
      );
      // The corpse is structurally a truncated archive: no valid central
      // directory/EOCD — prove decode-fail or missing required entries so
      // this test cannot pass on a completed archive.
      var corpseInvalid = false;
      try {
        final decoded = ZipDecoder().decodeBytes(
          await staging.readAsBytes(),
          verify: true,
        );
        corpseInvalid =
            decoded.find('manifest/project.json') == null ||
            decoded.find('database/project.db') == null ||
            !ArchiveIntegrity.verify(decoded);
      } on Object {
        corpseInvalid = true;
      }
      expect(
        corpseInvalid,
        isTrue,
        reason: 'the kill must have landed BEFORE the archive was closed',
      );

      // PRODUCTION RECOVERY 1 (same process, retry path): exportPortable
      // must reclaim the corpse instead of failing on it.
      final recovered = await PortableProjectExporter().exportPortable(
        package,
        destination: exportDir,
      );
      expect(
        p.equals(recovered.path, finalPath),
        isTrue,
        reason: 'the retry must produce the archive at the final path',
      );
      final verified = ZipDecoder().decodeBytes(
        await recovered.readAsBytes(),
        verify: true,
      );
      expect(
        verified.find('manifest/project.json'),
        isNotNull,
        reason: 'recovered archive must be a complete portable package',
      );
      expect(verified.find('database/project.db'), isNotNull);
      expect(
        ArchiveIntegrity.verify(verified),
        isTrue,
        reason: 'recovered archive must pass the integrity contract',
      );
      expect(
        await staging.exists(),
        isFalse,
        reason: 'the retry must consume the interrupted-export corpse',
      );

      // PRODUCTION RECOVERY 2 (cross-process sweep): plant a fresh corpse
      // exactly as a dead session leaves one, then prove the NEXT live
      // process's export still succeeds and sweeps it.
      await staging.writeAsBytes(List<int>.filled(4096, 0xAB), flush: true);
      final second = await PortableProjectExporter().exportPortable(
        package,
        destination: exportDir,
      );
      expect(await second.exists(), isTrue);
      expect(
        await staging.exists(),
        isFalse,
        reason: 'a planted corpse must be reclaimed, never block recovery',
      );
      final leftoverTmps = exportDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.tmp'))
          .toList();
      expect(
        leftoverTmps,
        isEmpty,
        reason: 'the exports namespace must end clean after recovery',
      );

      // Child's orphaned staging temp dir: the child died while the zip
      // stream was open — close() and the production finally NEVER ran, so
      // its staging dir is a real orphan of the crash window. Assert it
      // exists (proof the kill landed mid-flight, not after completion),
      // then delete it so the harness leaves no litter on the machine.
      // Note: the sibling-pinned contract in
      // portable_export_interrupt_safety_test.dart requires a DIRECTORY at
      // `<final>.tmp` to fail the next export loudly (safe-by-default); the
      // real OS-kill corpse here is a FILE (encoder stream open), which the
      // retry provably reclaims above — the two contracts are consistent.
      final childTemp = tempDir.isCompleted ? await tempDir.future : null;
      expect(
        childTemp,
        isNotNull,
        reason: 'child must report its staging temp dir',
      );
      expect(
        Directory(childTemp!).existsSync(),
        isTrue,
        reason:
            'OS kill must leave the exporter staging dir orphaned '
            '(the in-process finally never ran)',
      );
      try {
        Directory(childTemp).deleteSync(recursive: true);
      } on FileSystemException {
        // Harness litter only; the OS temp namespace reclaims it later.
      }
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
