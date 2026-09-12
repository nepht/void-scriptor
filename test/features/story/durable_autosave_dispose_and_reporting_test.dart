// vs-hunt-20260912-autosave BUG-3 (Medium) + BUG-17 (Low).
//
// BUG-3: dispose() lama memanggil saveNow() saat _saving=true; saveNow
// hanya set _retryRequested lalu RETURN, sehingga dispose resolve sebelum
// draf terbaru dipersist. finally save pertama lalu mengarm Timer 1.5s
// SETELAH objek disposed — dead session tetap menulis.
// BUG-17: _persist + acknowledge + onSaved berada dalam SATU catch;
// acknowledge/onSaved error dilaporkan sebagai "Gagal menyimpan draf"
// padahal DB persist sukses.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';
import 'package:void_scriptor/features/story/application/durable_autosave_coordinator.dart';

void main() {
  test(
    'dispose waits in-flight save AND flushes newest pending draft (BUG-3)',
    () async {
      final firstGate = Completer<void>();
      final persisted = <String>[];
      final coordinator = DurableAutosaveCoordinator(
        debounceDelay: const Duration(seconds: 30),
        persist: (sceneId, content) async {
          persisted.add(content);
          if (content == 'v1') await firstGate.future;
        },
      );

      await coordinator.onDraftChanged(sceneId: 'scene-a', content: 'v1');
      final saveV1 = coordinator.saveNow(); // in-flight tertahan
      await coordinator.onDraftChanged(sceneId: 'scene-a', content: 'v2');

      var disposed = false;
      final disposing = coordinator.dispose().then((_) => disposed = true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(disposed, isFalse, reason: 'dispose wajib menunggu save v1');

      firstGate.complete();
      await saveV1;
      await disposing;

      expect(
        persisted,
        ['v1', 'v2'],
        reason: 'dispose wajib flush konten terbaru, bukan mengarm timer mati',
      );
      // Tidak ada timer post-dispose: tunggu > debounce mini tidak menambah save.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(persisted, ['v1', 'v2']);
    },
  );

  test(
    'acknowledge/onSaved failure is NOT reported as persist failure (BUG-17)',
    () async {
      final root = await Directory.systemTemp.createTemp('run255-ack-error-');
      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });
      final journal = DurableDraftJournal(
        dir: Directory('${root.path}/journal'),
      );
      final persisted = <String>[];
      final persistErrors = <Object>[];
      final ackErrors = <Object>[];
      final coordinator = DurableAutosaveCoordinator(
        debounceDelay: const Duration(seconds: 30),
        persist: (sceneId, content) async => persisted.add(content),
        journal: journal,
        onPersistError: (sceneId, content, error) => persistErrors.add(error),
        onAcknowledgeError: (sceneId, content, error) => ackErrors.add(error),
      );

      await coordinator.onDraftChanged(
        sceneId: 'scene-a',
        content: 'tersimpan',
      );
      // Paksa onSaved melempar SETELAH persist+ack sukses.
      final throwing = DurableAutosaveCoordinator(
        debounceDelay: const Duration(seconds: 30),
        persist: (sceneId, content) async => persisted.add(content),
        onSaved: (sceneId, content) => throw StateError('callback UI gagal'),
        onPersistError: (sceneId, content, error) => persistErrors.add(error),
        onAcknowledgeError: (sceneId, content, error) => ackErrors.add(error),
      );
      await throwing.onDraftChanged(sceneId: 'scene-b', content: 'durable');
      await throwing.saveNow();

      expect(persisted, contains('durable'));
      expect(
        persistErrors,
        isEmpty,
        reason: 'persist SUKSES: callback/ack error bukan gagal simpan',
      );
      expect(ackErrors, hasLength(1));
      await throwing.dispose();
      await coordinator.dispose();
    },
  );
}
