// Kontrak Pacing Heatmap & Imbalance Warnings (Step 109.37) — RED
// pertama.
//
// Acceptance kanonik sprint_109.json: heatmap, chapter_view, arc_view,
// long_plateau_hint, custom_thresholds.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/pacing/domain/tension_labels.dart';
import 'package:void_scriptor/features/pacing/domain/pacing_heatmap.dart';

TensionLedger _ledger() {
  final ledger = TensionLedger();
  // Bab 1: naik-turun sehat (3 -> 8 -> 5).
  ledger
    ..setManual(sceneId: 'sc-01', level: 3)
    ..setManual(sceneId: 'sc-02', level: 8)
    ..setManual(sceneId: 'sc-03', level: 5);
  // Bab 2: dataran panjang di level rendah (4 empat kali berturut).
  ledger
    ..setManual(sceneId: 'sc-04', level: 4)
    ..setManual(sceneId: 'sc-05', level: 4)
    ..setManual(sceneId: 'sc-06', level: 4)
    ..setManual(sceneId: 'sc-07', level: 4);
  return ledger;
}

void main() {
  group('heatmap', () {
    test('sel heatmap memetakan level ke pita warna kanonis', () {
      final analyzer = PacingHeatmapAnalyzer(ledger: _ledger());
      final cell = analyzer.cellOf('sc-02');
      expect(cell.sceneId, 'sc-02');
      expect(cell.level, 8);
      expect(cell.band, TensionBand.high);
      expect(analyzer.cellOf('sc-01').band, TensionBand.low);
      expect(analyzer.cellOf('sc-03').band, TensionBand.mid);
    });
  });

  group('chapter_view', () {
    test('pandangan bab mengurutkan sel sesuai adegan yang diberi', () {
      final analyzer = PacingHeatmapAnalyzer(ledger: _ledger());
      final view = analyzer.chapterView(
        chapterId: 'ch-02',
        orderedSceneIds: const <String>['sc-07', 'sc-05', 'sc-06'],
      );
      expect(view.chapterId, 'ch-02');
      expect(view.cells.map((c) => c.sceneId).toList(), <String>[
        'sc-07',
        'sc-05',
        'sc-06',
      ]);
      expect(view.cells.every((c) => c.level == 4), isTrue);
    });
  });

  group('arc_view', () {
    test('pandangan arc merangkum bentuk tensi lintas bab', () {
      final analyzer = PacingHeatmapAnalyzer(ledger: _ledger());
      final view = analyzer.arcView(
        arcId: 'arc-utama',
        orderedSceneIds: const <String>['sc-01', 'sc-02', 'sc-03', 'sc-04'],
      );
      expect(view.arcId, 'arc-utama');
      expect(view.cells, hasLength(4));
      expect(view.peakLevel, 8);
      expect(view.valleyLevel, 3);
      // Bentuk arc tersedia untuk render ringkas.
      expect(view.shape, contains(TensionBand.mid));
    });
  });

  group('long_plateau_hint', () {
    test('dataran panjang menghasilkan petunjuk bukan vonis', () {
      final analyzer = PacingHeatmapAnalyzer(
        ledger: _ledger(),
        plateauLimit: 3,
      );
      final hints = analyzer.longPlateauHints(
        orderedSceneIds: const <String>[
          'sc-01',
          'sc-02',
          'sc-03',
          'sc-04',
          'sc-05',
          'sc-06',
          'sc-07',
        ],
      );
      expect(hints, hasLength(1));
      expect(hints.single.kind, HintKind.longPlateau);
      expect(hints.single.fromSceneId, 'sc-04');
      expect(hints.single.toSceneId, 'sc-07');
      expect(hints.single.explanation, contains('bukan penilaian'));

      // Deret pendek tanpa dataran tidak menghasilkan apa pun.
      final calm = analyzer.longPlateauHints(
        orderedSceneIds: const <String>['sc-01', 'sc-02'],
      );
      expect(calm, isEmpty);
    });
  });

  group('custom_thresholds', () {
    test('ambang pita bisa dikustom per proyek', () {
      final ledger = _ledger();
      final strict = PacingHeatmapAnalyzer(
        ledger: ledger,
        highThreshold: 7,
        lowThreshold: 5,
      );
      expect(strict.cellOf('sc-02').band, TensionBand.high);
      // Level 5 kini masuk pita rendah menurut ambang ketat ini.
      expect(strict.cellOf('sc-03').band, TensionBand.low);

      final loose = PacingHeatmapAnalyzer(
        ledger: ledger,
        highThreshold: 9,
        lowThreshold: 2,
      );
      expect(loose.cellOf('sc-02').band, TensionBand.mid);
      expect(loose.cellOf('sc-01').band, TensionBand.mid);
    });
  });
}
