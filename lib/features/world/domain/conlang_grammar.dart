/// Kontrak Conlang Grammar, Phonology & Script (Step 109.18).
///
/// Dokumentasi struktur sebuah bahasa buatan sebagai domain murni
/// (tanpa DB/UI), melengkapi registri kamus 109.17. Lima kemampuan
/// kanonik sprint_109.json:
/// 1. **grammar_rules** — aturan tata bahasa berurutan dan dapat direvisi;
/// 2. **phoneme_inventory** — inventaris bunyi terpilah konsonan/vokal,
///    simbol duplikat ditolak;
/// 3. **orthography_map** — peta grafem→fonem deterministik dan dapat
///    diperbarui;
/// 4. **script_notes** — catatan sistem tulisan yang dapat diedit
///    (nama, arah tulis, catatan);
/// 5. **version_history** — setiap mutasi mencatat revisi kronologis
///    memakai jam tersuntik, dan ikut terserialisasi.
library;

/// Kelas bunyi dalam inventaris fonem.
enum ConlangPhonemeKind {
  /// Konsonan.
  consonant,

  /// Vokal.
  vowel,
}

/// Arah penulisan sistem tulisan.
enum ConlangWritingDirection {
  /// Kiri ke kanan.
  leftToRight,

  /// Kanan ke kiri.
  rightToLeft,

  /// Atas ke bawah.
  topToBottom,
}

/// Satu aturan tata bahasa.
class ConlangGrammarRule {
  const ConlangGrammarRule({
    required this.id,
    required this.statement,
    required this.category,
  });

  final String id;

  /// Pernyataan aturan sebagaimana didokumentasikan.
  final String statement;

  /// Label bebas pengelompokan (word-order, case, dsb).
  final String category;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'statement': statement,
    'category': category,
  };

  static ConlangGrammarRule fromJson(Map<String, Object?> json) =>
      ConlangGrammarRule(
        id: json['id']! as String,
        statement: json['statement']! as String,
        category: json['category']! as String,
      );
}

/// Satu fonem dalam inventaris.
class ConlangPhoneme {
  const ConlangPhoneme({required this.symbol, required this.kind});

  final String symbol;
  final ConlangPhonemeKind kind;

  Map<String, Object?> toJson() => <String, Object?>{
    'symbol': symbol,
    'kind': kind.name,
  };

  static ConlangPhoneme fromJson(Map<String, Object?> json) => ConlangPhoneme(
    symbol: json['symbol']! as String,
    kind: ConlangPhonemeKind.values.firstWhere(
      (kind) => kind.name == json['kind'],
    ),
  );
}

/// Entri peta ortografi: bagaimana satu grafem dilafalkan.
class ConlangOrthographyEntry {
  const ConlangOrthographyEntry({
    required this.grapheme,
    required this.phoneme,
    this.note = '',
  });

  final String grapheme;
  final String phoneme;

  /// Catatan pelafalan opsional.
  final String note;

  Map<String, Object?> toJson() => <String, Object?>{
    'grapheme': grapheme,
    'phoneme': phoneme,
    'note': note,
  };

  static ConlangOrthographyEntry fromJson(Map<String, Object?> json) =>
      ConlangOrthographyEntry(
        grapheme: json['grapheme']! as String,
        phoneme: json['phoneme']! as String,
        note: json['note'] as String? ?? '',
      );
}

/// Catatan sistem tulisan bahasa terkait.
class ConlangScriptNotes {
  const ConlangScriptNotes({
    required this.name,
    required this.direction,
    this.notes = '',
  });

  final String name;

  /// Arah tulis; boleh belum ditetapkan.
  final ConlangWritingDirection? direction;
  final String notes;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'direction': direction?.name,
    'notes': notes,
  };
}

/// Satu entri riwayat revisi dokumen.
class ConlangGrammarRevision {
  const ConlangGrammarRevision({required this.at, required this.summary});

  final DateTime at;
  final String summary;
}

/// Dokumen tata bahasa satu bahasa buatan; urutan pendaftaran dirawat,
/// setiap mutasi mencatat revisi, serialisasi JSON deterministik.
class ConlangGrammarDoc {
  ConlangGrammarDoc({required this.languageId, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final String languageId;
  final DateTime Function() _clock;

  final Map<String, ConlangGrammarRule> _rules = <String, ConlangGrammarRule>{};
  final Map<String, ConlangPhoneme> _phonemes = <String, ConlangPhoneme>{};
  final Map<String, ConlangOrthographyEntry> _orthography =
      <String, ConlangOrthographyEntry>{};
  ConlangScriptNotes? _script;
  final List<ConlangGrammarRevision> _revisions = <ConlangGrammarRevision>[];

  /// Aturan dalam urutan pendaftaran/pembaruan pertama.
  List<ConlangGrammarRule> get rules => List.unmodifiable(_rules.values);

  /// Seluruh fonem dalam urutan pendaftaran.
  List<ConlangPhoneme> get allPhonemes => List.unmodifiable(_phonemes.values);

  /// Seluruh entri ortografi dalam urutan penetapan.
  List<ConlangOrthographyEntry> get orthography =>
      List.unmodifiable(_orthography.values);

  /// Catatan sistem tulis saat ini, bila sudah ada.
  ConlangScriptNotes? get script => _script;

  /// Riwayat revisi kronologis (jam tersuntik).
  List<ConlangGrammarRevision> get revisions => List.unmodifiable(_revisions);

  /// Menambah atau mengganti aturan; [ArgumentError] bila id/statement
  /// kosong.
  void upsertRule(ConlangGrammarRule rule) {
    if (rule.id.trim().isEmpty || rule.statement.trim().isEmpty) {
      throw ArgumentError('rule id and statement must not be blank');
    }
    _rules[rule.id] = rule;
    _record('rule: ${rule.id}');
  }

  /// Menambah fonem; [StateError] bila simbol sudah ada di inventaris.
  void addPhoneme({required String symbol, required ConlangPhonemeKind kind}) {
    if (_phonemes.containsKey(symbol)) {
      throw StateError('phoneme already inventoried: $symbol');
    }
    _phonemes[symbol] = ConlangPhoneme(symbol: symbol, kind: kind);
    _record('phoneme: $symbol');
  }

  /// Fonem terpilah menurut jenis; tanpa argumen berarti semua.
  List<ConlangPhoneme> phonemes({ConlangPhonemeKind? kind}) => <ConlangPhoneme>[
    for (final phoneme in _phonemes.values)
      if (kind == null || phoneme.kind == kind) phoneme,
  ];

  /// Menetapkan/memperbarui peta grafem→fonem; [ArgumentError] bila
  /// grafem atau fonem kosong.
  void setOrthography({
    required String grapheme,
    required String phoneme,
    String note = '',
  }) {
    if (grapheme.trim().isEmpty || phoneme.trim().isEmpty) {
      throw ArgumentError('grapheme and phoneme must not be blank');
    }
    _orthography[grapheme] = ConlangOrthographyEntry(
      grapheme: grapheme,
      phoneme: phoneme,
      note: note,
    );
    _record('orthography: $grapheme->$phoneme');
  }

  /// Fonem untuk sebuah grafem; null bila belum dipetakan.
  String? phonemeFor({required String grapheme}) =>
      _orthography[grapheme]?.phoneme;

  /// Mengganti keseluruhan catatan sistem tulis; [ArgumentError] bila
  /// nama kosong.
  void updateScript({
    required String scriptName,
    required ConlangWritingDirection? direction,
    String notes = '',
  }) {
    if (scriptName.trim().isEmpty) {
      throw ArgumentError('script name must not be blank');
    }
    _script = ConlangScriptNotes(
      name: scriptName,
      direction: direction,
      notes: notes,
    );
    _record('script: $scriptName');
  }

  void _record(String summary) {
    _revisions.add(ConlangGrammarRevision(at: _clock(), summary: summary));
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'languageId': languageId,
    'rules': <Object?>[for (final rule in _rules.values) rule.toJson()],
    'phonemes': <Object?>[
      for (final phoneme in _phonemes.values) phoneme.toJson(),
    ],
    'orthography': <Object?>[
      for (final entry in _orthography.values) entry.toJson(),
    ],
    'script': _script?.toJson(),
    'revisions': <Object?>[
      for (final revision in _revisions)
        <String, Object?>{
          'at': revision.at.toIso8601String(),
          'summary': revision.summary,
        },
    ],
  };

  /// Memulihkan dokumen apa adanya; tidak mencatat revisi baru.
  static ConlangGrammarDoc fromJson(Map<String, Object?> json) {
    final doc = ConlangGrammarDoc(languageId: json['languageId']! as String);
    final rules = json['rules'];
    if (rules is List<Object?>) {
      for (final raw in rules.whereType<Map<Object?, Object?>>()) {
        final rule = ConlangGrammarRule.fromJson(
          raw.map((k, v) => MapEntry(k.toString(), v)),
        );
        doc._rules[rule.id] = rule;
      }
    }
    final phonemes = json['phonemes'];
    if (phonemes is List<Object?>) {
      for (final raw in phonemes.whereType<Map<Object?, Object?>>()) {
        final phoneme = ConlangPhoneme.fromJson(
          raw.map((k, v) => MapEntry(k.toString(), v)),
        );
        doc._phonemes[phoneme.symbol] = phoneme;
      }
    }
    final orthography = json['orthography'];
    if (orthography is List<Object?>) {
      for (final raw in orthography.whereType<Map<Object?, Object?>>()) {
        final entry = ConlangOrthographyEntry.fromJson(
          raw.map((k, v) => MapEntry(k.toString(), v)),
        );
        doc._orthography[entry.grapheme] = entry;
      }
    }
    final scriptRaw = json['script'];
    if (scriptRaw is Map<Object?, Object?>) {
      final scriptJson = scriptRaw.map((k, v) => MapEntry(k.toString(), v));
      final directionName = scriptJson['direction'] as String?;
      doc._script = ConlangScriptNotes(
        name: scriptJson['name']! as String,
        direction: directionName == null
            ? null
            : ConlangWritingDirection.values.firstWhere(
                (direction) => direction.name == directionName,
              ),
        notes: scriptJson['notes'] as String? ?? '',
      );
    }
    final revisions = json['revisions'];
    if (revisions is List<Object?>) {
      for (final raw in revisions.whereType<Map<Object?, Object?>>()) {
        final revisionJson = raw.map((k, v) => MapEntry(k.toString(), v));
        doc._revisions.add(
          ConlangGrammarRevision(
            at: DateTime.parse(revisionJson['at']! as String),
            summary: revisionJson['summary']! as String,
          ),
        );
      }
    }
    return doc;
  }
}
