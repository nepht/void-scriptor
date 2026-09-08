// Kontrak Draft Snapshot Compare & Restore (Step 109.22) — RED pertama.
//
// Acceptance kanonik sprint_109.json: automatic_snapshot,
// manual_snapshot, diff_view, restore_creates_backup, retention_controls.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/domain/draft_snapshots.dart';

void main() {
  group('automatic_snapshot', () {
    test('rekam otomatis menyimpan naskah verbatim tanpa mengubah kini', () {
      var tick = DateTime(2026, 8, 26, 11);
      final store = DraftSnapshotStore(
        clock: () {
          tick = tick.add(const Duration(minutes: 15));
          return tick;
        },
      )..updateCurrent('d-1', 'Bab satu. Ia berjalan.');
      store.captureAuto('d-1');
      store.updateCurrent('d-1', 'Bab satu. Ia berlari.');
      final snaps = store.snapshotsOf('d-1');
      expect(snaps, hasLength(1));
      expect(snaps.single.kind, DraftSnapshotKind.auto);
      expect(snaps.single.content, 'Bab satu. Ia berjalan.');
      expect(store.currentOf('d-1'), 'Bab satu. Ia berlari.');
    });
  });

  group('manual_snapshot', () {
    test('rekam manual berlabel dan urut kronologis', () {
      var tick = DateTime(2026, 8, 26, 12);
      final store = DraftSnapshotStore(
        clock: () {
          tick = tick.add(const Duration(hours: 1));
          return tick;
        },
      )..updateCurrent('d-2', 'versi awal');
      store.captureManual(
        'd-2',
        label: 'sebelum rombak bab 1',
        content: 'versi awal',
      );
      store.captureManual(
        'd-2',
        label: 'setelah rombak bab 1',
        content: 'versi rombak',
      );
      final snaps = store.snapshotsOf('d-2');
      expect(snaps.map((s) => s.label), <String>[
        'sebelum rombak bab 1',
        'setelah rombak bab 1',
      ]);
      expect(snaps.first.at.isBefore(snaps.last.at), isTrue);
      expect(
        () => store.captureManual('d-2', label: '   ', content: 'x'),
        throwsArgumentError,
      );
    });
  });

  group('diff_view', () {
    test('perbandingan baris deterministik dengan hitung tambah/hapus', () {
      final store = DraftSnapshotStore()
        ..updateCurrent('d-3', 'baris satu\nbaris dua\nbaris tiga');
      store.captureManual('d-3', label: 'v1', content: 'baris satu\nbaris dua');
      store.updateCurrent(
        'd-3',
        'baris satu\nbaris dua revisi\nbaris tiga\nbaris empat',
      );
      final diff = store.diffWithCurrent('d-3', index: 0);
      expect(diff.removedLines, <String>['baris dua']);
      expect(diff.addedLines, containsAll(<String>['baris dua revisi']));
      expect(diff.unchangedCount, 1);
    });

    test(
      'duplikasi baris memakai semantik multiset (bug-hunt-run128 BUG-9)',
      () {
        final store = DraftSnapshotStore()..updateCurrent('d-3b', 'A\nA\nB');
        store.captureManual('d-3b', label: 'v1', content: 'A\nA\nB');
        store.updateCurrent('d-3b', 'A\nB\nB');

        final diff = store.diffWithCurrent('d-3b', index: 0);
        // Satu 'A' diganti satu 'B': multiset menghitung kejadian per baris,
        // bukan keanggotaan set — replacement tidak boleh dilaporkan zero diff.
        expect(diff.removedLines, <String>['A']);
        expect(diff.addedLines, <String>['B']);
        expect(diff.unchangedCount, 2);
      },
    );
  });

  group('restore_creates_backup', () {
    test('memulihkan selalu mencadangkan teks kini lebih dulu', () {
      final store = DraftSnapshotStore()
        ..updateCurrent('d-4', 'teks awal')
        ..captureManual('d-4', label: 'checkpoint', content: 'teks awal')
        ..updateCurrent('d-4', 'teks baru yang kacau');
      store.restoreTo('d-4', index: 0);
      expect(store.currentOf('d-4'), 'teks awal');
      final backup = store
          .snapshotsOf('d-4')
          .where((s) => s.kind == DraftSnapshotKind.restoreBackup);
      expect(backup, hasLength(1));
      expect(backup.single.content, 'teks baru yang kacau');
      // Snapshot asli tetap utuh dan bisa dipulihkan ulang.
      store.restoreTo('d-4', index: 0);
      expect(store.currentOf('d-4'), 'teks awal');
    });
  });

  group('retention_controls', () {
    test('batas retensi memangkas tertua; teks kini tak tersentuh', () {
      final store = DraftSnapshotStore()..setRetention('d-5', maxSnapshots: 2);
      store.updateCurrent('d-5', 'v1');
      store.captureAuto('d-5');
      store.updateCurrent('d-5', 'v2');
      store.captureAuto('d-5');
      store.updateCurrent('d-5', 'v3');
      store.captureAuto('d-5');
      final remaining = store.snapshotsOf('d-5').map((s) => s.content);
      expect(remaining, <String>['v2', 'v3']);
      expect(store.currentOf('d-5'), 'v3');
      expect(
        () => store.setRetention('d-5', maxSnapshots: 0),
        throwsArgumentError,
      );
    });
  });
}
