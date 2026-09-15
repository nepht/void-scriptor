// Sprint 111.33 - Idiom, Proverb & Saying Registry (domain-only).
//
// Menyimpan ungkapan budaya: teks asli, terjemahan literal, arti, jenis,
// varian, dan tautan bahasa. Mirror pola domain sprint 111.24/111.29:
// konstruktor tervalidasi, koleksi immutable, deterministik.
//
// Enam acceptance canonical sprint_111.json dipetakan:
// - original_text      -> IdiomRecord.originalText trim non-kosong +
//                         normalizedText (lowercase, whitespace dikolaps)
// - literal_translation-> wajib pada record, opsional per varian
// - meaning            -> wajib, terpisah dari terjemahan literal
// - type               -> IdiomType berlabel (idiom..other)
// - variants           -> IdiomVariant: id unik global, teks unik ternormalisasi,
//                         tidak boleh meniru teks kanon
// - language_links     -> IdiomLanguageLink (pola PhonotacticsConlangLink
//                         111.29): target non-kosong, max satu `original`,
//                         pasangan target+kind unik
//
// Tanpa persistence, UI, locale, jaringan, wall-clock, atau dart:math Random.
// D-SCHEMA-01 tetap OPEN; modul ini mirror domain untuk Drift mendatang.

library;

/// Keluarga ungkapan yang bisa dicatat di registri.
enum IdiomType {
  idiom('Idiom'),
  proverb('Proverb'),
  saying('Saying'),
  maxim('Maxim'),
  catchphrase('Catchphrase'),
  other('Other');

  const IdiomType(this.label);

  final String label;
}

/// Peran hubungan sebuah ungkapan dengan bahasa lain.
enum IdiomLinkKind {
  /// Bahasa asal ungkapan.
  original('Original'),

  /// Kekerabatan/kognat antar bahasa.
  cognate('Cognate'),

  /// Ungkapan dipinjam dari bahasa target.
  borrowed('Borrowed'),

  /// Catatan perbandingan/referensi.
  reference('Reference');

  const IdiomLinkKind(this.label);

  final String label;
}

String _requireTrimmed(String value, String fieldName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return trimmed;
}

/// Normalisasi perbandingan teks: trim, lowercase, whitespace dikolaps.
String normalizeIdiomText(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Satu varian teks dari ungkapan kanon.
class IdiomVariant {
  IdiomVariant._({
    required this.variantId,
    required this.text,
    required this.normalizedText,
    this.literalTranslation,
    required this.note,
  });

  /// Membuat varian; [variantId] dan [text] wajib non-kosong.
  /// [literalTranslation] opsional per varian.
  factory IdiomVariant.validated({
    required String variantId,
    required String text,
    String? literalTranslation,
    String note = '',
  }) {
    final trimmedLiteral = literalTranslation?.trim();
    return IdiomVariant._(
      variantId: _requireTrimmed(variantId, 'variantId'),
      text: _requireTrimmed(text, 'text'),
      normalizedText: normalizeIdiomText(text),
      literalTranslation: (trimmedLiteral == null || trimmedLiteral.isEmpty)
          ? null
          : trimmedLiteral,
      note: note.trim(),
    );
  }

  final String variantId;
  final String text;
  final String normalizedText;
  final String? literalTranslation;
  final String note;

  bool get hasLiteralTranslation => literalTranslation != null;

  Map<String, Object?> toJson() => <String, Object?>{
    'variantId': variantId,
    'text': text,
    if (literalTranslation != null) 'literalTranslation': literalTranslation,
    'note': note,
  };

  static IdiomVariant fromJson(Map<String, Object?> json) =>
      IdiomVariant.validated(
        variantId: json['variantId']! as String,
        text: json['text']! as String,
        literalTranslation: json['literalTranslation'] as String?,
        note: json['note'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdiomVariant &&
          other.variantId == variantId &&
          other.text == text &&
          other.literalTranslation == literalTranslation &&
          other.note == note);

  @override
  int get hashCode => Object.hash(variantId, text, literalTranslation, note);

  @override
  String toString() => 'IdiomVariant($variantId, $text)';
}

/// Tautan sebuah ungkapan ke bahasa lain pada registri konlang.
class IdiomLanguageLink {
  /// Membuat tautan; [targetLanguageId] dipangkas dan wajib tidak kosong.
  IdiomLanguageLink({
    required String targetLanguageId,
    required this.kind,
    String note = '',
  }) : targetLanguageId = targetLanguageId.trim(),
       note = note.trim() {
    if (this.targetLanguageId.isEmpty) {
      throw ArgumentError.value(
        targetLanguageId,
        'targetLanguageId',
        'target cannot be blank',
      );
    }
  }

  /// Id bahasa tujuan pada ConlangRegistry (referensi silang 109.17).
  final String targetLanguageId;
  final IdiomLinkKind kind;
  final String note;

  Map<String, Object?> toJson() => <String, Object?>{
    'targetLanguageId': targetLanguageId,
    'kind': kind.name,
    'note': note,
  };

  static IdiomLanguageLink fromJson(Map<String, Object?> json) =>
      IdiomLanguageLink(
        targetLanguageId: (json['targetLanguageId']! as String).trim(),
        kind: IdiomLinkKind.values.firstWhere((k) => k.name == json['kind']),
        note: json['note'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdiomLanguageLink &&
          other.targetLanguageId == targetLanguageId &&
          other.kind == kind &&
          other.note == note);

  @override
  int get hashCode => Object.hash(targetLanguageId, kind, note);

  @override
  String toString() => 'IdiomLanguageLink($kind, $targetLanguageId)';
}

/// Satu ungkapan lengkap: teks asli, terjemahan literal, arti, jenis,
/// varian, dan tautan bahasa.
class IdiomRecord {
  IdiomRecord._({
    required this.idiomId,
    required this.type,
    required this.originalText,
    required this.normalizedText,
    required this.literalTranslation,
    required this.meaning,
    required this.languageId,
    required this.variants,
    required this.links,
    required this.note,
  });

  /// Membuat record; seluruh field wajib (`note` dan koleksi opsional).
  factory IdiomRecord.validated({
    required String idiomId,
    required IdiomType type,
    required String originalText,
    required String literalTranslation,
    required String meaning,
    required String languageId,
    List<IdiomVariant> variants = const <IdiomVariant>[],
    List<IdiomLanguageLink> links = const <IdiomLanguageLink>[],
    String note = '',
  }) {
    final trimmedOriginal = _requireTrimmed(originalText, 'originalText');
    final canonical = normalizeIdiomText(trimmedOriginal);
    final seenVariantIds = <String>{};
    final seenVariantTexts = <String>{canonical};
    for (final v in variants) {
      if (!seenVariantIds.add(v.variantId)) {
        throw ArgumentError('duplicate variantId: ${v.variantId}');
      }
      if (!seenVariantTexts.add(v.normalizedText)) {
        throw ArgumentError(
          'variant text duplicates canonical or another variant: ${v.text}',
        );
      }
    }
    final seenLinkKeys = <String>{};
    var originalCount = 0;
    for (final l in links) {
      if (l.kind == IdiomLinkKind.original) originalCount++;
      if (originalCount > 1) {
        throw ArgumentError('at most one original language link is allowed');
      }
      final key = '${l.targetLanguageId.toLowerCase()}|${l.kind.name}';
      if (!seenLinkKeys.add(key)) {
        throw ArgumentError(
          'duplicate link target+kind: ${l.targetLanguageId}/${l.kind.name}',
        );
      }
    }
    return IdiomRecord._(
      idiomId: _requireTrimmed(idiomId, 'idiomId'),
      type: type,
      originalText: trimmedOriginal,
      normalizedText: canonical,
      literalTranslation: _requireTrimmed(
        literalTranslation,
        'literalTranslation',
      ),
      meaning: _requireTrimmed(meaning, 'meaning'),
      languageId: _requireTrimmed(languageId, 'languageId'),
      variants: List<IdiomVariant>.unmodifiable(variants),
      links: List<IdiomLanguageLink>.unmodifiable(links),
      note: note.trim(),
    );
  }

  final String idiomId;
  final IdiomType type;
  final String originalText;
  final String normalizedText;
  final String literalTranslation;
  final String meaning;
  final String languageId;
  final List<IdiomVariant> variants;
  final List<IdiomLanguageLink> links;
  final String note;

  /// Varian dengan teks ternormalisasi sama, toleran trim/kasus/whitespace.
  IdiomVariant? variantForText(String text) {
    final needle = normalizeIdiomText(text);
    if (needle.isEmpty) return null;
    for (final v in variants) {
      if (v.normalizedText == needle) return v;
    }
    return null;
  }

  /// Link dengan target bahasa tertentu (lookup kasus-toleran).
  IdiomLanguageLink? linkTo(String targetLanguageId) {
    final needle = targetLanguageId.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final l in links) {
      if (l.targetLanguageId.toLowerCase() == needle) return l;
    }
    return null;
  }

  /// Semua link dengan kind tertentu, urutan penyimpanan.
  List<IdiomLanguageLink> linksOfKind(IdiomLinkKind kind) =>
      List<IdiomLanguageLink>.unmodifiable(links.where((l) => l.kind == kind));

  /// Bahasa asal bila record menautkan satu link `original`.
  String? get originalSourceLanguageId {
    for (final l in links) {
      if (l.kind == IdiomLinkKind.original) return l.targetLanguageId;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'idiomId': idiomId,
    'type': type.name,
    'originalText': originalText,
    'literalTranslation': literalTranslation,
    'meaning': meaning,
    'languageId': languageId,
    'variants': variants.map((v) => v.toJson()).toList(),
    'links': links.map((l) => l.toJson()).toList(),
    'note': note,
  };

  static IdiomRecord fromJson(Map<String, Object?> json) =>
      IdiomRecord.validated(
        idiomId: json['idiomId']! as String,
        type: IdiomType.values.firstWhere((t) => t.name == json['type']),
        originalText: json['originalText']! as String,
        literalTranslation: json['literalTranslation']! as String,
        meaning: json['meaning']! as String,
        languageId: json['languageId']! as String,
        variants: (json['variants'] as List<Object?>? ?? const <Object?>[])
            .map((e) => IdiomVariant.fromJson((e! as Map<String, Object?>)))
            .toList(),
        links: (json['links'] as List<Object?>? ?? const <Object?>[])
            .map(
              (e) => IdiomLanguageLink.fromJson((e! as Map<String, Object?>)),
            )
            .toList(),
        note: json['note'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdiomRecord &&
          other.idiomId == idiomId &&
          other.type == type &&
          other.originalText == originalText &&
          other.literalTranslation == literalTranslation &&
          other.meaning == meaning &&
          other.languageId == languageId &&
          other.note == note &&
          other.variants.length == variants.length &&
          other.links.length == links.length &&
          List.generate(
            variants.length,
            (i) => other.variants[i] == variants[i],
          ).every((ok) => ok) &&
          List.generate(
            links.length,
            (i) => other.links[i] == links[i],
          ).every((ok) => ok));

  @override
  int get hashCode => Object.hash(
    idiomId,
    type,
    originalText,
    literalTranslation,
    meaning,
    languageId,
    note,
  );

  @override
  String toString() => 'IdiomRecord($idiomId, ${type.name})';
}

/// Registri ungkapan: kumpulan [IdiomRecord] terurut id, dengan guard
/// lintas record (idiomId dan variantId global unik).
class IdiomRegistry {
  IdiomRegistry._(this._records);

  /// Registri kosong.
  factory IdiomRegistry.empty() => IdiomRegistry._(const <IdiomRecord>[]);

  /// Membangun registri; idiomId dan variantId wajib unik lintas record.
  factory IdiomRegistry.withRecords(List<IdiomRecord> records) {
    final seenIds = <String>{};
    final seenVariantIds = <String>{};
    for (final r in records) {
      if (!seenIds.add(r.idiomId)) {
        throw ArgumentError('duplicate idiomId: ${r.idiomId}');
      }
      for (final v in r.variants) {
        if (!seenVariantIds.add(v.variantId)) {
          throw ArgumentError(
            'duplicate variantId across records: ${v.variantId}',
          );
        }
      }
    }
    final sorted = List<IdiomRecord>.of(records)
      ..sort((a, b) => a.idiomId.compareTo(b.idiomId));
    return IdiomRegistry._(List<IdiomRecord>.unmodifiable(sorted));
  }

  final List<IdiomRecord> _records;

  List<IdiomRecord> get records => _records;

  List<String> get idiomIds =>
      List<String>.unmodifiable(_records.map((r) => r.idiomId));

  int get recordCount => _records.length;

  int get totalVariantCount =>
      _records.fold(0, (sum, r) => sum + r.variants.length);

  int get totalLinkCount => _records.fold(0, (sum, r) => sum + r.links.length);

  /// Seluruh bahasa pemilik ungkapan, terurut.
  List<String> get languageIds => List<String>.unmodifiable(
    (_records.map((r) => r.languageId.toLowerCase()).toSet()
          ..removeWhere((e) => e.isEmpty))
        .toList()
      ..sort(),
  );

  /// Lookup per idiomId, toleran whitespace.
  IdiomRecord? recordFor(String idiomId) {
    final needle = idiomId.trim();
    if (needle.isEmpty) return null;
    for (final r in _records) {
      if (r.idiomId == needle) return r;
    }
    return null;
  }

  List<IdiomRecord> recordsOfType(IdiomType type) =>
      List<IdiomRecord>.unmodifiable(_records.where((r) => r.type == type));

  List<IdiomRecord> recordsInLanguage(String languageId) {
    final needle = languageId.trim().toLowerCase();
    if (needle.isEmpty) return const <IdiomRecord>[];
    return List<IdiomRecord>.unmodifiable(
      _records.where((r) => r.languageId.toLowerCase() == needle),
    );
  }

  /// Record yang punya link (kind apa pun) ke bahasa [targetLanguageId].
  List<IdiomRecord> recordsLinkingTo(String targetLanguageId) {
    final needle = targetLanguageId.trim().toLowerCase();
    if (needle.isEmpty) return const <IdiomRecord>[];
    return List<IdiomRecord>.unmodifiable(
      _records.where((r) => r.linkTo(needle) != null),
    );
  }

  /// Record kanon dengan teks ternormalisasi persis, toleran whitespace/kasus.
  IdiomRecord? findByNormalizedText(String text) {
    final needle = normalizeIdiomText(text);
    if (needle.isEmpty) return null;
    for (final r in _records) {
      if (r.normalizedText == needle) return r;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'records': _records.map((r) => r.toJson()).toList(),
  };

  static IdiomRegistry fromJson(Map<String, Object?> json) =>
      IdiomRegistry.withRecords(
        (json['records'] as List<Object?>? ?? const <Object?>[])
            .map((e) => IdiomRecord.fromJson(e! as Map<String, Object?>))
            .toList(),
      );

  @override
  String toString() => 'IdiomRegistry($recordCount records)';
}

/// Query deterministik atas [IdiomRegistry]; semua filter di-AND-kan.
class IdiomQuery {
  const IdiomQuery({
    this.type,
    this.languageId,
    this.textContains,
    this.requireVariant = false,
    this.requireLinkKind,
  });

  final IdiomType? type;
  final String? languageId;

  /// Substring atas teks ternormalisasi (mencakup kanon dan varian).
  final String? textContains;
  final bool requireVariant;
  final IdiomLinkKind? requireLinkKind;

  bool get isEmpty =>
      type == null &&
      languageId == null &&
      (textContains == null || textContains!.trim().isEmpty) &&
      !requireVariant &&
      requireLinkKind == null;

  List<IdiomRecord> apply(IdiomRegistry registry) {
    final needle = normalizeIdiomText(textContains ?? '');
    final lang = languageId?.trim().toLowerCase() ?? '';
    final hits = registry.records.where((r) {
      if (type != null && r.type != type) return false;
      if (lang.isNotEmpty && r.languageId.toLowerCase() != lang) return false;
      if (requireVariant && r.variants.isEmpty) return false;
      if (requireLinkKind != null &&
          r.links.every((l) => l.kind != requireLinkKind)) {
        return false;
      }
      if (needle.isNotEmpty) {
        final inCanonical = r.normalizedText.contains(needle);
        final inVariants = r.variants.any(
          (v) => v.normalizedText.contains(needle),
        );
        if (!inCanonical && !inVariants) return false;
      }
      return true;
    }).toList();
    return List<IdiomRecord>.unmodifiable(hits);
  }

  String describe() {
    if (isEmpty) return 'IdiomQuery(semua ungkapan)';
    final parts = <String>[];
    if (type != null) parts.add('type=${type!.label}');
    if (languageId != null && languageId!.trim().isNotEmpty) {
      parts.add('language=$languageId');
    }
    if (textContains != null && textContains!.trim().isNotEmpty) {
      parts.add('contains="$textContains"');
    }
    if (requireVariant) parts.add('hasVariant');
    if (requireLinkKind != null) parts.add('link=${requireLinkKind!.label}');
    return 'IdiomQuery(${parts.join(', ')})';
  }
}
