/// Kontrak Voice Profile & Dialogue Consistency (Step 109.16).
///
/// Lapisan aturan suara yang dapat diedit di atas profil deskriptif yang
/// sudah ada (`VoiceProfiles`: tekstur vokal & catatan penyampaian), untuk
/// menilai konsistensi dialog per karakter. Lima kemampuan kanonik
/// sprint_109.json:
/// 1. **editable_voice_rules** — aturan diksi/nada/tabu/pola bicara bisa
///    ditambah, diubah, dihapus, dan diaktifkan/nonaktifkan;
/// 2. **dialogue_comparison** — penilaian baris/batch dialog terhadap
///    aturan aktif karakter terkait;
/// 3. **explain_warning** — setiap peringatan punya render penjelasan
///    deterministik (aturan + istilah + saran);
/// 4. **disable_rule** — aturan nonaktif dilewati sampai diaktifkan lagi;
/// 5. **no_auto_rewrite** — teks naskah TIDAK pernah ditulis ulang otomatis;
///    hasil analisis hanya peringatan plus teks asli verbatim.
///
/// Modul ini domain murni: tanpa Drift dan tanpa UI. Pencocokan memakai
/// penahanan substring peka-huruf-besar sederhana (bukan batas kata penuh);
/// batasan itu disengaja untuk lapisan pertama dan terdokumentasi di sini.
library;

/// Jenis aturan suara karakter.
enum DialogueVoiceRuleKind {
  /// Pilihan diksi (kosakata khas).
  diction,

  /// Nada penyampaian (formal, sarkastik, dsb).
  tone,

  /// Istilah yang harus dihindari karakter.
  taboo,

  /// Pola bicara kontekstual (misal sapaan jabatan saat bertempur).
  speechPattern,
}

/// Arah aturan: menghindari atau mewajibkan istilah.
enum DialogueVoiceRuleMode {
  /// [DialogueVoiceRule.terms] tidak boleh muncul dalam dialog.
  avoid,

  /// [DialogueVoiceRule.terms] wajib muncul ketika penanda konteks ada.
  require,
}

/// Satu aturan suara yang dapat diedit milik satu karakter.
class DialogueVoiceRule {
  const DialogueVoiceRule({
    required this.id,
    required this.characterId,
    required this.kind,
    required this.mode,
    required this.terms,
    this.contextMarkers = const <String>[],
    this.explanation = '',
    this.enabled = true,
  });

  final String id;

  /// Karakter pemilik aturan.
  final String characterId;
  final DialogueVoiceRuleKind kind;
  final DialogueVoiceRuleMode mode;

  /// Istilah inti aturan (terlarang utk [DialogueVoiceRuleMode.avoid],
  /// wajib utk [DialogueVoiceRuleMode.require]).
  final List<String> terms;

  /// Penanda konteks untuk mode require; kosong berarti selalu berlaku.
  final List<String> contextMarkers;

  /// Penjelasan manusiawi yang tampil pada peringatan.
  final String explanation;
  final bool enabled;

  /// Memvalidasi bentuk aturan; daftar masalah bernama, kosong berarti
  /// sah. Urutan pemeriksaan deterministik: id, characterId, terms.
  List<String> validateSchema() {
    final problems = <String>[];
    if (id.trim().isEmpty) problems.add('id must not be blank');
    if (characterId.trim().isEmpty) {
      problems.add('characterId must not be blank');
    }
    if (terms.isEmpty) problems.add('terms must not be empty');
    return problems;
  }

  /// Salinan aturan dengan status aktif baru.
  DialogueVoiceRule withEnabled(bool value) => DialogueVoiceRule(
    id: id,
    characterId: characterId,
    kind: kind,
    mode: mode,
    terms: terms,
    contextMarkers: contextMarkers,
    explanation: explanation,
    enabled: value,
  );
}

/// Kumpulan aturan suara yang dapat diedit untuk satu karakter.
class DialogueVoiceProfile {
  DialogueVoiceProfile({required this.characterId});

  final String characterId;
  final Map<String, DialogueVoiceRule> _rules = <String, DialogueVoiceRule>{};

  /// Aturan dalam urutan pendaftaran/pembaruan pertama.
  List<DialogueVoiceRule> get rules => List.unmodifiable(_rules.values);

  /// Menambah atau mengganti aturan berdasarkan ID.
  void upsert(DialogueVoiceRule rule) => _rules[rule.id] = rule;

  /// Menghapus aturan; diam bila ID tak dikenal.
  void remove(String ruleId) => _rules.remove(ruleId);

  /// Membalik status aktif aturan. [ArgumentError] bila ID tak dikenal.
  void toggleEnabled(String ruleId) {
    final rule = _rules[ruleId];
    if (rule == null) {
      throw ArgumentError.value(ruleId, 'ruleId', 'unknown rule');
    }
    _rules[ruleId] = rule.withEnabled(!rule.enabled);
  }
}

/// Satu peringatan konsistensi suara atas satu baris dialog.
class VoiceConsistencyWarning {
  const VoiceConsistencyWarning({
    required this.ruleId,
    required this.kind,
    this.matchedTerms = const <String>[],
    this.missingTerms = const <String>[],
    required this.explanation,
  });

  final String ruleId;
  final DialogueVoiceRuleKind kind;

  /// Istilah terlarang yang ditemukan (mode avoid).
  final List<String> matchedTerms;

  /// Istilah terlarang pertama yang cocok.
  String get matchedTerm => matchedTerms.first;

  /// Istilah wajib yang absen meski konteks cocok (mode require).
  final List<String> missingTerms;
  final String explanation;

  /// Render penjelasan deterministik; dua analisis atas input sama
  /// selalu menghasilkan teks identik.
  String render() {
    final detail = matchedTerms.isNotEmpty
        ? 'Istilah terlarang ditemukan: '
              '${[for (final term in matchedTerms) '"$term"'].join(', ')}.'
        : 'Istilah wajib tidak ditemukan: '
              '${[for (final term in missingTerms) '"$term"'].join(', ')}.';
    return <String>[
      '[${kind.name}] $explanation',
      detail,
      'Saran: tinjau ulang kalimat ini secara manual.',
    ].join('\n');
  }
}

/// Hasil analisis satu baris dialog.
class LineVoiceCheckResult {
  const LineVoiceCheckResult({
    required this.originalText,
    required this.warnings,
  });

  /// Teks naskah apa adanya — tidak pernah diubah (no_auto_rewrite).
  final String originalText;
  final List<VoiceConsistencyWarning> warnings;

  bool get clean => warnings.isEmpty;

  /// Selalu null: modul ini sengaja tidak menawarkan tulisan-ulang otomatis.
  String? get suggestedRewrite => null;
}

/// Analisis konsistensi dialog terhadap aturan suara karakter.
class DialogueVoiceConsistencyAnalyzer {
  static bool _contains(String haystackLower, String needle) =>
      haystackLower.contains(needle.toLowerCase());

  /// Menilai satu baris dialog dengan aturan aktif milik [characterId].
  /// Aturan nonaktif dilewati; aturan karakter lain dilewati.
  LineVoiceCheckResult checkLine({
    required List<DialogueVoiceRule> rules,
    required String characterId,
    required String text,
  }) {
    final textLower = text.toLowerCase();
    final warnings = <VoiceConsistencyWarning>[];
    for (final rule in rules) {
      if (!rule.enabled || rule.characterId != characterId) continue;
      switch (rule.mode) {
        case DialogueVoiceRuleMode.avoid:
          final hits = <String>[
            for (final term in rule.terms)
              if (_contains(textLower, term)) term,
          ];
          if (hits.isNotEmpty) {
            warnings.add(
              VoiceConsistencyWarning(
                ruleId: rule.id,
                kind: rule.kind,
                matchedTerms: hits,
                explanation: rule.explanation,
              ),
            );
          }
        case DialogueVoiceRuleMode.require:
          final inContext =
              rule.contextMarkers.isEmpty ||
              rule.contextMarkers.any((marker) => _contains(textLower, marker));
          if (!inContext) break;
          final missing = <String>[
            for (final term in rule.terms)
              if (!_contains(textLower, term)) term,
          ];
          if (missing.isNotEmpty) {
            warnings.add(
              VoiceConsistencyWarning(
                ruleId: rule.id,
                kind: rule.kind,
                missingTerms: missing,
                explanation: rule.explanation,
              ),
            );
          }
      }
    }
    return LineVoiceCheckResult(originalText: text, warnings: warnings);
  }

  /// Menilai banyak baris sekaligus, menjaga urutan dan teks aslinya.
  List<LineVoiceCheckResult> checkAll({
    required List<DialogueVoiceRule> rules,
    required String characterId,
    required List<String> texts,
  }) => <LineVoiceCheckResult>[
    for (final text in texts)
      checkLine(rules: rules, characterId: characterId, text: text),
  ];
}
