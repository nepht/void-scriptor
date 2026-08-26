// Kontrak Tension & Pacing Labels (Step 109.36) — RED pertama.
//
// Acceptance kanonik sprint_109.json: manual_scale, custom_labels,
// duration_signal, word_count_signal, arc_aggregation.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/pacing/domain/tension_labels.dart';

void main() {
  group('manual_scale', () {
    test('skala tensi manual 0-10 per adegan tervalidasi', () {
      final ledger = TensionLedger()..setManual(sceneId: 'sc-01', level: 7);
      expect(ledger.manualOf('sc-01'), 7);
      expect(
        () => ledger.setManual(sceneId: 'sc-02', level: 11),
        throwsArgumentError,
      );
      expect(
        () => ledger.setManual(sceneId: 'sc-03', level: -1),
        throwsArgumentError,
      );
      // Nilai bisa diperbarui (label manual, bukan kunci).
      ledger.setManual(sceneId: 'sc-01', level: 9);
      expect(ledger.manualOf('sc-01'), 9);
    });
  });

  group('custom_labels', () {
    test('label kustom per proyek dipakai pada adegan', () {
      final ledger = TensionLedger()
        ..defineLabel(code: 'diam', title: 'Jeda Sunyi')
        ..defineLabel(code: 'badai', title: 'Badai Emosi')
        ..labelScene(sceneId: 'sc-01', code: 'badai')
        ..labelScene(sceneId: 'sc-02', code: 'diam');
      expect(ledger.labelOf('sc-01')!.title, 'Badai Emosi');
      expect(ledger.labelOf('sc-02')!.code, 'diam');
      // Label tak terdaftar ditolak.
      expect(
        () => ledger.labelScene(sceneId: 'sc-03', code: 'hantu'),
        throwsStateError,
      );
      // Kode duplikat ditolak.
      expect(
        () => ledger.defineLabel(code: 'badai', title: 'Lagi'),
        throwsStateError,
      );
    });
  });

  group('duration_signal', () {
    test('sinyal pacing dari durasi adegan terklasifikasi', () {
      final ledger = TensionLedger();
      final fast = ledger.durationSignal(
        sceneDurationSeconds: 60,
        medianDurationSeconds: 180,
      );
      final slow = ledger.durationSignal(
        sceneDurationSeconds: 400,
        medianDurationSeconds: 180,
      );
      final normal = ledger.durationSignal(
        sceneDurationSeconds: 190,
        medianDurationSeconds: 180,
      );
      expect(fast, PacingSignal.fast);
      expect(slow, PacingSignal.slow);
      expect(normal, PacingSignal.normal);
    });
  });

  group('word_count_signal', () {
    test('sinyal pacing dari jumlah kata terklasifikasi', () {
      final ledger = TensionLedger();
      expect(
        ledger.wordCountSignal(wordCount: 300, medianWordCount: 1000),
        PacingSignal.fast,
      );
      expect(
        ledger.wordCountSignal(wordCount: 2200, medianWordCount: 1000),
        PacingSignal.slow,
      );
      expect(
        ledger.wordCountSignal(wordCount: 1050, medianWordCount: 1000),
        PacingSignal.normal,
      );
    });
  });

  group('arc_aggregation', () {
    test('agregasi arc merangkum puncak dan lembah tensi', () {
      final ledger = TensionLedger()
        ..setManual(sceneId: 'sc-01', level: 3)
        ..setManual(sceneId: 'sc-02', level: 8)
        ..setManual(sceneId: 'sc-03', level: 5)
        ..setManual(sceneId: 'sc-04', level: 2);
      final arc = ledger.aggregateArc(
        arcId: 'arc-utama',
        orderedSceneIds: const <String>['sc-01', 'sc-02', 'sc-03', 'sc-04'],
      );
      expect(arc.arcId, 'arc-utama');
      expect(arc.sceneCount, 4);
      expect(arc.peakLevel, 8);
      expect(arc.peakSceneId, 'sc-02');
      expect(arc.valleyLevel, 2);
      expect(arc.averageLevel, closeTo(4.5, 0.001));
      // Arc tanpa label apa pun tetap sah tapi kosong.
      final empty = ledger.aggregateArc(
        arcId: 'arc-kosong',
        orderedSceneIds: const <String>[],
      );
      expect(empty.isUnlabeled, isTrue);
    });
  });
}
