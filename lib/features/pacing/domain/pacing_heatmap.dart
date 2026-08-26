/// Kontrak Pacing Heatmap & Imbalance Warnings (Step 109.37).
///
/// Pola tensi per bab dan arc sebagai domain murni (tanpa DB/UI),
/// TANPA menilai kualitas secara absolut — petunjuk bersifat
/// deskriptif. Mengikat TensionLedger 109.36 milik slice sendiri.
/// Lima kemampuan kanonik sprint_109.json:
/// 1. **heatmap** — sel per adegan: level tensi dipetakan ke pita;
/// 2. **chapter_view** — pandangan bab berisi sel urut adegan;
/// 3. **arc_view** — pandangan arc lintas bab + bentuk ringkas;
/// 4. **long_plateau_hint** — deret datar memanjang menghasilkan
///    petunjuk deskriptif (bukan vonis kualitas);
/// 5. **custom_thresholds** — ambang pita bisa dikustom per proyek.
library;

import 'package:void_scriptor/features/pacing/domain/tension_labels.dart';

/// Pita tensi untuk render heatmap.
enum TensionBand { low, mid, high }

/// Jenis petunjuk ketimpangan.
enum HintKind { longPlateau }

/// Sel heatmap satu adegan.
class HeatmapCell {
  const HeatmapCell({
    required this.sceneId,
    required this.level,
    required this.band,
  });

  final String sceneId;
  final int level;
  final TensionBand band;
}

/// Pandangan satu bab.
class ChapterPacingView {
  ChapterPacingView({
    required this.chapterId,
    required List<HeatmapCell> rawCells,
  }) : cells = List.unmodifiable(rawCells);

  final String chapterId;

  /// Sel urut sesuai daftar adegan yang diminta.
  final List<HeatmapCell> cells;
}

/// Pandangan satu arc.
class ArcPacingView {
  ArcPacingView({
    required this.arcId,
    required List<HeatmapCell> rawCells,
    required this.peakLevel,
    required this.valleyLevel,
  }) : cells = List.unmodifiable(rawCells);

  final String arcId;

  /// Sel urut sesuai daftar adegan yang diminta.
  final List<HeatmapCell> cells;
  final int? peakLevel;
  final int? valleyLevel;

  /// Deretan pita sebagai bentuk ringkas arc.
  List<TensionBand> get shape => <TensionBand>[for (final c in cells) c.band];
}

/// Satu petunjuk ketimpangan; deskriptif, bukan penilaian mutlak.
class ImbalanceHint {
  const ImbalanceHint({
    required this.kind,
    required this.fromSceneId,
    required this.toSceneId,
    required this.explanation,
  });

  final HintKind kind;
  final String fromSceneId;
  final String toSceneId;

  /// Penjelasan dalam bahasa manusia; selalu menegaskan sifat
  /// deskriptifnya.
  final String explanation;
}

/// Analyzer heatmap pacing murni domain.
class PacingHeatmapAnalyzer {
  PacingHeatmapAnalyzer({
    required this.ledger,
    this.highThreshold = 7,
    this.lowThreshold = 4,
    this.plateauLimit = 4,
  });

  /// Sumber kebenaran label tensi (109.36).
  final TensionLedger ledger;

  /// Level >= [highThreshold] dianggap pita tinggi.
  final int highThreshold;

  /// Level <= [lowThreshold] dianggap pita rendah.
  final int lowThreshold;

  /// Banyaknya adegan berturut-turut setara sebelum dianggap dataran
  /// panjang.
  final int plateauLimit;

  /// Sel heatmap satu adegan; adegan tanpa label [StateError].
  HeatmapCell cellOf(String sceneId) {
    final level = ledger.manualOf(sceneId);
    if (level == null) {
      throw StateError('scene has no tension label: $sceneId');
    }
    return HeatmapCell(sceneId: sceneId, level: level, band: _bandOf(level));
  }

  TensionBand _bandOf(int level) {
    if (level >= highThreshold) return TensionBand.high;
    if (level <= lowThreshold) return TensionBand.low;
    return TensionBand.mid;
  }

  List<HeatmapCell> _cellsFor(List<String> orderedSceneIds) => <HeatmapCell>[
    for (final id in orderedSceneIds) cellOf(id),
  ];

  /// Pandangan bab: sel urut sesuai [orderedSceneIds].
  ChapterPacingView chapterView({
    required String chapterId,
    required List<String> orderedSceneIds,
  }) {
    return ChapterPacingView(
      chapterId: chapterId,
      rawCells: _cellsFor(orderedSceneIds),
    );
  }

  /// Pandangan arc: sel + puncak + lembah.
  ArcPacingView arcView({
    required String arcId,
    required List<String> orderedSceneIds,
  }) {
    final cells = _cellsFor(orderedSceneIds);
    if (cells.isEmpty) {
      return ArcPacingView(
        arcId: arcId,
        rawCells: cells,
        peakLevel: null,
        valleyLevel: null,
      );
    }
    var peak = cells.first.level;
    var valley = cells.first.level;
    for (final c in cells) {
      if (c.level > peak) peak = c.level;
      if (c.level < valley) valley = c.level;
    }
    return ArcPacingView(
      arcId: arcId,
      rawCells: cells,
      peakLevel: peak,
      valleyLevel: valley,
    );
  }

  /// Petunjuk dataran panjang: deret adegan berturut-turut dengan
  /// band sama dan level identik yang melewati [plateauLimit].
  ///
  /// Deskriptif semata: penulis menentukan sendiri artinya.
  List<ImbalanceHint> longPlateauHints({
    required List<String> orderedSceneIds,
  }) {
    final hints = <ImbalanceHint>[];
    var hasRun = false;
    var runStartId = '';
    var runEndId = '';
    var runLevel = -1;
    var runLength = 0;
    void flush() {
      if (hasRun && runLength >= plateauLimit) {
        hints.add(
          ImbalanceHint(
            kind: HintKind.longPlateau,
            fromSceneId: runStartId,
            toSceneId: runEndId,
            explanation:
                'adegan $runStartId..$runEndId bertahan di level '
                '$runLevel sebanyak $runLength adegan — pola datar '
                'panjang; ini catatan bentuk, bukan penilaian kualitas',
          ),
        );
      }
      hasRun = false;
      runStartId = '';
      runEndId = '';
      runLevel = -1;
      runLength = 0;
    }

    for (final sceneId in orderedSceneIds) {
      final cell = cellOf(sceneId);
      if (hasRun && runLevel == cell.level) {
        runEndId = sceneId;
        runLength += 1;
      } else {
        flush();
        hasRun = true;
        runStartId = sceneId;
        runEndId = sceneId;
        runLevel = cell.level;
        runLength = 1;
      }
    }
    flush();
    return hints;
  }
}
