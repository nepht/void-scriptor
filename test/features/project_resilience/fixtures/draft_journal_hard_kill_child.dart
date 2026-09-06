// Step 145.30 - native process-kill harness fixture.
//
// Child process Dart nyata: men-stage draf ke DurableDraftJournal, mencetak
// sinyal READY (stage atomic + rename sudah selesai), lalu HANG tanpa exit,
// tanpa flush/close eksplisit. Parent meng-hard-kill proses ini di level OS
// (Windows: TerminateProcess) untuk mensimulasikan crash/power-loss nyata.
import 'dart:io';
import 'dart:isolate';

import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';

Future<void> main(List<String> args) async {
  final journalDir = Directory(args[0]);
  final journal = DurableDraftJournal(dir: journalDir);
  await journal.stage(
    sceneId: 'scene-kill-1',
    content: 'Draf terakhir sebelum aplikasi dibunuh paksa oleh OS.',
  );
  stdout.writeln('READY');
  await stdout.flush();
  // Tidak pernah keluar dengan sendirinya - parent HARUS kill.
  final keepAlive = ReceivePort();
  try {
    await keepAlive.first;
  } finally {
    keepAlive.close();
  }
}
