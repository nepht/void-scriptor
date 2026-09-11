import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/custom_storage_location.dart';

/// bug-hunt run197 BUG-17: `_Probe.checkWith` guarded the probe file's
/// `writeAsString(..., flush: true)` and its cleanup `delete` in ONE
/// try/catch. When the write succeeded but the cleanup delete hit a
/// transient sharing violation (the errno-32 fresh-file window this repo
/// documents for durable_draft_journal and ProjectLock), the healthy
/// location was classified `permissionDenied` and
/// `setActiveLocation`/`relinkLocation` rejected it.
///
/// Referee fix direction: the delete is best-effort cleanup — give it
/// its own try/catch so writability is classified from the write result
/// alone. A leftover `.vs_write_probe` is harmless residue, not a
/// permission problem.
///
/// Windows staging (the same handle-hold technique as run203's
/// rollback-restoreError test): holding the probe file open in append
/// mode makes the cleanup delete fail with errno 32, while the reopen +
/// write of the same path still succeeds (verified on this host:
/// WRITE_OK + DELETE_FAIL 32). POSIX unlinks open files, so the staged
/// RED is Windows-only.
void main() {
  test('a cleanup-delete sharing violation does not classify a writable '
      'location as permissionDenied', () async {
    final root = await Directory.systemTemp.createTemp('bug17-run197-');
    RandomAccessFile? handle;
    addTearDown(() async {
      try {
        await handle?.close();
      } catch (_) {}
      // A GREEN code path may leave harmless probe residue behind;
      // cleanup is best-effort here too.
      try {
        await File('${root.path}/.vs_write_probe').delete();
      } catch (_) {}
      try {
        await root.delete(recursive: true);
      } on FileSystemException catch (_) {}
    });

    // Stage the errno-32 delete window: create the probe file and hold
    // it open (append keeps the append cursor at the end without
    // rewinding the read cursor to 0). checkWith will re-open the same
    // path for its write — which still succeeds — and then fail its
    // cleanup delete.
    final probeFile = File('${root.path}/.vs_write_probe');
    await probeFile.writeAsString('held', flush: true);
    handle = await probeFile.open(mode: FileMode.append);

    // The real probe runs (no health seam): _Probe.checkWith re-opens
    // the same path for its write — which still succeeds — then fails
    // its cleanup delete on the held handle.
    final result = await CustomStorageLocation.probe(root.path);

    expect(
      result.writable,
      isTrue,
      reason:
          'BUG-17 run197: a failed cleanup delete after a successful '
          'write must not classify the location as unwritable.',
    );
    expect(result.reason, StorageProbeReason.ok);
  }, skip: !Platform.isWindows);
}
