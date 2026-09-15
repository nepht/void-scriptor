// Sprint 111.34 - Cultural Ownership & Usage Context (domain-only).
//
// Melengkapi registri ungkapan 111.33 dengan konteks kepemilikan dan
// pemakaian: wilayah, budaya, faksi, profesi, era, situasi sosial, dan
// register (tingkat formalitas), termasuk pihak yang MENGHINDARI ungkapan.
//
// Tujuh acceptance canonical sprint_111.json dipetakan:
// - regions      -> IdiomRegionRef (wilayah + stance pemakaian)
// - cultures     -> IdiomCultureRef (budaya + stance)
// - factions     -> IdiomFactionRef (role memakai ScopeFactionRole 111.5)
// - professions  -> IdiomProfessionRef (profesi penutur + stance)
// - eras         -> IdiomEraRange (marker cerita + sequence rank opsional,
//                   konvensi yang sama dengan 111.26/27/30)
// - contexts     -> IdiomContextUsage atas SocialContext 111.30
// - register     -> IdiomRegister ladder formalitas + registerFor(context)
//
// "Pihak yang menghindari ungkapan" dicatat lewat stance avoided pada facet
// manapun — tidak ada tabel separate — sehingga pertanyaan "siapa menghindari
// apa" terjawab seragam lintas facet (avoiderIds / idiomsAvoidedByX).
//
// Sengaja TANPA validasi konsistensi/anakronisme: itu ranah 111.36
// (Idiom Consistency & Anachronism Checks). Modul ini murni data + query
// deterministik.
//
// Tanpa persistence, UI, locale, jaringan, wall-clock, atau random.
// D-SCHEMA-01 tetap OPEN; modul ini mirror domain untuk Drift mendatang.

library;

import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_profiles.dart'
    show SocialContext;
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_scope.dart'
    show ScopeFactionRole;

String _requireTrimmed(String value, String fieldName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return trimmed;
}

String? _optionalTrimmed(String? value, String fieldName) {
  final trimmed = value?.trim();
  if (trimmed != null && trimmed.isEmpty) {
    throw ArgumentError('$fieldName must be non-empty when provided');
  }
  return trimmed;
}

String _normalizeKey(String value) => value.trim().toLowerCase();

/// Seberapa erat sebuah wilayah/budaya/faksi/profesi memakai ungkapan.
/// [avoided] menangkap acceptance "pihak yang menghindari ungkapan".
enum IdiomUseStance {
  /// Pemakai utama — ungkapan lahir/lezat di sini.
  primary('Primary user'),

  /// Pemakaian lazim tanpa keistimewaan.
  common('Common user'),

  /// Pemakaian terbatas/insidental.
  occasional('Occasional user'),

  /// Jarang dipakai, hampir punah di pihak ini.
  rare('Rare user'),

  /// Pihak secara sadar MENGHINDARI ungkapan (tabu/sosial/politik).
  avoided('Avoids the saying');

  const IdiomUseStance(this.label);

  final String label;

  /// Bobot urutan penyimpanan (index enum) — deterministik.
  int get weight => index;

  bool get isAvoidance => this == IdiomUseStance.avoided;

  static IdiomUseStance fromName(String? name) =>
      values.firstWhere((s) => s.name == name);
}

/// Tingkat formalitas (register) pemakaian ungkapan. Naik monotonic dalam
/// formalitas; [formality] dipakai untuk perbandingan dan penyaringan.
enum IdiomRegister {
  /// Bahasa pasar/pungutan, sangat informal.
  vulgar('Vulgar', 0),

  /// Santai, percakapan akrab.
  colloquial('Colloquial', 1),

  /// Netral, aman di kebanyakan situasi.
  neutral('Neutral', 2),

  /// Resmi/birokratis.
  formal('Formal', 3),

  /// Hormat kepada orang atau institusi.
  honorific('Honorific', 4),

  /// Sakral/upacaraan — register paling tinggi.
  ceremonial('Ceremonial', 5);

  const IdiomRegister(this.label, this.formality);

  final String label;
  final int formality;

  bool atLeast(IdiomRegister other) => formality >= other.formality;

  bool moreFormalThan(IdiomRegister other) => formality > other.formality;

  static IdiomRegister fromName(String? name) =>
      values.firstWhere((r) => r.name == name);
}

/// Empat facet kepemilikan yang bisa ditanya "siapa memakai/menghindari".
enum IdiomOwnershipFacet {
  region('Region'),
  culture('Culture'),
  faction('Faction'),
  profession('Profession');

  const IdiomOwnershipFacet(this.label);

  final String label;
}

/// Satu wilayah tempat ungkapan dipakai (atau dihindari).
class IdiomRegionRef {
  const IdiomRegionRef._({
    required this.regionId,
    required this.stance,
    required this.note,
  });

  /// Membuat rujukan; [regionId] wajib non-kosong (dipangkas).
  factory IdiomRegionRef.validated({
    required String regionId,
    IdiomUseStance stance = IdiomUseStance.common,
    String note = '',
  }) {
    return IdiomRegionRef._(
      regionId: _requireTrimmed(regionId, 'regionId'),
      stance: stance,
      note: note.trim(),
    );
  }

  final String regionId;
  final IdiomUseStance stance;
  final String note;

  Map<String, Object?> toJson() => <String, Object?>{
    'regionId': regionId,
    'stance': stance.name,
    'note': note,
  };

  static IdiomRegionRef fromJson(Map<String, Object?> json) =>
      IdiomRegionRef.validated(
        regionId: json['regionId']! as String,
        stance: IdiomUseStance.fromName(json['stance'] as String?),
        note: json['note'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdiomRegionRef &&
          other.regionId == regionId &&
          other.stance == stance &&
          other.note == note);

  @override
  int get hashCode => Object.hash(regionId, stance, note);

  @override
  String toString() => 'IdiomRegionRef($regionId, ${stance.name})';
}

/// Satu budaya pemakai (atau penghindar) ungkapan.
class IdiomCultureRef {
  const IdiomCultureRef._({
    required this.cultureId,
    required this.stance,
    required this.note,
  });

  factory IdiomCultureRef.validated({
    required String cultureId,
    IdiomUseStance stance = IdiomUseStance.common,
    String note = '',
  }) {
    return IdiomCultureRef._(
      cultureId: _requireTrimmed(cultureId, 'cultureId'),
      stance: stance,
      note: note.trim(),
    );
  }

  final String cultureId;
  final IdiomUseStance stance;
  final String note;

  Map<String, Object?> toJson() => <String, Object?>{
    'cultureId': cultureId,
    'stance': stance.name,
    'note': note,
  };

  static IdiomCultureRef fromJson(Map<String, Object?> json) =>
      IdiomCultureRef.validated(
        cultureId: json['cultureId']! as String,
        stance: IdiomUseStance.fromName(json['stance'] as String?),
        note: json['note'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdiomCultureRef &&
          other.cultureId == cultureId &&
          other.stance == stance &&
          other.note == note);

  @override
  int get hashCode => Object.hash(cultureId, stance, note);

  @override
  String toString() => 'IdiomCultureRef($cultureId, ${stance.name})';
}

/// Satu faksi dengan role (konvensi ScopeFactionRole 111.5) dan stance.
class IdiomFactionRef {
  const IdiomFactionRef._({
    required this.factionId,
    required this.role,
    required this.stance,
    required this.note,
  });

  factory IdiomFactionRef.validated({
    required String factionId,
    ScopeFactionRole role = ScopeFactionRole.owning,
    IdiomUseStance stance = IdiomUseStance.common,
    String note = '',
  }) {
    return IdiomFactionRef._(
      factionId: _requireTrimmed(factionId, 'factionId'),
      role: role,
      stance: stance,
      note: note.trim(),
    );
  }

  final String factionId;
  final ScopeFactionRole role;
  final IdiomUseStance stance;
  final String note;

  Map<String, Object?> toJson() => <String, Object?>{
    'factionId': factionId,
    'role': role.name,
    'stance': stance.name,
    'note': note,
  };

  static IdiomFactionRef fromJson(Map<String, Object?> json) =>
      IdiomFactionRef.validated(
        factionId: json['factionId']! as String,
        role: ScopeFactionRole.values.firstWhere((r) => r.name == json['role']),
        stance: IdiomUseStance.fromName(json['stance'] as String?),
        note: json['note'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdiomFactionRef &&
          other.factionId == factionId &&
          other.role == role &&
          other.stance == stance &&
          other.note == note);

  @override
  int get hashCode => Object.hash(factionId, role, stance, note);

  @override
  String toString() => 'IdiomFactionRef($factionId, ${role.name})';
}

/// Satu profesi penutur ungkapan (mis. pelaut, notaris, pendeta).
class IdiomProfessionRef {
  const IdiomProfessionRef._({
    required this.professionId,
    required this.stance,
    required this.note,
  });

  factory IdiomProfessionRef.validated({
    required String professionId,
    IdiomUseStance stance = IdiomUseStance.common,
    String note = '',
  }) {
    return IdiomProfessionRef._(
      professionId: _requireTrimmed(professionId, 'professionId'),
      stance: stance,
      note: note.trim(),
    );
  }

  final String professionId;
  final IdiomUseStance stance;
  final String note;

  Map<String, Object?> toJson() => <String, Object?>{
    'professionId': professionId,
    'stance': stance.name,
    'note': note,
  };

  static IdiomProfessionRef fromJson(Map<String, Object?> json) =>
      IdiomProfessionRef.validated(
        professionId: json['professionId']! as String,
        stance: IdiomUseStance.fromName(json['stance'] as String?),
        note: json['note'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdiomProfessionRef &&
          other.professionId == professionId &&
          other.stance == stance &&
          other.note == note);

  @override
  int get hashCode => Object.hash(professionId, stance, note);

  @override
  String toString() => 'IdiomProfessionRef($professionId, ${stance.name})';
}

/// Rentang era tempat ungkapan lazim dipakai. Kronologi absolut tetap milik
/// sistem timeline; [fromMarker]/[toMarker] bebas, [sequence] rank opsional
/// (konvensi 111.26/27/30).
class IdiomEraRange {
  const IdiomEraRange._({
    required this.eraId,
    required this.label,
    required this.fromMarker,
    required this.toMarker,
    required this.sequence,
  });

  factory IdiomEraRange.validated({
    required String eraId,
    required String label,
    required String fromMarker,
    String? toMarker,
    int? sequence,
  }) {
    return IdiomEraRange._(
      eraId: _requireTrimmed(eraId, 'eraId'),
      label: _requireTrimmed(label, 'label'),
      fromMarker: _requireTrimmed(fromMarker, 'fromMarker'),
      toMarker: _optionalTrimmed(toMarker, 'toMarker'),
      sequence: sequence,
    );
  }

  final String eraId;
  final String label;
  final String fromMarker;

  /// Marker akhir; null selama era masih berjalan.
  final String? toMarker;
  final int? sequence;

  bool get isOngoing => toMarker == null;

  String describe() {
    final end = toMarker;
    return end == null
        ? '$fromMarker..ongoing ($eraId)'
        : '$fromMarker..$end ($eraId)';
  }

  /// Urutkan era berdasarkan sequence (null terakhir), lalu eraId.
  static int compare(IdiomEraRange a, IdiomEraRange b) {
    final sa = a.sequence;
    final sb = b.sequence;
    if (sa != null && sb != null && sa != sb) return sa.compareTo(sb);
    if (sa == null && sb != null) return 1;
    if (sa != null && sb == null) return -1;
    return a.eraId.compareTo(b.eraId);
  }

  /// Apakah [marker] (leksikografis, konvensi marker ter-zero-pad) jatuh di
  /// dalam rentang inklusif ini.
  bool coversMarker(String marker) {
    final m = marker.trim();
    if (m.compareTo(fromMarker) < 0) return false;
    final end = toMarker;
    if (end != null && m.compareTo(end) > 0) return false;
    return true;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'eraId': eraId,
    'label': label,
    'fromMarker': fromMarker,
    'toMarker': toMarker,
    'sequence': sequence,
  };

  static IdiomEraRange fromJson(Map<String, Object?> json) =>
      IdiomEraRange.validated(
        eraId: json['eraId']! as String,
        label: json['label']! as String,
        fromMarker: json['fromMarker']! as String,
        toMarker: json['toMarker'] as String?,
        sequence: json['sequence'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdiomEraRange &&
          other.eraId == eraId &&
          other.label == label &&
          other.fromMarker == fromMarker &&
          other.toMarker == toMarker &&
          other.sequence == sequence);

  @override
  int get hashCode => Object.hash(eraId, label, fromMarker, toMarker, sequence);

  @override
  String toString() => 'IdiomEraRange($eraId, ${describe()})';
}

/// Register yang dipakai pada satu konteks sosial (SocialContext 111.30).
class IdiomContextUsage {
  const IdiomContextUsage._({
    required this.context,
    required this.register,
    required this.note,
  });

  factory IdiomContextUsage.validated({
    required SocialContext context,
    required IdiomRegister register,
    String note = '',
  }) {
    return IdiomContextUsage._(
      context: context,
      register: register,
      note: note.trim(),
    );
  }

  final SocialContext context;
  final IdiomRegister register;
  final String note;

  Map<String, Object?> toJson() => <String, Object?>{
    'context': context.name,
    'register': register.name,
    'note': note,
  };

  static IdiomContextUsage fromJson(Map<String, Object?> json) =>
      IdiomContextUsage.validated(
        context: SocialContext.values.firstWhere(
          (c) => c.name == json['context'],
        ),
        register: IdiomRegister.fromName(json['register'] as String?),
        note: json['note'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdiomContextUsage &&
          other.context == context &&
          other.register == register &&
          other.note == note);

  @override
  int get hashCode => Object.hash(context, register, note);

  @override
  String toString() => 'IdiomContextUsage(${context.name}, ${register.name})';
}

/// Konteks kepemilikan/pemakaian lengkap untuk SATU ungkapan (kunci idiomId
/// menuju [IdiomRecord] 111.33).
class IdiomUsageProfile {
  const IdiomUsageProfile._({
    required this.idiomId,
    required this.regions,
    required this.cultures,
    required this.factions,
    required this.professions,
    required this.eras,
    required this.contexts,
    required this.defaultRegister,
    required this.note,
  });

  /// Membuat profil. [idiomId] wajib non-kosong; setiap koleksi boleh kosong
  /// (sengaja longgar — mirror semantik EncyclopediaScope 111.5 "kosong =
  /// tidak membatasi"). Guard: id unik per facet (toleran kasus/whitespace),
  /// factionId unik lintas role, satu SocialContext hanya satu register.
  factory IdiomUsageProfile.validated({
    required String idiomId,
    List<IdiomRegionRef> regions = const <IdiomRegionRef>[],
    List<IdiomCultureRef> cultures = const <IdiomCultureRef>[],
    List<IdiomFactionRef> factions = const <IdiomFactionRef>[],
    List<IdiomProfessionRef> professions = const <IdiomProfessionRef>[],
    List<IdiomEraRange> eras = const <IdiomEraRange>[],
    List<IdiomContextUsage> contexts = const <IdiomContextUsage>[],
    IdiomRegister defaultRegister = IdiomRegister.neutral,
    String note = '',
  }) {
    void requireUniqueKeys(Iterable<String> keys, String fieldName) {
      final seen = <String>{};
      for (final k in keys) {
        if (!seen.add(_normalizeKey(k))) {
          throw ArgumentError('duplicate $fieldName: $k');
        }
      }
    }

    requireUniqueKeys(regions.map((r) => r.regionId), 'regionId');
    requireUniqueKeys(cultures.map((c) => c.cultureId), 'cultureId');
    requireUniqueKeys(factions.map((f) => f.factionId), 'factionId');
    requireUniqueKeys(professions.map((p) => p.professionId), 'professionId');
    requireUniqueKeys(eras.map((e) => e.eraId), 'eraId');
    requireUniqueKeys(contexts.map((c) => c.context.name), 'usage context');
    return IdiomUsageProfile._(
      idiomId: _requireTrimmed(idiomId, 'idiomId'),
      regions: List<IdiomRegionRef>.unmodifiable(regions),
      cultures: List<IdiomCultureRef>.unmodifiable(cultures),
      factions: List<IdiomFactionRef>.unmodifiable(factions),
      professions: List<IdiomProfessionRef>.unmodifiable(professions),
      eras: List<IdiomEraRange>.unmodifiable(eras),
      contexts: List<IdiomContextUsage>.unmodifiable(contexts),
      defaultRegister: defaultRegister,
      note: note.trim(),
    );
  }

  final String idiomId;
  final List<IdiomRegionRef> regions;
  final List<IdiomCultureRef> cultures;
  final List<IdiomFactionRef> factions;
  final List<IdiomProfessionRef> professions;
  final List<IdiomEraRange> eras;
  final List<IdiomContextUsage> contexts;

  /// Register bila sebuah konteks tidak punya override eksplisit.
  final IdiomRegister defaultRegister;
  final String note;

  int get regionCount => regions.length;
  int get cultureCount => cultures.length;
  int get factionCount => factions.length;
  int get professionCount => professions.length;
  int get eraCount => eras.length;
  int get contextCount => contexts.length;

  /// true bila profil declaring facet apa pun (lookup membatasi); false =
  /// profil longgar, ungkapan dianggap bebas dipakai.
  bool get hasAnyFacet =>
      regions.isNotEmpty ||
      cultures.isNotEmpty ||
      factions.isNotEmpty ||
      professions.isNotEmpty ||
      eras.isNotEmpty ||
      contexts.isNotEmpty;

  bool get hasAvoiders => avoidingFacets.isNotEmpty;

  // --- lookup per facet (toleran whitespace, kasus-toleran) --------------

  IdiomRegionRef? regionFor(String regionId) {
    final needle = _normalizeKey(regionId);
    if (needle.isEmpty) return null;
    for (final r in regions) {
      if (_normalizeKey(r.regionId) == needle) return r;
    }
    return null;
  }

  IdiomCultureRef? cultureFor(String cultureId) {
    final needle = _normalizeKey(cultureId);
    if (needle.isEmpty) return null;
    for (final c in cultures) {
      if (_normalizeKey(c.cultureId) == needle) return c;
    }
    return null;
  }

  IdiomFactionRef? factionFor(String factionId) {
    final needle = _normalizeKey(factionId);
    if (needle.isEmpty) return null;
    for (final f in factions) {
      if (_normalizeKey(f.factionId) == needle) return f;
    }
    return null;
  }

  IdiomProfessionRef? professionFor(String professionId) {
    final needle = _normalizeKey(professionId);
    if (needle.isEmpty) return null;
    for (final p in professions) {
      if (_normalizeKey(p.professionId) == needle) return p;
    }
    return null;
  }

  IdiomEraRange? eraFor(String eraId) {
    final needle = _normalizeKey(eraId);
    if (needle.isEmpty) return null;
    for (final e in eras) {
      if (_normalizeKey(e.eraId) == needle) return e;
    }
    return null;
  }

  IdiomContextUsage? contextUsageFor(SocialContext context) {
    for (final c in contexts) {
      if (c.context == context) return c;
    }
    return null;
  }

  // --- predikat pemakaian -------------------------------------------------

  /// Kosong = bebas; terisi = hanya pihak berstance bukan `avoided` memakai.
  bool usedInRegion(String regionId) =>
      _facetUsed(regionId, _entries(IdiomOwnershipFacet.region));

  bool avoidedByRegion(String regionId) =>
      _facetAvoided(regionId, _entries(IdiomOwnershipFacet.region));

  bool usedByCulture(String cultureId) =>
      _facetUsed(cultureId, _entries(IdiomOwnershipFacet.culture));

  bool avoidedByCulture(String cultureId) =>
      _facetAvoided(cultureId, _entries(IdiomOwnershipFacet.culture));

  bool usedWithFaction(String factionId) =>
      _facetUsed(factionId, _entries(IdiomOwnershipFacet.faction));

  bool avoidedByFaction(String factionId) =>
      _facetAvoided(factionId, _entries(IdiomOwnershipFacet.faction));

  bool usedByProfession(String professionId) =>
      _facetUsed(professionId, _entries(IdiomOwnershipFacet.profession));

  bool avoidedByProfession(String professionId) =>
      _facetAvoided(professionId, _entries(IdiomOwnershipFacet.profession));

  List<(String, IdiomUseStance)> _entries(IdiomOwnershipFacet facet) {
    return switch (facet) {
      IdiomOwnershipFacet.region =>
        regions.map((r) => (r.regionId, r.stance)).toList(growable: false),
      IdiomOwnershipFacet.culture =>
        cultures.map((c) => (c.cultureId, c.stance)).toList(growable: false),
      IdiomOwnershipFacet.faction =>
        factions.map((f) => (f.factionId, f.stance)).toList(growable: false),
      IdiomOwnershipFacet.profession =>
        professions
            .map((p) => (p.professionId, p.stance))
            .toList(growable: false),
    };
  }

  bool _facetUsed(String id, List<(String, IdiomUseStance)> entries) {
    if (entries.isEmpty) return true;
    final needle = _normalizeKey(id);
    if (needle.isEmpty) return false;
    for (final (key, stance) in entries) {
      if (_normalizeKey(key) == needle) return !stance.isAvoidance;
    }
    return false;
  }

  bool _facetAvoided(String id, List<(String, IdiomUseStance)> entries) {
    final needle = _normalizeKey(id);
    if (needle.isEmpty) return false;
    for (final (key, stance) in entries) {
      if (_normalizeKey(key) == needle) return stance.isAvoidance;
    }
    return false;
  }

  ScopeFactionRole? roleForFaction(String factionId) =>
      factionFor(factionId)?.role;

  List<String> factionRoleIds(ScopeFactionRole role) =>
      List<String>.unmodifiable(
        factions.where((f) => f.role == role).map((f) => f.factionId),
      );

  /// Register efektif untuk [context]: override eksplisit, lalu default.
  IdiomRegister registerFor(SocialContext context) =>
      contextUsageFor(context)?.register ?? defaultRegister;

  /// Apakah ungkapan lazim dipakai pada [context] (contexts kosong = bebas).
  bool usableIn(SocialContext context) =>
      contexts.isEmpty || contextUsageFor(context) != null;

  /// Apakah ungkapan aktif pada [marker] (eras kosong = selalu aktif).
  bool activeAtMarker(String marker) {
    if (eras.isEmpty) return true;
    return eras.any((e) => e.coversMarker(marker));
  }

  /// Stance pihak pada facet tertentu (null = tidak dicatat).
  IdiomUseStance? effectiveStanceFor(
    IdiomOwnershipFacet facet,
    String ownerId,
  ) {
    return switch (facet) {
      IdiomOwnershipFacet.region => regionFor(ownerId)?.stance,
      IdiomOwnershipFacet.culture => cultureFor(ownerId)?.stance,
      IdiomOwnershipFacet.faction => factionFor(ownerId)?.stance,
      IdiomOwnershipFacet.profession => professionFor(ownerId)?.stance,
    };
  }

  /// Daftar `facet:id` dari semua pihak yang menghindari ungkapan,
  /// terurut deterministik.
  List<String> get avoidingFacets {
    final out = <String>[];
    for (final r in regions) {
      if (r.stance.isAvoidance) out.add('region:${r.regionId}');
    }
    for (final c in cultures) {
      if (c.stance.isAvoidance) out.add('culture:${c.cultureId}');
    }
    for (final f in factions) {
      if (f.stance.isAvoidance) out.add('faction:${f.factionId}');
    }
    for (final p in professions) {
      if (p.stance.isAvoidance) out.add('profession:${p.professionId}');
    }
    out.sort();
    return List<String>.unmodifiable(out);
  }

  List<String> _idsWithStances(
    Iterable<(String, IdiomUseStance)> entries,
    bool Function(IdiomUseStance) test,
  ) {
    final out = <String>[
      for (final (id, stance) in entries)
        if (test(stance)) id,
    ]..sort();
    return List<String>.unmodifiable(out);
  }

  List<String> get primaryRegionIds => _idsWithStances(
    _entries(IdiomOwnershipFacet.region),
    (s) => s == IdiomUseStance.primary,
  );

  List<String> get avoidedCultureIds => _idsWithStances(
    _entries(IdiomOwnershipFacet.culture),
    (s) => s.isAvoidance,
  );

  List<String> get primaryProfessionIds => _idsWithStances(
    _entries(IdiomOwnershipFacet.profession),
    (s) => s == IdiomUseStance.primary,
  );

  List<String> get allRegionIds => List<String>.unmodifiable(
    (regions.map((r) => r.regionId).toSet()).toList()..sort(),
  );

  List<String> get allCultureIds => List<String>.unmodifiable(
    (cultures.map((c) => c.cultureId).toSet()).toList()..sort(),
  );

  List<String> get allProfessionIds => List<String>.unmodifiable(
    (professions.map((p) => p.professionId).toSet()).toList()..sort(),
  );

  List<String> get eraIds => List<String>.unmodifiable(
    (eras.map((e) => e.eraId).toSet()).toList()..sort(),
  );

  Set<SocialContext> get usedContexts => contexts.map((c) => c.context).toSet();

  Map<String, Object?> toJson() => <String, Object?>{
    'idiomId': idiomId,
    'regions': regions.map((r) => r.toJson()).toList(),
    'cultures': cultures.map((c) => c.toJson()).toList(),
    'factions': factions.map((f) => f.toJson()).toList(),
    'professions': professions.map((p) => p.toJson()).toList(),
    'eras': eras.map((e) => e.toJson()).toList(),
    'contexts': contexts.map((c) => c.toJson()).toList(),
    'defaultRegister': defaultRegister.name,
    'note': note,
  };

  static IdiomUsageProfile fromJson(
    Map<String, Object?> json,
  ) => IdiomUsageProfile.validated(
    idiomId: json['idiomId']! as String,
    regions: (json['regions'] as List<Object?>? ?? const <Object?>[])
        .map((e) => IdiomRegionRef.fromJson((e! as Map<String, Object?>)))
        .toList(),
    cultures: (json['cultures'] as List<Object?>? ?? const <Object?>[])
        .map((e) => IdiomCultureRef.fromJson((e! as Map<String, Object?>)))
        .toList(),
    factions: (json['factions'] as List<Object?>? ?? const <Object?>[])
        .map((e) => IdiomFactionRef.fromJson((e! as Map<String, Object?>)))
        .toList(),
    professions: (json['professions'] as List<Object?>? ?? const <Object?>[])
        .map((e) => IdiomProfessionRef.fromJson((e! as Map<String, Object?>)))
        .toList(),
    eras: (json['eras'] as List<Object?>? ?? const <Object?>[])
        .map((e) => IdiomEraRange.fromJson((e! as Map<String, Object?>)))
        .toList(),
    contexts: (json['contexts'] as List<Object?>? ?? const <Object?>[])
        .map((e) => IdiomContextUsage.fromJson((e! as Map<String, Object?>)))
        .toList(),
    defaultRegister: IdiomRegister.fromName(json['defaultRegister'] as String?),
    note: json['note'] as String? ?? '',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdiomUsageProfile &&
          other.idiomId == idiomId &&
          other.defaultRegister == defaultRegister &&
          other.note == note &&
          other.regions.length == regions.length &&
          other.cultures.length == cultures.length &&
          other.factions.length == factions.length &&
          other.professions.length == professions.length &&
          other.eras.length == eras.length &&
          other.contexts.length == contexts.length &&
          List.generate(
            regions.length,
            (i) => other.regions[i] == regions[i],
          ).every((ok) => ok) &&
          List.generate(
            cultures.length,
            (i) => other.cultures[i] == cultures[i],
          ).every((ok) => ok) &&
          List.generate(
            factions.length,
            (i) => other.factions[i] == factions[i],
          ).every((ok) => ok) &&
          List.generate(
            professions.length,
            (i) => other.professions[i] == professions[i],
          ).every((ok) => ok) &&
          List.generate(
            eras.length,
            (i) => other.eras[i] == eras[i],
          ).every((ok) => ok) &&
          List.generate(
            contexts.length,
            (i) => other.contexts[i] == contexts[i],
          ).every((ok) => ok));

  @override
  int get hashCode => Object.hash(
    idiomId,
    defaultRegister,
    note,
    regions.length,
    cultures.length,
    factions.length,
    professions.length,
    eras.length,
    contexts.length,
  );

  @override
  String toString() => 'IdiomUsageProfile($idiomId)';
}

/// Katalog profil pemakaian lintas ungkapan.
class IdiomUsageCatalog {
  const IdiomUsageCatalog._(this._profiles);

  /// Katalog kosong.
  factory IdiomUsageCatalog.empty() =>
      const IdiomUsageCatalog._(<IdiomUsageProfile>[]);

  /// Membangun katalog; [IdiomUsageProfile.idiomId] wajib unik lintas profil.
  factory IdiomUsageCatalog.withProfiles(List<IdiomUsageProfile> profiles) {
    final seen = <String>{};
    for (final p in profiles) {
      if (!seen.add(p.idiomId)) {
        throw ArgumentError('duplicate idiomId: ${p.idiomId}');
      }
    }
    final sorted = List<IdiomUsageProfile>.of(profiles)
      ..sort((a, b) => a.idiomId.compareTo(b.idiomId));
    return IdiomUsageCatalog._(List<IdiomUsageProfile>.unmodifiable(sorted));
  }

  final List<IdiomUsageProfile> _profiles;

  List<IdiomUsageProfile> get profiles => _profiles;

  int get profileCount => _profiles.length;

  List<String> get idiomIds =>
      List<String>.unmodifiable(_profiles.map((p) => p.idiomId));

  /// Lookup profil per idiomId, toleran whitespace.
  IdiomUsageProfile? profileFor(String idiomId) {
    final needle = idiomId.trim();
    if (needle.isEmpty) return null;
    for (final p in _profiles) {
      if (p.idiomId == needle) return p;
    }
    return null;
  }

  List<String> get regionIds => _aggregate((p) => p.allRegionIds);
  List<String> get cultureIds => _aggregate((p) => p.allCultureIds);
  List<String> get professionIds => _aggregate((p) => p.allProfessionIds);

  List<String> get factionIds => List<String>.unmodifiable(
    (_profiles.expand((p) => p.factions.map((f) => f.factionId)).toSet())
        .toList()
      ..sort(),
  );

  List<String> get eraIds => _aggregate((p) => p.eraIds);

  List<String> _aggregate(List<String> Function(IdiomUsageProfile) pick) =>
      List<String>.unmodifiable(
        (_profiles.expand(pick).toSet()).toList()..sort(),
      );

  /// Id pihak pada facet yang MEMAKAI (stance bukan avoided), terurut dedup.
  List<String> ownerIds(IdiomOwnershipFacet facet) => List<String>.unmodifiable(
    (_profiles
            .expand((p) => p.entriesFor(facet).where((e) => !e.$2.isAvoidance))
            .map((e) => e.$1)
            .toSet())
        .toList()
      ..sort(),
  );

  List<String> avoiderIds(IdiomOwnershipFacet facet) =>
      List<String>.unmodifiable(
        (_profiles
                .expand(
                  (p) => p.entriesFor(facet).where((e) => e.$2.isAvoidance),
                )
                .map((e) => e.$1)
                .toSet())
            .toList()
          ..sort(),
      );

  /// Reverse index: ungkapan yang lazim dipakai di wilayah [regionId].
  List<String> idiomsUsedInRegion(String regionId) =>
      _matching((p) => p.usedInRegion(regionId));

  List<String> idiomsAvoidedInRegion(String regionId) =>
      _matching((p) => p.avoidedByRegion(regionId));

  List<String> idiomsUsedByCulture(String cultureId) =>
      _matching((p) => p.usedByCulture(cultureId));

  List<String> idiomsAvoidedByCulture(String cultureId) =>
      _matching((p) => p.avoidedByCulture(cultureId));

  List<String> idiomsUsedWithFaction(String factionId) =>
      _matching((p) => p.usedWithFaction(factionId));

  List<String> idiomsAvoidedByFaction(String factionId) =>
      _matching((p) => p.avoidedByFaction(factionId));

  List<String> idiomsUsedByProfession(String professionId) =>
      _matching((p) => p.usedByProfession(professionId));

  List<String> idiomsAvoidedByProfession(String professionId) =>
      _matching((p) => p.avoidedByProfession(professionId));

  List<String> _matching(bool Function(IdiomUsageProfile) test) =>
      List<String>.unmodifiable(
        _profiles.where(test).map((p) => p.idiomId).toList()..sort(),
      );

  /// Jumlah entri profil yang memakai [context] (hanya contexts non-kosong
  /// yang dihitung — profil longgar tidak mengklaim konteks).
  Map<SocialContext, int> contextCounts() {
    final out = <SocialContext, int>{};
    for (final p in _profiles) {
      for (final c in p.contexts) {
        out[c.context] = (out[c.context] ?? 0) + 1;
      }
    }
    return Map<SocialContext, int>.unmodifiable(out);
  }

  /// Semua register yang muncul di katalog (override konteks + default).
  List<IdiomRegister> registersInUse() {
    final out = <IdiomRegister>{};
    for (final p in _profiles) {
      out.add(p.defaultRegister);
      for (final c in p.contexts) {
        out.add(c.register);
      }
    }
    final list = out.toList()..sort((a, b) => a.index.compareTo(b.index));
    return List<IdiomRegister>.unmodifiable(list);
  }

  /// Ungkapan dengan register efektif tertinggi (default atau override
  /// kontekstual); tie-break idiomId ascending; null saat katalog kosong.
  String? mostFormalIdiomId() {
    String? best;
    var bestFormality = -1;
    for (final p in _profiles) {
      var local = p.defaultRegister.formality;
      for (final c in p.contexts) {
        if (c.register.formality > local) local = c.register.formality;
      }
      if (local > bestFormality ||
          (local == bestFormality &&
              best != null &&
              p.idiomId.compareTo(best) < 0)) {
        bestFormality = local;
        best = p.idiomId;
      }
    }
    return best;
  }

  /// Total rujukan facet di seluruh profil (region+culture+faction+
  /// profession+era+context).
  int get totalReferrantCount => _profiles.fold(
    0,
    (sum, p) =>
        sum +
        p.regionCount +
        p.cultureCount +
        p.factionCount +
        p.professionCount +
        p.eraCount +
        p.contextCount,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'profiles': _profiles.map((p) => p.toJson()).toList(),
  };

  static IdiomUsageCatalog fromJson(Map<String, Object?> json) =>
      IdiomUsageCatalog.withProfiles(
        (json['profiles'] as List<Object?>? ?? const <Object?>[])
            .map(
              (e) => IdiomUsageProfile.fromJson((e! as Map<String, Object?>)),
            )
            .toList(),
      );

  @override
  String toString() => 'IdiomUsageCatalog($profileCount profiles)';
}

extension IdiomUsageProfileEntries on IdiomUsageProfile {
  /// Pasangan (id, stance) seragam untuk satu facet — dipakai agregat
  /// katalog agar pertanyaan kepemilikan konsisten lintas facet.
  List<(String, IdiomUseStance)> entriesFor(IdiomOwnershipFacet facet) {
    return switch (facet) {
      IdiomOwnershipFacet.region =>
        regions.map((r) => (r.regionId, r.stance)).toList(growable: false),
      IdiomOwnershipFacet.culture =>
        cultures.map((c) => (c.cultureId, c.stance)).toList(growable: false),
      IdiomOwnershipFacet.faction =>
        factions.map((f) => (f.factionId, f.stance)).toList(growable: false),
      IdiomOwnershipFacet.profession =>
        professions
            .map((p) => (p.professionId, p.stance))
            .toList(growable: false),
    };
  }
}

/// Query deterministik atas [IdiomUsageCatalog]; semua filter di-AND-kan.
/// Profil longgar (facet kosong) lolos predikat apa pun, mirror semantik
/// 111.5.
class IdiomUsageFilter {
  const IdiomUsageFilter({
    this.idiomId,
    this.regionId,
    this.cultureId,
    this.factionId,
    this.professionId,
    this.context,
    this.atMarker,
    this.minFormality,
    this.maxFormality,
    this.facet,
    this.requireAvoidance = false,
  });

  final String? idiomId;
  final String? regionId;
  final String? cultureId;
  final String? factionId;
  final String? professionId;
  final SocialContext? context;

  /// Marker era; profil harus aktif pada marker ini (eras kosong = lolos).
  final String? atMarker;
  final IdiomRegister? minFormality;
  final IdiomRegister? maxFormality;

  /// Bersama [requireAvoidance]: facet mana yang harus memuat penghindaran.
  final IdiomOwnershipFacet? facet;

  /// true = hanya profil yang punya pihak menghindari (pada [facet] bila
  /// diberikan, atau facet apa pun bila tidak).
  final bool requireAvoidance;

  bool get isEmpty =>
      _blank(idiomId) &&
      _blank(regionId) &&
      _blank(cultureId) &&
      _blank(factionId) &&
      _blank(professionId) &&
      context == null &&
      _blank(atMarker) &&
      minFormality == null &&
      maxFormality == null &&
      !requireAvoidance;

  static bool _blank(String? v) => v == null || v.trim().isEmpty;

  List<IdiomUsageProfile> apply(IdiomUsageCatalog catalog) {
    final hits = catalog.profiles.where((p) {
      if (!_blank(idiomId) && p.idiomId != idiomId!.trim()) return false;
      if (!_blank(regionId) && !p.usedInRegion(regionId!)) return false;
      if (!_blank(cultureId) && !p.usedByCulture(cultureId!)) return false;
      if (!_blank(factionId) && !p.usedWithFaction(factionId!)) return false;
      if (!_blank(professionId) && !p.usedByProfession(professionId!)) {
        return false;
      }
      if (context != null && !p.usableIn(context!)) return false;
      if (!_blank(atMarker) && !p.activeAtMarker(atMarker!)) return false;
      if (minFormality != null || maxFormality != null) {
        final effective = context != null
            ? p.registerFor(context!)
            : _maxRegisterOf(p);
        if (minFormality != null && !effective.atLeast(minFormality!)) {
          return false;
        }
        if (maxFormality != null && !maxFormality!.atLeast(effective)) {
          return false;
        }
      }
      if (requireAvoidance) {
        if (facet != null) {
          final anyAvoided = p.entriesFor(facet!).any((e) => e.$2.isAvoidance);
          if (!anyAvoided) return false;
        } else if (!p.hasAvoiders) {
          return false;
        }
      }
      return true;
    }).toList();
    return List<IdiomUsageProfile>.unmodifiable(hits);
  }

  static IdiomRegister _maxRegisterOf(IdiomUsageProfile p) {
    var best = p.defaultRegister;
    for (final c in p.contexts) {
      if (c.register.moreFormalThan(best)) best = c.register;
    }
    return best;
  }

  String describe() {
    if (isEmpty) return 'IdiomUsageFilter(semua profil)';
    final parts = <String>[];
    if (!_blank(idiomId)) parts.add('idiom=$idiomId');
    if (!_blank(regionId)) parts.add('region=$regionId');
    if (!_blank(cultureId)) parts.add('culture=$cultureId');
    if (!_blank(factionId)) parts.add('faction=$factionId');
    if (!_blank(professionId)) parts.add('profession=$professionId');
    if (context != null) parts.add('context=${context!.name}');
    if (!_blank(atMarker)) parts.add('marker=$atMarker');
    if (minFormality != null) parts.add('minRegister=${minFormality!.name}');
    if (maxFormality != null) parts.add('maxRegister=${maxFormality!.name}');
    if (facet != null) parts.add('facet=${facet!.name}');
    if (requireAvoidance) parts.add('avoided');
    return 'IdiomUsageFilter(${parts.join(', ')})';
  }
}
