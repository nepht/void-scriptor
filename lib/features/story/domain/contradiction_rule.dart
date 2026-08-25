/// Kontrak aturan kontradiksi cerita (Step 109.12).
///
/// Menyatukan rule continuity untuk enam dimensi kanonik — waktu, usia,
/// lokasi, status hidup, kepemilikan, dan fakta canon — sebagai lapisan
/// domain murni di atas sistem eksisting: `CanonRule`/`CanonConflict`
/// (bible) dan `SceneContinuityValidator` (story). Modul ini HANYA
/// mendefinisikan kontrak (rule_schema, severity_model, confidence_model,
/// explanation_contract); pipeline eksekusinya adalah langkah 109.13.
///
/// Dua sumbu penilaian sengaja dipisah: [ContradictionSeverity] menyatakan
/// seberapa keras sebuah pelanggaran, [DetectionConfidence] menyatakan
/// seberapa yakin deteksinya terhadap data yang ada. Data parsial boleh
/// melahirkan pelanggaran keras berkeyakinan rendah tanpa saling menimpa.
library;

/// Enam dimensi continuity yang dicakup kontrak ini.
enum ContradictionDimension {
  /// Urutan/kronologi waktu kejadian.
  time,

  /// Usia subjek pada titik waktu tertentu.
  age,

  /// Kehadiran/posisi lokasi subjek.
  location,

  /// Status hidup/mati subjek.
  lifeStatus,

  /// Kepemilikan objek oleh subjek.
  ownership,

  /// Fakta tetap yang dikunci canon.
  canonFact,
}

/// Komparator nilai yang dipahami [ContradictionRule].
enum ContradictionComparator {
  /// Nilai atribut harus sama dengan satu operand.
  equals,

  /// Nilai atribut harus berbeda dari satu operand.
  notEquals,

  /// Nilai waktu harus sebelum satu operand.
  before,

  /// Nilai waktu harus sesudah satu operand.
  after,

  /// Nilai harus berada dalam rentang dua operand `[min, max]`.
  withinRange,
}

/// Tingkat kekerasan pelanggaran kontradiksi.
enum ContradictionSeverity {
  /// Catatan informasi; tidak memblokir apa pun.
  info,

  /// Peringatan yang layak ditinjau; tidak memblokir publikasi.
  warning,

  /// Pelanggaran nyata yang memblokir publikasi sampai diselesaikan.
  violation;

  /// Hanya [violation] yang memblokir publikasi.
  bool get blocksPublication => this == violation;
}

/// Keyakinan deteksi terhadap data yang tersedia.
enum DetectionConfidence {
  /// Data parsial atau inferensia lemah.
  low,

  /// Bukti cukup namun belum mutlak.
  medium,

  /// Bukti langsung dan lengkap.
  high,
}

/// Satu aturan kontradiksi tingkat proyek.
class ContradictionRule {
  const ContradictionRule({
    required this.id,
    required this.projectId,
    required this.title,
    required this.dimension,
    required this.subjectKind,
    required this.attributeKey,
    required this.comparator,
    required this.expectedValues,
    this.enabled = true,
    this.description = '',
  });

  final String id;
  final String projectId;
  final String title;
  final ContradictionDimension dimension;

  /// Jenis subjek yang dinilai, misal `character`, `scene`, `item`.
  final String subjectKind;

  /// Kunci atribut subjek yang dibandingkan, misal `age`, `ownerAssetId`.
  final String attributeKey;
  final ContradictionComparator comparator;

  /// Operand komparator; jumlah sahnya ditentukan [comparator].
  final List<String> expectedValues;
  final bool enabled;
  final String description;

  /// Jumlah operand yang sah untuk [comparator].
  int get requiredOperandCount => switch (comparator) {
    ContradictionComparator.withinRange => 2,
    _ => 1,
  };

  /// Memvalidasi bentuk aturan; mengembalikan daftar masalah bernama
  /// (kosong berarti sah). Urutan pemeriksaan deterministik: title,
  /// projectId, attributeKey, lalu jumlah operand komparator.
  List<String> validateSchema() {
    final problems = <String>[];
    if (title.trim().isEmpty) problems.add('title must not be blank');
    if (projectId.trim().isEmpty) {
      problems.add('projectId must not be blank');
    }
    if (attributeKey.trim().isEmpty) {
      problems.add('attributeKey must not be blank');
    }
    if (expectedValues.length != requiredOperandCount) {
      problems.add(
        'comparator ${comparator.name} requires '
        '$requiredOperandCount operand(s), got ${expectedValues.length}',
      );
    }
    return problems;
  }
}

/// Rujukan sumber tempat sebuah temuan berasal.
class ContradictionSourceRef {
  const ContradictionSourceRef({required this.sourceId, required this.label});

  /// ID stabil sumber (scene id, bible entry id, beat id, dsb).
  final String sourceId;

  /// Label manusiawi untuk ditampilkan, misal `Bab 1 · Pembukaan`.
  final String label;
}

/// Penjelasan temuan: apa yang bertentangan, dari mana buktinya, dan
/// opsi saran perbaikan. Render-nya deterministik agar laporan identik
/// dibaca ulang kapan pun.
class ContradictionExplanation {
  const ContradictionExplanation({
    required this.summary,
    required this.expectedValue,
    required this.actualValue,
    this.sources = const <ContradictionSourceRef>[],
    this.suggestion = '',
  });

  final String summary;
  final String expectedValue;
  final String actualValue;

  /// Rujukan sumber dalam urutan penyajian yang stabil.
  final List<ContradictionSourceRef> sources;
  final String suggestion;

  /// Merender penjelasan menjadi teks multi-baris siap tampilkan.
  String render({required ContradictionDimension dimension}) {
    final lines = <String>[
      '[${dimension.name}] $summary',
      'Diharapkan: $expectedValue · temuan: $actualValue.',
      for (final source in sources) '• ${source.label} (${source.sourceId})',
      if (suggestion.trim().isNotEmpty) 'Saran: ${suggestion.trim()}',
    ];
    return lines.join('\n');
  }
}

/// Satu temuan kontradiksi hasil analisis (diisi pipeline 109.13).
class ContradictionFinding {
  const ContradictionFinding({
    required this.id,
    required this.ruleId,
    required this.subjectId,
    required this.dimension,
    required this.severity,
    required this.confidence,
    required this.explanation,
  });

  final String id;

  /// Aturan yang dilanggar ([ContradictionRule.id]).
  final String ruleId;

  /// Subjek yang melanggar (karakter, scene, item, dsb).
  final String subjectId;
  final ContradictionDimension dimension;
  final ContradictionSeverity severity;
  final DetectionConfidence confidence;
  final ContradictionExplanation explanation;
}
