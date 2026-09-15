// Sprint 111.29 - Syllable Pool & Phonotactic Rules (domain-only).
//
// Menyimpan onset, nucleus, coda, pola suku kata, tekanan, dan kombinasi
// terlarang untuk satu bahasa buatan, sebagai kontrak domain murni.
//
// Enam acceptance canonical sprint_111.json dipetakan:
// - syllable_parts      -> SyllablePart + SyllableSlot (onset/nucleus/coda)
// - patterns            -> SyllablePattern.parse (template C/V + grup opsional)
// - weights             -> SyllablePattern.weight + massa derivatif SyllableMass
// - stress_rules        -> StressRule + StressKind, indeks suku kata tekan
// - forbidden_sequences -> ForbiddenSequence.occursIn + violationsIn
// - conlang_links       -> PhonotacticsConlangLink + resolveLanguageLinks
//
// Tanpa persistence, UI, locale, jaringan, wall-clock, atau random.
// D-SCHEMA-01 tetap OPEN; modul ini mirror domain untuk Drift mendatang.

library;

/// Posisi sebuah bunyi dalam struktur suku kata.
enum SyllableSlot {
  /// Onset — pembuka suku kata.
  onset,

  /// Nucleus — inti suku kata (wajib pada suku kata yang sah).
  nucleus,

  /// Coda — penutup suku kata.
  coda,
}

/// Berat suku kata derivatif dari isi nucleus dan coda.
enum SyllableMass {
  /// Ringan: nucleus tunggal tanpa coda.
  light,

  /// Berat: satu coda, atau nucleus ganda tanpa coda.
  heavy,

  /// Superberat: nucleus ganda dengan coda, atau coda ganda.
  superheavy,
}

/// Jenis kaidah tekanan suku kata.
enum StressKind {
  /// Suku kata pertama.
  initial,

  /// Suku kata terakhir.
  ultimate,

  /// Suku kedua dari akhir.
  penult,

  /// Suku ketiga dari akhir.
  antepenult,

  /// Pola Latin: penult bila berat, selainnya antepenult.
  latinPenult,

  /// Berat paling kanan, fallback suku kata terakhir.
  rightmostHeavyOrFinal,
}

/// Peran hubungan sebuah registri fonotaktik dengan bahasa konlang lain.
enum ConlangLinkKind {
  /// Bahasa utama yang difonotaktikkan registri ini.
  primary,

  /// Kekerabatan/kognat.
  cognate,

  /// Kontak bahasa (pinjaman, areal).
  contact,

  /// Catatan historis/perbandingan.
  notes,
}

/// Satu bunyi dalam pool suku kata, dengan posisi yang boleh ditempatinya.
class SyllablePart {
  const SyllablePart._({required this.symbol, required this._slots});

  /// Membuat bagian pool tervalidasi: [symbol] dipangkas dan wajib tidak
  /// kosong; [slots] dinormalisasi ke urutan canonically ordered
  /// (onset, nucleus, coda) tanpa duplikat, dan wajib tidak kosong.
  factory SyllablePart.validated({
    required String symbol,
    required List<SyllableSlot> slots,
  }) {
    final trimmed = symbol.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(symbol, 'symbol', 'symbol cannot be empty');
    }
    if (slots.isEmpty) {
      throw ArgumentError.value(slots, 'slots', 'slots cannot be empty');
    }
    final ordered = <SyllableSlot>[
      for (final slot in SyllableSlot.values)
        if (slots.contains(slot)) slot,
    ];
    return SyllablePart._(symbol: trimmed, slots: List.unmodifiable(ordered));
  }

  /// Simbol bunyi (huruf, IPA, atau label internal).
  final String symbol;

  final List<SyllableSlot> _slots;

  /// Slot yang boleh ditempati simbol ini, urutan canonical.
  List<SyllableSlot> get slots => _slots;

  /// Apakah simbol ini sah pada [slot].
  bool canOccurIn(SyllableSlot slot) => _slots.contains(slot);

  Map<String, Object?> toJson() => <String, Object?>{
    'symbol': symbol,
    'slots': <Object?>[for (final slot in _slots) slot.name],
  };

  static SyllablePart fromJson(Map<String, Object?> json) =>
      SyllablePart.validated(
        symbol: json['symbol']! as String,
        slots: <SyllableSlot>[
          for (final raw in (json['slots']! as List<Object?>))
            SyllableSlot.values.firstWhere((slot) => slot.name == raw),
        ],
      );
}

/// Satu posisi dalam template pola suku kata.
class SyllablePosition {
  const SyllablePosition({required this.slot, this.optional = false});

  final SyllableSlot slot;

  /// True bila posisi dibungkus kurung pada template, mis. `(C)`.
  final bool optional;
}

/// Pola suku kata sebagai template berhuruf C/V dengan grup opsional kurung.
class SyllablePattern {
  const SyllablePattern._({
    required this.id,
    required this.template,
    required this._positions,
    required this.weight,
  });

  /// Membuat pola tervalidasi dari [template] canonical: karakter `C`
  /// (onset/coda), `V` (nucleus), dan kurung `(...)` penanda opsional.
  /// Wajib memuat minimal satu `V`; karakter asing, kurung tak seimbang,
  /// template kosong, atau [id]/[weight] tidak sah melempar
  /// [ArgumentError].
  factory SyllablePattern.parse({
    required String id,
    required String template,
    int weight = 1,
  }) {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'id cannot be empty');
    }
    if (weight < 0) {
      throw ArgumentError.value(weight, 'weight', 'weight must be >= 0');
    }
    final positions = <SyllablePosition>[];
    var optionalDepth = 0;
    var nucleusSeen = false;
    for (var i = 0; i < template.length; i++) {
      final ch = template[i];
      switch (ch) {
        case '(':
          optionalDepth++;
        case ')':
          optionalDepth--;
          if (optionalDepth < 0) {
            throw ArgumentError.value(
              template,
              'template',
              'unbalanced parentheses',
            );
          }
        case 'C':
          // Konsonan sebelum nucleus adalah onset; sesudahnya coda.
          positions.add(
            SyllablePosition(
              slot: nucleusSeen ? SyllableSlot.coda : SyllableSlot.onset,
              optional: optionalDepth > 0,
            ),
          );
        case 'V':
          nucleusSeen = true;
          positions.add(
            SyllablePosition(
              slot: SyllableSlot.nucleus,
              optional: optionalDepth > 0,
            ),
          );
        default:
          throw ArgumentError.value(
            template,
            'template',
            'unknown template character: $ch',
          );
      }
    }
    if (optionalDepth != 0) {
      throw ArgumentError.value(template, 'template', 'unbalanced parentheses');
    }
    if (positions.isEmpty) {
      throw ArgumentError.value(
        template,
        'template',
        'template cannot be empty',
      );
    }
    if (!positions.any((p) => p.slot == SyllableSlot.nucleus)) {
      throw ArgumentError.value(
        template,
        'template',
        'template must contain at least one nucleus (V)',
      );
    }
    return SyllablePattern._(
      id: trimmedId,
      template: template,
      positions: List.unmodifiable(positions),
      weight: weight,
    );
  }

  final String id;

  /// Template sebagaimana ditulis, mis. `CVC` atau `(C)V(C)`.
  final String template;

  final List<SyllablePosition> _positions;
  final int weight;

  /// Deretan posisi pola, urutan template.
  List<SyllablePosition> get positions => _positions;

  /// Massa derivatif dari isi wajib pola: nucleus ganda -> +berat,
  /// coda tunggal -> berat, coda ganda/nukleus ganda+coda -> superberat.
  SyllableMass get mass {
    final required = _positions.where((p) => !p.optional);
    final nuclei = required.where((p) => p.slot == SyllableSlot.nucleus).length;
    final codas = required.where((p) => p.slot == SyllableSlot.coda).length;
    if (codas >= 2 || (nuclei >= 2 && codas >= 1)) {
      return SyllableMass.superheavy;
    }
    if (codas == 1 || nuclei >= 2) {
      return SyllableMass.heavy;
    }
    return SyllableMass.light;
  }

  /// Apakah urutan [slots] konkret cocok dengan pola ini, memetakan setiap
  /// slot ke posisi berurutan yang boleh kosong bila opsional.
  bool matches(List<SyllableSlot> slots) {
    var slotIndex = 0;
    for (final position in _positions) {
      if (slotIndex < slots.length && slots[slotIndex] == position.slot) {
        slotIndex++;
      } else if (!position.optional) {
        return false;
      }
    }
    return slotIndex == slots.length;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'template': template,
    'weight': weight,
  };

  static SyllablePattern fromJson(Map<String, Object?> json) =>
      SyllablePattern.parse(
        id: json['id']! as String,
        template: json['template']! as String,
        weight: (json['weight'] as int?) ?? 1,
      );
}

/// Satu kaidah tekanan suku kata.
class StressRule {
  /// Membuat kaidah; [id] dipangkas dan wajib tidak kosong.
  StressRule({required String id, required this.kind, String note = ''})
    : id = id.trim(),
      note = note.trim() {
    if (this.id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'id cannot be empty');
    }
  }

  final String id;
  final StressKind kind;

  /// Catatan dokumentasi opsional.
  final String note;

  /// Indeks (0-based) suku kata yang mendapat tekanan untuk daftar massa
  /// [masses]; [StateError] bila daftar kosong.
  int stressedIndex(List<SyllableMass> masses) {
    if (masses.isEmpty) {
      throw StateError('cannot stress an empty syllable list');
    }
    final n = masses.length;
    switch (kind) {
      case StressKind.initial:
        return 0;
      case StressKind.ultimate:
        return n - 1;
      case StressKind.penult:
        return n >= 2 ? n - 2 : 0;
      case StressKind.antepenult:
        return n >= 3 ? n - 3 : 0;
      case StressKind.latinPenult:
        if (n >= 2 && masses[n - 2].index >= SyllableMass.heavy.index) {
          return n - 2;
        }
        return n >= 3 ? n - 3 : 0;
      case StressKind.rightmostHeavyOrFinal:
        for (var i = n - 1; i >= 0; i--) {
          if (masses[i].index >= SyllableMass.heavy.index) {
            return i;
          }
        }
        return n - 1;
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'kind': kind.name,
    'note': note,
  };

  static StressRule fromJson(Map<String, Object?> json) => StressRule(
    id: json['id']! as String,
    kind: StressKind.values.firstWhere((k) => k.name == json['kind']),
    note: json['note'] as String? ?? '',
  );
}

/// Kombinasi bunyi yang dilarang berurutan dalam kata.
class ForbiddenSequence {
  const ForbiddenSequence._({
    required this.id,
    required this._symbols,
    required this.note,
  });

  /// Membuat larangan tervalidasi: [id] dan minimal satu simbol non-kosong
  /// pada [symbols] (tiap simbol dipangkas, simbol kosong dibuang);
  /// [note] opsional dipangkas.
  factory ForbiddenSequence.validated({
    required String id,
    required List<String> symbols,
    String note = '',
  }) {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'id cannot be empty');
    }
    final cleaned = <String>[
      for (final s in symbols)
        if (s.trim().isNotEmpty) s.trim(),
    ];
    if (cleaned.isEmpty) {
      throw ArgumentError.value(
        symbols,
        'symbols',
        'forbidden sequence needs at least one symbol',
      );
    }
    return ForbiddenSequence._(
      id: trimmedId,
      symbols: List.unmodifiable(cleaned),
      note: note.trim(),
    );
  }

  final String id;

  final List<String> _symbols;

  /// Rangkaian simbol terlarang, urutan terjaga.
  List<String> get symbols => _symbols;

  final String note;

  /// Apakah [symbols] konkret memuat rangkaian terlarang ini sebagai
  /// sub-list berurutan.
  bool occursIn(List<String> symbols) {
    final needle = _symbols;
    if (needle.length > symbols.length) return false;
    for (var start = 0; start + needle.length <= symbols.length; start++) {
      var hit = true;
      for (var j = 0; j < needle.length; j++) {
        if (symbols[start + j] != needle[j]) {
          hit = false;
          break;
        }
      }
      if (hit) return true;
    }
    return false;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'symbols': <Object?>[...symbols],
    'note': note,
  };

  static ForbiddenSequence fromJson(Map<String, Object?> json) =>
      ForbiddenSequence.validated(
        id: json['id']! as String,
        symbols: (json['symbols']! as List<Object?>).cast<String>(),
        note: json['note'] as String? ?? '',
      );
}

/// Tautan registri fonotaktik ini ke bahasa konlang lain (109.17/109.18).
class PhonotacticsConlangLink {
  /// Membuat tautan; [targetLanguageId] dipangkas dan wajib tidak kosong.
  PhonotacticsConlangLink({
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

  /// Id bahasa tujuan pada ConlangRegistry.
  final String targetLanguageId;
  final ConlangLinkKind kind;
  final String note;

  Map<String, Object?> toJson() => <String, Object?>{
    'targetLanguageId': targetLanguageId,
    'kind': kind.name,
    'note': note,
  };

  static PhonotacticsConlangLink fromJson(Map<String, Object?> json) =>
      PhonotacticsConlangLink(
        targetLanguageId: (json['targetLanguageId']! as String).trim(),
        kind: ConlangLinkKind.values.firstWhere((k) => k.name == json['kind']),
        note: json['note'] as String? ?? '',
      );
}

/// Registrasi fonotaktik lengkap satu bahasa buatan: pool suku kata, pola
/// beserta bobot/massa, kaidah tekanan, kombinasi terlarang, dan tautan
/// konlang.
class PhonotacticsSpec {
  const PhonotacticsSpec._({
    required this.id,
    required this.languageId,
    required this._inventory,
    required this._patterns,
    required this._stressRules,
    required this.defaultStressRuleId,
    required this._forbidden,
    required this._conlangLinks,
  });

  /// Membangun spesifikasi tervalidasi dengan integritas referensial:
  /// id/languageId non-kosong; patterns minimal satu; symbol inventaris
  /// unik; id pattern unik; setiap slot yang dipakai pola punya anggota
  /// inventaris; id stress rule unik dan [defaultStressRuleId] (bila ada)
  /// menunjuk aturan terdaftar; id forbidden unik dan setiap simbolnya
  /// anggota inventaris; tautan konlang boleh kosong namun target unik
  /// dan maksimal satu [ConlangLinkKind.primary]. Melanggar = [ArgumentError].
  factory PhonotacticsSpec.validated({
    required String id,
    required String languageId,
    required List<SyllablePart> inventory,
    required List<SyllablePattern> patterns,
    List<StressRule> stressRules = const <StressRule>[],
    String? defaultStressRuleId,
    List<ForbiddenSequence> forbidden = const <ForbiddenSequence>[],
    List<PhonotacticsConlangLink> conlangLinks =
        const <PhonotacticsConlangLink>[],
  }) {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'id cannot be empty');
    }
    final trimmedLang = languageId.trim();
    if (trimmedLang.isEmpty) {
      throw ArgumentError.value(
        languageId,
        'languageId',
        'languageId cannot be empty',
      );
    }
    if (patterns.isEmpty) {
      throw ArgumentError.value(
        patterns,
        'patterns',
        'at least one syllable pattern is required',
      );
    }
    final seenSymbols = <String>{};
    for (final part in inventory) {
      if (!seenSymbols.add(part.symbol)) {
        throw ArgumentError.value(
          part.symbol,
          'inventory',
          'duplicate syllable part symbol: ${part.symbol}',
        );
      }
    }
    final seenPatterns = <String>{};
    for (final p in patterns) {
      if (!seenPatterns.add(p.id)) {
        throw ArgumentError.value(
          p.id,
          'patterns',
          'duplicate pattern id: ${p.id}',
        );
      }
    }
    final usedSlots = <SyllableSlot>{
      for (final p in patterns)
        for (final pos in p.positions) pos.slot,
    };
    for (final slot in usedSlots) {
      final hasPart = inventory.any((part) => part.canOccurIn(slot));
      if (!hasPart) {
        throw ArgumentError.value(
          slot.name,
          'patterns',
          'pattern slot $slot has no inventory member',
        );
      }
    }
    final seenStress = <String>{};
    for (final rule in stressRules) {
      if (!seenStress.add(rule.id)) {
        throw ArgumentError.value(
          rule.id,
          'stressRules',
          'duplicate stress rule id: ${rule.id}',
        );
      }
    }
    final trimmedDefault = defaultStressRuleId?.trim();
    final effectiveDefault = (trimmedDefault == null || trimmedDefault.isEmpty)
        ? null
        : trimmedDefault;
    if (effectiveDefault != null &&
        !stressRules.any((r) => r.id == effectiveDefault)) {
      throw ArgumentError.value(
        effectiveDefault,
        'defaultStressRuleId',
        'unknown default stress rule: $effectiveDefault',
      );
    }
    final seenForbidden = <String>{};
    for (final f in forbidden) {
      if (!seenForbidden.add(f.id)) {
        throw ArgumentError.value(
          f.id,
          'forbidden',
          'duplicate forbidden sequence id: ${f.id}',
        );
      }
      for (final symbol in f.symbols) {
        if (!seenSymbols.contains(symbol)) {
          throw ArgumentError.value(
            symbol,
            'forbidden',
            'forbidden symbol outside syllable pool: $symbol',
          );
        }
      }
    }
    final seenTargets = <String>{};
    var primaryCount = 0;
    for (final link in conlangLinks) {
      final target = link.targetLanguageId.trim();
      if (target.isEmpty) {
        throw ArgumentError.value(
          link.targetLanguageId,
          'conlangLinks',
          'link target cannot be blank',
        );
      }
      if (!seenTargets.add(target)) {
        throw ArgumentError.value(
          target,
          'conlangLinks',
          'duplicate link target: $target',
        );
      }
      if (link.kind == ConlangLinkKind.primary) primaryCount++;
    }
    if (primaryCount > 1) {
      throw ArgumentError.value(
        primaryCount,
        'conlangLinks',
        'at most one primary link is allowed',
      );
    }
    return PhonotacticsSpec._(
      id: trimmedId,
      languageId: trimmedLang,
      inventory: List.unmodifiable(inventory),
      patterns: List.unmodifiable(patterns),
      stressRules: List.unmodifiable(stressRules),
      defaultStressRuleId: effectiveDefault,
      forbidden: List.unmodifiable(forbidden),
      conlangLinks: List.unmodifiable(conlangLinks),
    );
  }

  final String id;

  /// Id bahasa pemilik registri ini.
  final String languageId;

  final List<SyllablePart> _inventory;
  final List<SyllablePattern> _patterns;
  final List<StressRule> _stressRules;
  final String? defaultStressRuleId;
  final List<ForbiddenSequence> _forbidden;
  final List<PhonotacticsConlangLink> _conlangLinks;

  /// Pool suku kata terurut symbol (deterministik).
  List<SyllablePart> get inventory => List.unmodifiable(
    (_inventory.toList()..sort((a, b) => a.symbol.compareTo(b.symbol))),
  );

  /// Pola dalam urutan pendaftaran.
  List<SyllablePattern> get patterns => _patterns;

  /// Kaidah tekanan dalam urutan pendaftaran.
  List<StressRule> get stressRules => _stressRules;

  /// Kombinasi terlarang dalam urutan pendaftaran.
  List<ForbiddenSequence> get forbidden => _forbidden;

  /// Tautan konlang dalam urutan pendaftaran.
  List<PhonotacticsConlangLink> get conlangLinks => _conlangLinks;

  /// Jumlah bagian pool.
  int get inventoryCount => _inventory.length;

  /// Jumlah pola.
  int get patternCount => _patterns.length;

  /// Bagian pool yang boleh menempati [slot], terurut symbol.
  List<SyllablePart> partsForSlot(SyllableSlot slot) =>
      List.unmodifiable(inventory.where((part) => part.canOccurIn(slot)));

  /// Pola dengan massa tertentu, terurut id.
  List<SyllablePattern> patternsOfMass(SyllableMass mass) => List.unmodifiable(
    (_patterns.where((p) => p.mass == mass).toList())
      ..sort((a, b) => a.id.compareTo(b.id)),
  );

  /// Pola ber-id [id]; null bila tidak ada (lookup trim-tolerant).
  SyllablePattern? patternById(String id) {
    final key = id.trim();
    if (key.isEmpty) return null;
    for (final p in _patterns) {
      if (p.id == key) return p;
    }
    return null;
  }

  /// Kaidah tekanan ber-id [id]; null bila tidak ada.
  StressRule? stressRuleById(String id) {
    final key = id.trim();
    if (key.isEmpty) return null;
    for (final r in _stressRules) {
      if (r.id == key) return r;
    }
    return null;
  }

  /// Kombinasi terlarang yang terjadi pada [symbols], terurut id.
  List<String> violationsIn(List<String> symbols) => List.unmodifiable(
    (_forbidden.where((f) => f.occursIn(symbols)).map((f) => f.id).toList())
      ..sort(),
  );

  /// True bila [symbols] bebas dari seluruh kombinasi terlarang.
  bool isWordLegal(List<String> symbols) => violationsIn(symbols).isEmpty;

  /// Indeks suku kata tekan memakai default; [StateError] bila tidak ada
  /// default atau daftar massa kosong.
  int stressedIndex(List<SyllableMass> masses) {
    final ruleId = defaultStressRuleId;
    if (ruleId == null) {
      throw StateError('no default stress rule on spec $id');
    }
    return stressRuleById(ruleId)!.stressedIndex(masses);
  }

  /// Target tautan yang tidak ada pada [knownLanguageIds] (bekas tautan
  /// yatim), terurut id.
  List<String> resolveLanguageLinks(Set<String> knownLanguageIds) =>
      List.unmodifiable(
        (_conlangLinks
              .map((l) => l.targetLanguageId)
              .where((t) => !knownLanguageIds.contains(t))
              .toList())
          ..sort(),
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'languageId': languageId,
    'inventory': <Object?>[for (final p in _inventory) p.toJson()],
    'patterns': <Object?>[for (final p in _patterns) p.toJson()],
    'stressRules': <Object?>[for (final r in _stressRules) r.toJson()],
    'defaultStressRuleId': defaultStressRuleId,
    'forbidden': <Object?>[for (final f in _forbidden) f.toJson()],
    'conlangLinks': <Object?>[for (final l in _conlangLinks) l.toJson()],
  };

  static PhonotacticsSpec fromJson(Map<String, Object?> json) =>
      PhonotacticsSpec.validated(
        id: json['id']! as String,
        languageId: json['languageId']! as String,
        inventory: <SyllablePart>[
          for (final raw in (json['inventory']! as List<Object?>))
            SyllablePart.fromJson((raw! as Map<Object?, Object?>).toTypes),
        ],
        patterns: <SyllablePattern>[
          for (final raw in (json['patterns']! as List<Object?>))
            SyllablePattern.fromJson((raw! as Map<Object?, Object?>).toTypes),
        ],
        stressRules: <StressRule>[
          for (final raw
              in ((json['stressRules'] as List<Object?>?) ?? const <Object?>[]))
            StressRule.fromJson((raw! as Map<Object?, Object?>).toTypes),
        ],
        defaultStressRuleId: json['defaultStressRuleId'] as String?,
        forbidden: <ForbiddenSequence>[
          for (final raw
              in ((json['forbidden'] as List<Object?>?) ?? const <Object?>[]))
            ForbiddenSequence.fromJson((raw! as Map<Object?, Object?>).toTypes),
        ],
        conlangLinks: <PhonotacticsConlangLink>[
          for (final raw
              in ((json['conlangLinks'] as List<Object?>?) ??
                  const <Object?>[]))
            PhonotacticsConlangLink.fromJson(
              (raw! as Map<Object?, Object?>).toTypes,
            ),
        ],
      );
}

extension on Map<Object?, Object?> {
  Map<String, Object?> get toTypes =>
      map((key, value) => MapEntry(key.toString(), value));
}
