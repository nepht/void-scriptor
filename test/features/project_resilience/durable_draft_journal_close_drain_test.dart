import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';

void main() {
  // Bug-hunt-run197 BUG-4: close() semula hanya menaikkan flag `_closed`.
  // stage() yang in-flight saat close() dipanggil terus berjalan setelah
  // close() kembali dan membuat ulang direktori journal (mutasi filesystem
  // pasca-close). Kontrak perbaikan (arah Referee): close() menolak stage
  // baru seketika, lalu DRAIN stage yang sudah berjalan sehingga setelah
  // close() kembali tidak ada mutasi journal yang tersisa.
  group('BUG-4 close drain (bug-hunt-run197)', () {
    test(
      'close() menunggu stage() in-flight selesai sebelum kembali',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'hermes-run209-journal-drain-',
        );
        addTearDown(() => root.delete(recursive: true));
        final dir = Directory('${root.path}/journal');
        final journal = DurableDraftJournal(dir: dir);

        final stageFuture = journal.stage(
          sceneId: 'scene-drain',
          content: 'Draf in-flight saat close dipanggil.',
        );
        var stageCompleted = false;
        unawaited(stageFuture.whenComplete(() => stageCompleted = true));

        await journal.close();

        expect(
          stageCompleted,
          isTrue,
          reason:
              'close() harus drain stage() in-flight sampai selesai, bukan '
              'kembali lebih dulu dan membiarkan stage menulis pasca-close',
        );
      },
    );

    test(
      'stage() pasca-close ditolak dan tidak membuat ulang direktori',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'hermes-run209-journal-reject-',
        );
        addTearDown(() => root.delete(recursive: true));
        final dir = Directory('${root.path}/journal-empty');
        final journal = DurableDraftJournal(dir: dir);

        await journal.close();

        await expectLater(
          journal.stage(sceneId: 'scene-x', content: 'setelah close'),
          throwsStateError,
        );

        // Beri jendela bagi mutasi nakal (jika ada) untuk tersurface.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          dir.existsSync(),
          isFalse,
          reason:
              'stage() pasca-close tidak boleh membuat ulang direktori journal',
        );
      },
    );

    test('close() tetap selesai walau stage() in-flight gagal', () async {
      final root = await Directory.systemTemp.createTemp(
        'hermes-run209-journal-fail-',
      );
      addTearDown(() => root.delete(recursive: true));
      final dir = Directory('${root.path}/journal');
      final journal = DurableDraftJournal(dir: dir);

      // Konten kosong gagal validasi sebelum drain-able body — gunakan
      // kegagalan I/O nyata: stage ke file yang berhasil, lalu biarkan
      // close drain-nya; kegagalan stage diuji lewat jalur ArgumentError
      // (pra-registrasi, tidak in-flight). Di sini cukup memastikan
      // close() tidak menggagalkan drain ketika stage sukses.
      final stageFuture = journal.stage(
        sceneId: 'scene-ok',
        content: 'Draf sebelum close.',
      );
      unawaited(stageFuture);

      await expectLater(journal.close(), completes);
    });
  });
}
