/// Kontrak Conlang Registry & Dictionary (Step 109.17).
///
/// Registri bahasa buatan dan kamusnya sebagai domain murni (tanpa DB/UI).
/// Lima kemampuan kanonik sprint_109.json:
/// 1. **multiple_languages** — banyak bahasa dalam satu registri;
/// 2. **dictionary_search** — pencarian case-insensitive atas istilah,
///    arti, dan bentuk varian, dapat dibatasi per bahasa;
/// 3. **variant_forms** — bentuk varian tersimpan di kata induknya dan
///    ikut terindeks pencarian;
/// 4. **usage_examples** — contoh penggunaan + terjemahan berurutan;
/// 5. **import_export** — roundtrip JSON deterministik identik antar-rebuild.
library;

/// Kelas kata yang dikenali kamus.
enum ConlangPartOfSpeech {
  /// Nomina.
  noun,

  /// Verba.
  verb,

  /// Pronomina.
  pronoun,

  /// Adjektiva.
  adjective,

  /// Adverbia.
  adverb,

  /// Partikel/fungsi gramatikal.
  particle,
}

/// Satu bahasa buatan terdaftar.
class ConlangLanguage {
  const ConlangLanguage({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, Object?> toJson() => <String, Object?>{'id': id, 'name': name};

  static ConlangLanguage fromJson(Map<String, Object?> json) =>
      ConlangLanguage(id: json['id']! as String, name: json['name']! as String);
}

/// Bentuk varian dari sebuah kata (jamak, honorifik, infleksi, dsb).
class ConlangVariantForm {
  const ConlangVariantForm({
    required this.id,
    required this.form,
    this.gloss = '',
  });

  final String id;

  /// Bentuk permukaan sebagaimana ditulis.
  final String form;

  /// Penjelasan singkat fungsi bentuk ini.
  final String gloss;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'form': form,
    'gloss': gloss,
  };

  static ConlangVariantForm fromJson(Map<String, Object?> json) =>
      ConlangVariantForm(
        id: json['id']! as String,
        form: json['form']! as String,
        gloss: json['gloss'] as String? ?? '',
      );
}

/// Contoh penggunaan kata beserta terjemahannya.
class ConlangUsageExample {
  const ConlangUsageExample({required this.text, this.translation = ''});

  final String text;
  final String translation;

  Map<String, Object?> toJson() => <String, Object?>{
    'text': text,
    'translation': translation,
  };

  static ConlangUsageExample fromJson(Map<String, Object?> json) =>
      ConlangUsageExample(
        text: json['text']! as String,
        translation: json['translation'] as String? ?? '',
      );
}

/// Satu entri kamus: istilah, arti, kelas kata, varian, contoh.
class ConlangWord {
  const ConlangWord({
    required this.id,
    required this.languageId,
    required this.term,
    required this.meaning,
    required this.partOfSpeech,
    this.variants = const <ConlangVariantForm>[],
    this.examples = const <ConlangUsageExample>[],
  });

  final String id;
  final String languageId;
  final String term;
  final String meaning;
  final ConlangPartOfSpeech partOfSpeech;
  final List<ConlangVariantForm> variants;
  final List<ConlangUsageExample> examples;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'languageId': languageId,
    'term': term,
    'meaning': meaning,
    'partOfSpeech': partOfSpeech.name,
    'variants': <Object?>[for (final v in variants) v.toJson()],
    'examples': <Object?>[for (final e in examples) e.toJson()],
  };

  static ConlangWord fromJson(Map<String, Object?> json) => ConlangWord(
    id: json['id']! as String,
    languageId: json['languageId']! as String,
    term: json['term']! as String,
    meaning: json['meaning']! as String,
    partOfSpeech: ConlangPartOfSpeech.values.firstWhere(
      (pos) => pos.name == json['partOfSpeech'],
    ),
    variants: <ConlangVariantForm>[
      for (final raw
          in (json['variants'] as List<Object?>? ?? <Object?>[])
              .whereType<Map<Object?, Object?>>())
        ConlangVariantForm.fromJson(
          raw.map((k, v) => MapEntry(k.toString(), v)),
        ),
    ],
    examples: <ConlangUsageExample>[
      for (final raw
          in (json['examples'] as List<Object?>? ?? <Object?>[])
              .whereType<Map<Object?, Object?>>())
        ConlangUsageExample.fromJson(
          raw.map((k, v) => MapEntry(k.toString(), v)),
        ),
    ],
  );

  /// Salinan kata dengan daftar varian baru.
  ConlangWord withVariants(List<ConlangVariantForm> next) => ConlangWord(
    id: id,
    languageId: languageId,
    term: term,
    meaning: meaning,
    partOfSpeech: partOfSpeech,
    variants: next,
    examples: examples,
  );

  /// Salinan kata dengan daftar contoh baru.
  ConlangWord withExamples(List<ConlangUsageExample> next) => ConlangWord(
    id: id,
    languageId: languageId,
    term: term,
    meaning: meaning,
    partOfSpeech: partOfSpeech,
    variants: variants,
    examples: next,
  );
}

/// Registri bahasa buatan + kamusnya; urutan pendaftaran dirawat dan
/// serialisasi JSON-nya deterministik.
class ConlangRegistry {
  final Map<String, ConlangLanguage> _languages = <String, ConlangLanguage>{};
  final Map<String, ConlangWord> _words = <String, ConlangWord>{};

  /// Semua bahasa dalam urutan pendaftaran pertama.
  List<ConlangLanguage> get languages => List.unmodifiable(_languages.values);

  /// Menambah atau mengganti bahasa berdasarkan ID.
  void upsertLanguage(ConlangLanguage language) =>
      _languages[language.id] = language;

  /// Menambah atau mengganti kata; [ArgumentError] bila bahasa target
  /// belum terdaftar (kata yatim tidak boleh masuk kamus).
  void upsertWord(ConlangWord word) {
    if (!_languages.containsKey(word.languageId)) {
      throw ArgumentError.value(
        word.languageId,
        'languageId',
        'word references an unregistered language',
      );
    }
    _words[word.id] = word;
  }

  /// Kata-kata kamus, opsional terfilter per bahasa.
  List<ConlangWord> words({String? languageId}) => <ConlangWord>[
    for (final word in _words.values)
      if (languageId == null || word.languageId == languageId) word,
  ];

  /// Mengambil satu kata; [StateError] bila ID tak dikenal.
  ConlangWord wordById(String id) => _words[id]!;

  /// Pencarian kamus case-insensitive atas istilah, arti, dan bentuk
  /// varian; [term] kosong/null berarti tanpa filter teks.
  List<ConlangWord> search({String? languageId, String? term}) {
    final needle = term?.toLowerCase();
    return <ConlangWord>[
      for (final word in _words.values)
        if ((languageId == null || word.languageId == languageId) &&
            (needle == null || _matches(word, needle)))
          word,
    ];
  }

  bool _matches(ConlangWord word, String needle) =>
      word.term.toLowerCase().contains(needle) ||
      word.meaning.toLowerCase().contains(needle) ||
      word.variants.any(
        (variant) => variant.form.toLowerCase().contains(needle),
      );

  /// Menambah bentuk varian pada kata induknya; [StateError] bila kata
  /// tak dikenal.
  void addVariant({
    required String wordId,
    required ConlangVariantForm variant,
  }) {
    final word = wordById(wordId);
    _words[wordId] = word.withVariants(<ConlangVariantForm>[
      ...word.variants,
      variant,
    ]);
  }

  /// Menambah contoh penggunaan pada kata; [StateError] bila kata
  /// tak dikenal.
  void addExample({
    required String wordId,
    required ConlangUsageExample example,
  }) {
    final word = wordById(wordId);
    _words[wordId] = word.withExamples(<ConlangUsageExample>[
      ...word.examples,
      example,
    ]);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'languages': <Object?>[for (final l in _languages.values) l.toJson()],
    'words': <Object?>[for (final w in _words.values) w.toJson()],
  };

  static ConlangRegistry fromJson(Map<String, Object?> json) {
    final registry = ConlangRegistry();
    final languages = json['languages'];
    if (languages is List<Object?>) {
      for (final raw in languages.whereType<Map<Object?, Object?>>()) {
        registry.upsertLanguage(
          ConlangLanguage.fromJson(
            raw.map((k, v) => MapEntry(k.toString(), v)),
          ),
        );
      }
    }
    final words = json['words'];
    if (words is List<Object?>) {
      for (final raw in words.whereType<Map<Object?, Object?>>()) {
        registry.upsertWord(
          ConlangWord.fromJson(raw.map((k, v) => MapEntry(k.toString(), v))),
        );
      }
    }
    return registry;
  }
}
