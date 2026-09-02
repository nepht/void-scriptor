import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';

/// Step 145.30 - native process-kill harness.
///
/// Harness ini membuktikan no-silent-loss di bawah hard-kill OS nyata
/// (TerminateProcess), bukan simulasi in-process seperti test sebelumnya:
/// 1. Child process Dart nyata men-stage draf ke journal lalu sleep diam
///    (tidak ada exit, tidak ada flush eksplisit) - parent membunuhnya
///    dengan Process.kill.
/// 2. Parent membaca journal yang ditinggalkan child yang mati paksa dan
///    memulihkan konten.
/// 3. Sebuah .tmp setengah jadi ditanam untuk membuktikan file setengah
///    jadi TIDAK pernah dianggap sumber pemulihan (no silent loss).
void main() {
  test(
    'journal content written by a hard-killed real process is fully '
    'recoverable (no silent loss)',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'hermes-s30-prockill-',
      );
      addTearDown(() => root.delete(recursive: true));
      final journalDir = Directory('${root.path}/recovery/draft-journal');

      // Di dalam `flutter test`, Platform.resolvedExecutable =
      // flutter_tester.exe (tidak bisa menjalankan script Dart biasa).
      // Resolve dart VM nyata dari FLUTTER_ROOT; fallback ke
      // resolvedExecutable untuk eksekusi `dart test` langsung.
      final flutterRoot = Platform.environment['FLUTTER_ROOT'];
      final isWindows = Platform.isWindows;
      final dartExe = (flutterRoot == null || flutterRoot.isEmpty)
          ? Platform.resolvedExecutable
          : <String>[
              flutterRoot,
              'bin',
              'cache',
              'dart-sdk',
              'bin',
              isWindows ? 'dart.exe' : 'dart',
            ].join(Platform.pathSeparator);
      final childScript = File(
        'test/features/project_resilience/fixtures/'
        'draft_journal_hard_kill_child.dart',
      );
      expect(
        await childScript.exists(),
        isTrue,
        reason: 'child script fixture must exist for the kill harness',
      );

      final process = await Process.start(
        dartExe,
        <String>[childScript.absolute.path, journalDir.absolute.path],
        workingDirectory: Directory.current.path,
      );

      // Tunggu sinyal siap-kill dari child (stdout line 'READY').
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
        if (!readyCompleter.isCompleted) {
          readyCompleter.completeError(
            StateError('child failed before READY: $line'),
          );
        }
      });

      await readyCompleter.future.timeout(const Duration(seconds: 30));

      // Kill paksa OS-level (Windows: TerminateProcess) TANPA memberi child
      // kesempatan flush/close - mensimulasikan crash/power-loss nyata.
      final killed = process.kill();
      expect(killed, isTrue, reason: 'hard kill must succeed');
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 15),
      );
      expect(exitCode, isNot(0), reason: 'hard-killed child must exit nonzero');

      // Parent membaca journal milik child yang mati paksa.
      final journal = DurableDraftJournal(dir: journalDir);
      final pending = await journal.pendingEntries();
      expect(pending, hasLength(1));
      expect(pending.single.sceneId, 'scene-kill-1');
      expect(pending.single.content, 'Draf terakhir sebelum aplikasi dibunuh paksa oleh OS.');

      // No silent loss: entri dipulihkan lalu di-acknowledge seperti alur
      // pemulihan startup yang dikendalikan pengguna.
      await journal.acknowledge(pending.single.sceneId);
      expect(await journal.pendingEntries(), isEmpty);
    },
  );

  test(
    'half-written tmp file from a killed writer is never treated as '
    'recoverable source',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'hermes-s30-prockill2-',
      );
      addTearDown(() => root.delete(recursive: true));
      final journalDir = Directory('${root.path}/recovery/draft-journal');
      await journalDir.create(recursive: true);

      // Simulasi .tmp setengah jadi dari writer yang dibunuh di tengah
      // penulisan (crash sebelum rename atomic).
      await File(
        '${journalDir.path}/scene-tmp.json.tmp',
      ).writeAsString('{"sceneId":"scene-tmp","content":"setengah');

      final journal = DurableDraftJournal(dir: journalDir);
      final pending = await journal.pendingEntries();
      expect(pending, isEmpty);
    },
  );
}
