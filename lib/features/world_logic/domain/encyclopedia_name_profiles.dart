// Sprint 111.30 - Cultural Name Profiles (domain-only).
//
// Mendefinisikan pola nama berdasarkan bahasa, budaya, era, kelas/konteks
// sosial, gelar, tipe entitas, dan aturan afiks (prefiks/sufiks) untuk satu
// budaya fiksi, sebagai kontrak domain murni.
//
// Tujuh acceptance canonical sprint_111.json dipetakan:
// - culture             -> CulturalNameProfile.cultureId
// - language            -> CulturalNameProfile.languageId (rujuk konlang 109.17)
// - era                 -> NameEra (marker cerita + sequence rank opsional,
//                          konvensi yang sama dengan 111.26/111.27)
// - social_context      -> SocialContext enum + defaultContext profil
// - titles              -> NameTitle (posisi pre/post, per tipe + konteks)
// - entity_types        -> NameEntityType enum + whitelist profil (guard
//                          subset untuk gelar dan afiks)
// - prefix_suffix_rules -> NameAffixRule + decorateName deterministik
//
// Tanpa persistence, UI, locale, jaringan, wall-clock, atau random.
// D-SCHEMA-01 tetap OPEN; modul ini mirror domain untuk Drift mendatang.

library;

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

/// Tipe entitas dunia yang bisa dinamai oleh sebuah profil budaya.
enum NameEntityType {
  /// Orang perorangan.
  person,

  /// Tempat/geografi bernama.
  place,

  /// Keluarga/dinasti.
  family,

  /// Dewa atau makhluk sakral.
  deity,

  /// Makhluk hidup non-sakral.
  creature,

  /// Artefak/benda bernama.
  artifact,

  /// Organisasi/institusi.
  organization,
}

/// Konteks sosial pemakaian nama — kapan sebuah bentuk nama lazim dipakai.
enum SocialContext {
  /// Pemakaian sehari-hari.
  everyday,

  /// Situasi resmi/birokratis.
  formal,

  /// Upacara dan peristiwa seremonial.
  ceremonial,

  /// Konteks sakral/keagamaan.
  sacred,

  /// Nama rahasia/tersembunyi.
  secret,
}

/// Posisi gelar relatif terhadap nama inti.
enum TitlePosition {
  /// Gelar sebelum nama (mis. "Lady Anya").
  preName,

  /// Gelar sesudah nama (mis. "Anya the Wise").
  postName,
}

/// Jenis afiks pada aturan prefiks/sufiks nama.
enum NameAffixKind {
  /// Ditambahkan di depan nama inti.
  prefix,

  /// Ditambahkan di belakang nama inti.
  suffix,
}

/// Rentang era cerita tempat sebuah profil nama berlaku. Kronologi absolut
/// tetap milik sistem timeline; [fromMarker]/[toMarker] adalah marker cerita
/// bebas dan [sequence] adalah rank kronologis opsional (konvensi 111.26/27).
class NameEra {
  const NameEra._({
    required this.eraId,
    required this.label,
    required this.fromMarker,
    required this.toMarker,
    required this.sequence,
  });

  /// Membuat era tervalidasi: [eraId], [label], dan [fromMarker] dipangkas
  /// dan wajib tidak kosong; [toMarker] opsional (null = era masih berjalan)
  /// tetapi tidak boleh blank; [sequence] rank opsional tanpa constraint.
  factory NameEra.validated({
    required String eraId,
    required String label,
    required String fromMarker,
    String? toMarker,
    int? sequence,
  }) {
    return NameEra._(
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

  /// Rank kronologis opsional dari sistem timeline.
  final int? sequence;

  bool get isOngoing => toMarker == null;

  /// Teks ringkas rentang era.
  String describe() {
    final end = toMarker;
    return end == null
        ? '$fromMarker..ongoing ($eraId)'
        : '$fromMarker..$end ($eraId)';
  }

  /// Urutkan era ber-dasarkan sequence (null terakhir), lalu eraId.
  static int compare(NameEra a, NameEra b) {
    final sa = a.sequence;
    final sb = b.sequence;
    if (sa != null && sb != null && sa != sb) return sa.compareTo(sb);
    if (sa == null && sb != null) return 1;
    if (sa != null && sb == null) return -1;
    return a.eraId.compareTo(b.eraId);
  }

  /// Apakah [marker] (bandingkan leksikografis, konvensi marker berurut
  /// seperti `m05`) jatuh di dalam rentang era inklusif ini.
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

  static NameEra fromJson(Map<String, Object?> json) => NameEra.validated(
    eraId: json['eraId']! as String,
    label: json['label']! as String,
    fromMarker: json['fromMarker']! as String,
    toMarker: json['toMarker'] as String?,
    sequence: json['sequence'] as int?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NameEra &&
          other.eraId == eraId &&
          other.label == label &&
          other.fromMarker == fromMarker &&
          other.toMarker == toMarker &&
          other.sequence == sequence;

  @override
  int get hashCode => Object.hash(eraId, label, fromMarker, toMarker, sequence);
}

/// Satu gelar bernama yang dapat dirangkaikan ke nama entitas tertentu pada
/// konteks sosial tertentu.
class NameTitle {
  const NameTitle._({
    required this.id,
    required this.text,
    required this.position,
    required this._entityTypes,
    required this._contexts,
  });

  /// Membuat gelar tervalidasi: [id] dan [text] dipangkas wajib tidak kosong;
  /// [entityTypes] dan [contexts] wajib tidak kosong dan dinormalisasi ke
  /// urutan canonical enum tanpa duplikat.
  factory NameTitle.validated({
    required String id,
    required String text,
    required TitlePosition position,
    required Set<NameEntityType> entityTypes,
    required Set<SocialContext> contexts,
  }) {
    if (entityTypes.isEmpty) {
      throw ArgumentError('entityTypes must be non-empty');
    }
    if (contexts.isEmpty) {
      throw ArgumentError('contexts must be non-empty');
    }
    return NameTitle._(
      id: _requireTrimmed(id, 'id'),
      text: _requireTrimmed(text, 'text'),
      position: position,
      entityTypes: List.unmodifiable(<NameEntityType>[
        for (final t in NameEntityType.values)
          if (entityTypes.contains(t)) t,
      ]),
      contexts: List.unmodifiable(<SocialContext>[
        for (final c in SocialContext.values)
          if (contexts.contains(c)) c,
      ]),
    );
  }

  final String id;

  /// Teks gelar persis sebagaimana dipakai (tanpa spasi tepi).
  final String text;
  final TitlePosition position;

  final List<NameEntityType> _entityTypes;
  final List<SocialContext> _contexts;

  /// Tipe entitas yang memakai gelar ini, urutan canonical.
  List<NameEntityType> get entityTypes => _entityTypes;

  /// Konteks sosial pemakaian gelar ini, urutan canonical.
  List<SocialContext> get contexts => _contexts;

  /// Apakah gelar ini berlaku untuk kombinasi [entityType] + [context].
  bool appliesTo(NameEntityType entityType, SocialContext context) =>
      _entityTypes.contains(entityType) && _contexts.contains(context);

  /// Rangkaikan gelar pada [name] sesuai posisinya.
  String applyTo(String name) =>
      position == TitlePosition.preName ? '$text $name' : '$name $text';

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'text': text,
    'position': position.name,
    'entityTypes': <Object?>[for (final t in _entityTypes) t.name],
    'contexts': <Object?>[for (final c in _contexts) c.name],
  };

  static NameTitle fromJson(Map<String, Object?> json) => NameTitle.validated(
    id: json['id']! as String,
    text: json['text']! as String,
    position: TitlePosition.values.firstWhere(
      (p) => p.name == json['position'],
    ),
    entityTypes: <NameEntityType>{
      for (final raw in (json['entityTypes']! as List<Object?>))
        NameEntityType.values.firstWhere((t) => t.name == raw),
    },
    contexts: <SocialContext>{
      for (final raw in (json['contexts']! as List<Object?>))
        SocialContext.values.firstWhere((c) => c.name == raw),
    },
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NameTitle &&
          other.id == id &&
          other.text == text &&
          other.position == position &&
          other._entityTypes.length == _entityTypes.length &&
          other._entityTypes.every(_entityTypes.contains) &&
          other._contexts.length == _contexts.length &&
          other._contexts.every(_contexts.contains);

  @override
  int get hashCode => Object.hash(
    id,
    text,
    position,
    Object.hashAll(_entityTypes),
    Object.hashAll(_contexts),
  );
}

/// Satu aturan prefiks atau sufiks yang dapat ditempelkan pada nama inti.
class NameAffixRule {
  const NameAffixRule._({
    required this.id,
    required this.kind,
    required this.text,
    required this._entityTypes,
    required this._contexts,
    required this.optional,
  });

  /// Membuat aturan afiks tervalidasi: [id] dan [text] dipangkas wajib tidak
  /// kosong; [entityTypes] dan [contexts] wajib tidak kosong dan
  /// dinormalisasi ke urutan canonical; [optional] menandai afiks yang
  /// boleh dilewati oleh pemakai (default false).
  factory NameAffixRule.validated({
    required String id,
    required NameAffixKind kind,
    required String text,
    required Set<NameEntityType> entityTypes,
    required Set<SocialContext> contexts,
    bool optional = false,
  }) {
    if (entityTypes.isEmpty) {
      throw ArgumentError('entityTypes must be non-empty');
    }
    if (contexts.isEmpty) {
      throw ArgumentError('contexts must be non-empty');
    }
    return NameAffixRule._(
      id: _requireTrimmed(id, 'id'),
      kind: kind,
      text: _requireTrimmed(text, 'text'),
      entityTypes: List.unmodifiable(<NameEntityType>[
        for (final t in NameEntityType.values)
          if (entityTypes.contains(t)) t,
      ]),
      contexts: List.unmodifiable(<SocialContext>[
        for (final c in SocialContext.values)
          if (contexts.contains(c)) c,
      ]),
      optional: optional,
    );
  }

  final String id;
  final NameAffixKind kind;

  /// Bentuk afiks persis (tanpa spasi; perlekatan langsung ke nama inti).
  final String text;

  final List<NameEntityType> _entityTypes;
  final List<SocialContext> _contexts;

  /// Tipe entitas sasaran afiks ini, urutan canonical.
  List<NameEntityType> get entityTypes => _entityTypes;

  /// Konteks sosial pemakaian afiks ini, urutan canonical.
  List<SocialContext> get contexts => _contexts;

  /// True bila afiks opsional (boleh dilewati saat pembentukan nama).
  final bool optional;

  /// Apakah aturan ini berlaku untuk kombinasi [entityType] + [context].
  bool appliesTo(NameEntityType entityType, SocialContext context) =>
      _entityTypes.contains(entityType) && _contexts.contains(context);

  /// Tempelkan afiks pada [name] sesuai jenisnya.
  String attachTo(String name) =>
      kind == NameAffixKind.prefix ? '$text$name' : '$name$text';

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'kind': kind.name,
    'text': text,
    'entityTypes': <Object?>[for (final t in _entityTypes) t.name],
    'contexts': <Object?>[for (final c in _contexts) c.name],
    'optional': optional,
  };

  static NameAffixRule fromJson(Map<String, Object?> json) =>
      NameAffixRule.validated(
        id: json['id']! as String,
        kind: NameAffixKind.values.firstWhere((k) => k.name == json['kind']),
        text: json['text']! as String,
        entityTypes: <NameEntityType>{
          for (final raw in (json['entityTypes']! as List<Object?>))
            NameEntityType.values.firstWhere((t) => t.name == raw),
        },
        contexts: <SocialContext>{
          for (final raw in (json['contexts']! as List<Object?>))
            SocialContext.values.firstWhere((c) => c.name == raw),
        },
        optional: json['optional'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NameAffixRule &&
          other.id == id &&
          other.kind == kind &&
          other.text == text &&
          other.optional == optional &&
          other._entityTypes.length == _entityTypes.length &&
          other._entityTypes.every(_entityTypes.contains) &&
          other._contexts.length == _contexts.length &&
          other._contexts.every(_contexts.contains);

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    text,
    optional,
    Object.hashAll(_entityTypes),
    Object.hashAll(_contexts),
  );
}

/// Profil nama budaya lengkap: satu pasangan budaya+bahasa, era berlaku,
/// whitelist tipe entitas, konteks sosial default, gelar, dan aturan afiks.
class CulturalNameProfile {
  const CulturalNameProfile._({
    required this.profileId,
    required this.cultureId,
    required this.languageId,
    required this.era,
    required this._entityTypes,
    required this.defaultContext,
    required this._titles,
    required this._affixRules,
  });

  /// Membangun profil tervalidasi dengan integritas referensial:
  /// [profileId]/[cultureId]/[languageId] non-kosong; whitelist [entityTypes]
  /// minimal satu tipe (dinormalisasi canonical); setiap gelar dan aturan
  /// afiks wajib memakai tipe yang termasuk whitelist; id gelar dan id afiks
  /// wajib unik dalam koleksinya masing-masing. [era] opsional — profil tanpa
  /// era berlaku lintas waktu. Melanggar = [ArgumentError].
  factory CulturalNameProfile.validated({
    required String profileId,
    required String cultureId,
    required String languageId,
    NameEra? era,
    required Set<NameEntityType> entityTypes,
    SocialContext defaultContext = SocialContext.everyday,
    List<NameTitle> titles = const <NameTitle>[],
    List<NameAffixRule> affixRules = const <NameAffixRule>[],
  }) {
    if (entityTypes.isEmpty) {
      throw ArgumentError('at least one entity type is required');
    }
    final whitelist = <NameEntityType>[
      for (final t in NameEntityType.values)
        if (entityTypes.contains(t)) t,
    ];
    final allowed = whitelist.toSet();
    final seenTitleIds = <String>{};
    for (final t in titles) {
      if (!seenTitleIds.add(t.id)) {
        throw ArgumentError('duplicate title id: ${t.id}');
      }
      for (final type in t.entityTypes) {
        if (!allowed.contains(type)) {
          throw ArgumentError(
            'title ${t.id} uses type $type outside the profile whitelist',
          );
        }
      }
    }
    final seenAffixIds = <String>{};
    for (final r in affixRules) {
      if (!seenAffixIds.add(r.id)) {
        throw ArgumentError('duplicate affix rule id: ${r.id}');
      }
      for (final type in r.entityTypes) {
        if (!allowed.contains(type)) {
          throw ArgumentError(
            'affix rule ${r.id} uses type $type outside the profile whitelist',
          );
        }
      }
    }
    return CulturalNameProfile._(
      profileId: _requireTrimmed(profileId, 'profileId'),
      cultureId: _requireTrimmed(cultureId, 'cultureId'),
      languageId: _requireTrimmed(languageId, 'languageId'),
      era: era,
      entityTypes: List.unmodifiable(whitelist),
      defaultContext: defaultContext,
      titles: List.unmodifiable(titles),
      affixRules: List.unmodifiable(affixRules),
    );
  }

  final String profileId;

  /// Id budaya pemilik profil ini.
  final String cultureId;

  /// Id bahasa (konlang) tempat nama-nama ini berakar.
  final String languageId;

  /// Era berlaku; null berarti lintas era.
  final NameEra? era;

  final List<NameEntityType> _entityTypes;
  final SocialContext defaultContext;
  final List<NameTitle> _titles;
  final List<NameAffixRule> _affixRules;

  /// Whitelist tipe entitas profil ini, urutan canonical.
  List<NameEntityType> get entityTypes => _entityTypes;

  /// Gelar dalam urutan pendaftaran.
  List<NameTitle> get titles => _titles;

  /// Aturan afiks dalam urutan pendaftaran.
  List<NameAffixRule> get affixRules => _affixRules;

  /// Apakah [entityType] masuk whitelist profil.
  bool supportsEntityType(NameEntityType entityType) =>
      _entityTypes.contains(entityType);

  /// Gelar yang berlaku untuk [entityType] + [context], terurut id.
  List<NameTitle> titlesApplyingTo(
    NameEntityType entityType,
    SocialContext context,
  ) => List.unmodifiable(
    (_titles.where((t) => t.appliesTo(entityType, context)).toList())
      ..sort((a, b) => a.id.compareTo(b.id)),
  );

  /// Aturan afiks yang berlaku, terurut id.
  List<NameAffixRule> affixesApplyingTo(
    NameEntityType entityType,
    SocialContext context,
  ) => List.unmodifiable(
    (_affixRules.where((r) => r.appliesTo(entityType, context)).toList())
      ..sort((a, b) => a.id.compareTo(b.id)),
  );

  /// Bentuk nama inti [name] dengan seluruh afiks yang berlaku: prefiks
  /// (id asc, masing-masing menempel paling dalam) lalu sufiks (id asc,
  /// menempel berurutan ke kanan). Deterministik — tanpa random, itu ranah
  /// 111.31.
  String decorateName(
    String name,
    NameEntityType entityType, [
    SocialContext? context,
  ]) {
    final ctx = context ?? defaultContext;
    final applicable = affixesApplyingTo(entityType, ctx);
    if (applicable.isEmpty) return name;
    var core = name;
    for (final rule in applicable.where(
      (r) => r.kind == NameAffixKind.prefix,
    )) {
      core = rule.attachTo(core);
    }
    for (final rule in applicable.where(
      (r) => r.kind == NameAffixKind.suffix,
    )) {
      core = rule.attachTo(core);
    }
    return core;
  }

  /// Nama lengkap bergelar: pre-name (id asc) + nama + post-name (id asc).
  String titledName(
    String name,
    NameEntityType entityType, [
    SocialContext? context,
  ]) {
    final ctx = context ?? defaultContext;
    final applying = titlesApplyingTo(entityType, ctx);
    if (applying.isEmpty) return name;
    final parts = <String>[
      for (final t in applying)
        if (t.position == TitlePosition.preName) t.text,
      name,
      for (final t in applying)
        if (t.position == TitlePosition.postName) t.text,
    ];
    return parts.join(' ');
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'profileId': profileId,
    'cultureId': cultureId,
    'languageId': languageId,
    'era': era?.toJson(),
    'entityTypes': <Object?>[for (final t in _entityTypes) t.name],
    'defaultContext': defaultContext.name,
    'titles': <Object?>[for (final t in _titles) t.toJson()],
    'affixRules': <Object?>[for (final r in _affixRules) r.toJson()],
  };

  static CulturalNameProfile fromJson(Map<String, Object?> json) {
    final eraJson = json['era'] as Map<Object?, Object?>?;
    return CulturalNameProfile.validated(
      profileId: json['profileId']! as String,
      cultureId: json['cultureId']! as String,
      languageId: json['languageId']! as String,
      era: eraJson == null ? null : NameEra.fromJson(_typed(eraJson)),
      entityTypes: <NameEntityType>{
        for (final raw in (json['entityTypes']! as List<Object?>))
          NameEntityType.values.firstWhere((t) => t.name == raw),
      },
      defaultContext: SocialContext.values.firstWhere(
        (c) => c.name == json['defaultContext'],
      ),
      titles: <NameTitle>[
        for (final raw
            in ((json['titles'] as List<Object?>?) ?? const <Object?>[]))
          NameTitle.fromJson(_typed(raw! as Map<Object?, Object?>)),
      ],
      affixRules: <NameAffixRule>[
        for (final raw
            in ((json['affixRules'] as List<Object?>?) ?? const <Object?>[]))
          NameAffixRule.fromJson(_typed(raw! as Map<Object?, Object?>)),
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CulturalNameProfile &&
          other.profileId == profileId &&
          other.cultureId == cultureId &&
          other.languageId == languageId &&
          other.era == era &&
          other.defaultContext == defaultContext &&
          other._entityTypes.length == _entityTypes.length &&
          other._entityTypes.every(_entityTypes.contains) &&
          _sameElements(other._titles, _titles) &&
          _sameElements(other._affixRules, _affixRules);

  @override
  int get hashCode => Object.hash(
    profileId,
    cultureId,
    languageId,
    era,
    defaultContext,
    Object.hashAll(_entityTypes),
    Object.hashAll(_titles),
    Object.hashAll(_affixRules),
  );
}

bool _sameElements<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Map<String, Object?> _typed(Map<Object?, Object?> json) =>
    json.map((key, value) => MapEntry(key.toString(), value));

/// Katalog multi-profil: kumpulan [CulturalNameProfile] lintas budaya dan
/// era, dengan seleksi profil aktif per marker cerita.
class NameProfileCatalog {
  const NameProfileCatalog._(this._profiles);

  /// Membuat katalog tervalidasi: id profil wajib unik antar seluruh
  /// anggota; katalog kosong diperbolehkan.
  factory NameProfileCatalog.validated({
    required List<CulturalNameProfile> profiles,
  }) {
    final seen = <String>{};
    for (final p in profiles) {
      if (!seen.add(p.profileId)) {
        throw ArgumentError('duplicate profile id: ${p.profileId}');
      }
    }
    return NameProfileCatalog._(List.unmodifiable(profiles));
  }

  final List<CulturalNameProfile> _profiles;

  /// Profil dalam urutan pendaftaran.
  List<CulturalNameProfile> get profiles => _profiles;

  /// Jumlah profil terdaftar.
  int get count => _profiles.length;

  /// Profil milik [cultureId] (trim-tolerant), terurut id profil asc.
  List<CulturalNameProfile> profilesForCulture(String cultureId) {
    final key = cultureId.trim();
    if (key.isEmpty) return const <CulturalNameProfile>[];
    return List.unmodifiable(
      (_profiles.where((p) => p.cultureId == key).toList())
        ..sort((a, b) => a.profileId.compareTo(b.profileId)),
    );
  }

  /// Profil ber-bahasa [languageId], terurut id profil asc.
  List<CulturalNameProfile> profilesForLanguage(String languageId) {
    final key = languageId.trim();
    if (key.isEmpty) return const <CulturalNameProfile>[];
    return List.unmodifiable(
      (_profiles.where((p) => p.languageId == key).toList())
        ..sort((a, b) => a.profileId.compareTo(b.profileId)),
    );
  }

  /// Profil aktif budaya [cultureId] pada [marker] cerita. Kandidat era
  /// (era mendaftar dan mencakup marker) dipilih dengan urutan: sequence
  /// naik (null terakhir), lalu id profil. Bila tidak ada kandidat era,
  /// fallback ke profil tanpa era dengan id profil terkecil. Null bila
  /// budaya tidak dikenal atau hanya ada profil era yang tidak mencakup.
  CulturalNameProfile? activeProfileFor({
    required String cultureId,
    required String marker,
    int? rank,
  }) {
    // [rank] diterima untuk kompatibilitas pemanggil berbasis sequence;
    // pemilihan era sudah deterministik lewat coversMarker + urutan kandidat.
    final _ = rank;
    final candidates = profilesForCulture(cultureId);
    if (candidates.isEmpty) return null;
    final eraMatched = candidates
        .where((p) => p.era != null && p.era!.coversMarker(marker))
        .toList();
    if (eraMatched.isNotEmpty) {
      eraMatched.sort((a, b) {
        final bySeq = NameEra.compare(a.era!, b.era!);
        if (bySeq != 0) return bySeq;
        return a.profileId.compareTo(b.profileId);
      });
      return eraMatched.first;
    }
    final eraless = candidates.where((p) => p.era == null).toList();
    if (eraless.isEmpty) return null;
    eraless.sort((a, b) => a.profileId.compareTo(b.profileId));
    return eraless.first;
  }
}
