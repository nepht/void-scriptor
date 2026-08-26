/// Kontrak Tension & Pacing Labels (Step 109.36).
///
/// Label tensi manual dan sinyal pacing per adegan sebagai domain
/// murni (tanpa DB/UI). Lima kemampuan kanonik sprint_109.json:
/// 1. **manual_scale** — skala tensi manual 0-10 per adegan;
/// 2. **custom_labels** — label kustom per proyek untuk adegan;
/// 3. **duration_signal** — sinyal pacing dari durasi adegan vs
///    median;
/// 4. **word_count_signal** — sinyal pacing dari jumlah kata vs
///    median;
/// 5. **arc_aggregation** — agregasi tensi per arc: puncak, lembah,
///    rata-rata.
library;

/// Sinyal pacing hasil klasifikasi.
enum PacingSignal { fast, normal, slow }

/// Label kustom proyek.
class CustomLabel {
  const CustomLabel({required this.code, required this.title});

  /// Kode unik pendek.
  final String code;

  /// Judul tampil penulis.
  final String title;
}

/// Hasil agregasi tensi satu arc.
class ArcAggregate {
  const ArcAggregate({
    required this.arcId,
    required this.sceneCount,
    this.peakSceneId,
    this.peakLevel,
    this.valleyLevel,
    required this.averageLevel,
  });

  final String arcId;
  final int sceneCount;

  /// Adegan dengan tensi tertinggi.
  final String? peakSceneId;
  final int? peakLevel;

  /// Tensi terendah dalam arc.
  final int? valleyLevel;
  final double averageLevel;

  /// True bila tidak ada adegan berlabel di arc ini.
  bool get isUnlabeled => sceneCount == 0 || peakLevel == null;
}

/// Ledger tensi dan pacing; murni domain.
class TensionLedger {
  static const int _minLevel = 0;
  static const int _maxLevel = 10;

  /// Ambang relatif sinyal cepat/lambat terhadap median.
  static const double _fastRatio = 0.75;
  static const double _slowRatio = 1.5;

  final Map<String, int> _manual = <String, int>{};
  final Map<String, CustomLabel> _labels = <String, CustomLabel>{};
  final Map<String, String> _sceneLabelCodes = <String, String>{};

  void _requireLevel(int level) {
    if (level < _minLevel || level > _maxLevel) {
      throw ArgumentError(
        'tension level must be within $_minLevel..$_maxLevel',
      );
    }
  }

  /// Menetapkan tensi manual [level] pada satu adegan; label manual
  /// boleh diperbarui kapan pun.
  void setManual({required String sceneId, required int level}) {
    _requireLevel(level);
    _manual[sceneId] = level;
  }

  /// Tensi manual adegan; null bila belum diberi label.
  int? manualOf(String sceneId) => _manual[sceneId];

  /// Mendefinisikan label kustom proyek; kode duplikat [StateError].
  void defineLabel({required String code, required String title}) {
    if (_labels.containsKey(code)) {
      throw StateError('label code already defined: $code');
    }
    _labels[code] = CustomLabel(code: code, title: title);
  }

  /// Memasang label terdaftar pada adegan; kode tak dikenal
  /// [StateError].
  void labelScene({required String sceneId, required String code}) {
    if (!_labels.containsKey(code)) {
      throw StateError('unknown label code: $code');
    }
    _sceneLabelCodes[sceneId] = code;
  }

  /// Label adegan; null bila belum dipasangi label.
  CustomLabel? labelOf(String sceneId) {
    final code = _sceneLabelCodes[sceneId];
    return code == null ? null : _labels[code];
  }

  PacingSignal _classify(num value, num median) {
    if (median <= 0) return PacingSignal.normal;
    final ratio = value / median;
    if (ratio <= _fastRatio) return PacingSignal.fast;
    if (ratio >= _slowRatio) return PacingSignal.slow;
    return PacingSignal.normal;
  }

  /// Sinyal pacing dari durasi adegan dibanding median durasi.
  PacingSignal durationSignal({
    required num sceneDurationSeconds,
    required num medianDurationSeconds,
  }) {
    return _classify(sceneDurationSeconds, medianDurationSeconds);
  }

  /// Sinyal pacing dari jumlah kata dibanding median jumlah kata.
  PacingSignal wordCountSignal({
    required int wordCount,
    required int medianWordCount,
  }) {
    return _classify(wordCount, medianWordCount);
  }

  /// Mengagregasi tensi manual sepanjang arc berurutan adegannya.
  ArcAggregate aggregateArc({
    required String arcId,
    required List<String> orderedSceneIds,
  }) {
    final levels = <(String, int)>[
      for (final sceneId in orderedSceneIds)
        if (_manual[sceneId] != null) (sceneId, _manual[sceneId]!),
    ];
    if (levels.isEmpty) {
      return ArcAggregate(arcId: arcId, sceneCount: 0, averageLevel: 0);
    }
    var peak = levels.first;
    var valley = levels.first;
    var total = 0;
    for (final entry in levels) {
      if (entry.$2 > peak.$2) peak = entry;
      if (entry.$2 < valley.$2) valley = entry;
      total += entry.$2;
    }
    return ArcAggregate(
      arcId: arcId,
      sceneCount: levels.length,
      peakSceneId: peak.$1,
      peakLevel: peak.$2,
      valleyLevel: valley.$2,
      averageLevel: total / levels.length,
    );
  }
}
