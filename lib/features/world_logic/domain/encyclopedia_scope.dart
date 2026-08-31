// Sprint 111.5 - Temporal, Regional & Cultural Scope.
//
// Domain-only contract for encyclopedia entries that need to carry when,
// where, by whom, and on which world branch a piece of lore applies.
//
// Covers validity_ranges, locations, cultures, factions (with role),
// languages, and world_branches. Pure Dart, deterministic, free of
// persistence, UI, locale, network, wall clock, and random input.

library;

/// Tick-based temporal validity window. [validFrom] is inclusive;
/// [validUntil] is inclusive and may be null for open-ended ranges.
class ValidityRange {
  const ValidityRange._({required this.validFrom, required this.validUntil});

  factory ValidityRange.validated({required int validFrom, int? validUntil}) {
    if (validFrom < 0) {
      throw ArgumentError.value(
        validFrom,
        'validFrom',
        'validFrom must be >= 0',
      );
    }
    if (validUntil != null && validUntil < validFrom) {
      throw ArgumentError.value(
        validUntil,
        'validUntil',
        'validUntil must be >= validFrom',
      );
    }
    return ValidityRange._(validFrom: validFrom, validUntil: validUntil);
  }

  final int validFrom;
  final int? validUntil;

  bool containsTick(int tick) {
    if (tick < validFrom) return false;
    final upper = validUntil;
    if (upper == null) return true;
    return tick <= upper;
  }

  bool get isOpenEnded => validUntil == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ValidityRange &&
          other.validFrom == validFrom &&
          other.validUntil == validUntil);

  @override
  int get hashCode => Object.hash(validFrom, validUntil);

  @override
  String toString() => isOpenEnded
      ? 'ValidityRange($validFrom..)'
      : 'ValidityRange($validFrom..$validUntil)';
}

/// Reference to a world location that scopes an encyclopedia entry.
class ScopeLocationRef {
  const ScopeLocationRef._({required this.locationId, required this.kind});

  factory ScopeLocationRef.validated({
    required String locationId,
    required String kind,
  }) {
    final id = locationId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(
        locationId,
        'locationId',
        'locationId cannot be empty',
      );
    }
    final k = kind.trim();
    if (k.isEmpty) {
      throw ArgumentError.value(kind, 'kind', 'kind cannot be empty');
    }
    return ScopeLocationRef._(locationId: id, kind: k);
  }

  final String locationId;
  final String kind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScopeLocationRef &&
          other.locationId == locationId &&
          other.kind == kind);

  @override
  int get hashCode => Object.hash(locationId, kind);

  @override
  String toString() => 'ScopeLocationRef($locationId:$kind)';
}

/// Reference to a culture that owns or influences the entry.
class ScopeCultureRef {
  const ScopeCultureRef._({required this.cultureId});

  factory ScopeCultureRef.validated({required String cultureId}) {
    final id = cultureId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(
        cultureId,
        'cultureId',
        'cultureId cannot be empty',
      );
    }
    return ScopeCultureRef._(cultureId: id);
  }

  final String cultureId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScopeCultureRef && other.cultureId == cultureId);

  @override
  int get hashCode => cultureId.hashCode;

  @override
  String toString() => 'ScopeCultureRef($cultureId)';
}

/// Role a faction plays with respect to the entry. Drives query semantics
/// (owning/controlling/alliedWith/opposedTo/influencedBy) without binding
/// to the diplomacy authority in 110.30.
enum ScopeFactionRole {
  owning,
  controlling,
  alliedWith,
  influencedBy,
  opposedTo,
}

/// Reference to a faction with a specific role on the entry.
class ScopeFactionRef {
  const ScopeFactionRef._({required this.factionId, required this.role});

  factory ScopeFactionRef.validated({
    required String factionId,
    required ScopeFactionRole role,
  }) {
    final id = factionId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(
        factionId,
        'factionId',
        'factionId cannot be empty',
      );
    }
    return ScopeFactionRef._(factionId: id, role: role);
  }

  final String factionId;
  final ScopeFactionRole role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScopeFactionRef &&
          other.factionId == factionId &&
          other.role == role);

  @override
  int get hashCode => Object.hash(factionId, role);

  @override
  String toString() => 'ScopeFactionRef($factionId:${role.name})';
}

/// Reference to a language relevant to the entry.
class ScopeLanguageRef {
  const ScopeLanguageRef._({required this.languageId});

  factory ScopeLanguageRef.validated({required String languageId}) {
    final id = languageId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(
        languageId,
        'languageId',
        'languageId cannot be empty',
      );
    }
    return ScopeLanguageRef._(languageId: id);
  }

  final String languageId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScopeLanguageRef && other.languageId == languageId);

  @override
  int get hashCode => languageId.hashCode;

  @override
  String toString() => 'ScopeLanguageRef($languageId)';
}

/// Reference to a world branch (timeline/timeline-branch the entry applies
/// to). At least one prime branch is expected per project, mirroring the
/// branch awareness in 110.20 TemporalMapState.
class ScopeBranchRef {
  const ScopeBranchRef._({required this.branchId, required this.isPrime});

  factory ScopeBranchRef.validated({
    required String branchId,
    required bool isPrime,
  }) {
    final id = branchId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(
        branchId,
        'branchId',
        'branchId cannot be empty',
      );
    }
    return ScopeBranchRef._(branchId: id, isPrime: isPrime);
  }

  final String branchId;
  final bool isPrime;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScopeBranchRef &&
          other.branchId == branchId &&
          other.isPrime == isPrime);

  @override
  int get hashCode => Object.hash(branchId, isPrime);

  @override
  String toString() =>
      isPrime ? 'ScopeBranchRef($branchId:prime)' : 'ScopeBranchRef($branchId)';
}

/// Aggregated scope metadata for an encyclopedia entry. Each facet is
/// optional so an entry may declare any subset without forcing callers to
/// fill the others. Equality compares every facet.
class EncyclopediaScope {
  const EncyclopediaScope({
    this.validity,
    this.locations = const [],
    this.cultures = const [],
    this.factions = const [],
    this.languages = const [],
    this.branches = const [],
  });

  static const empty = EncyclopediaScope();

  final ValidityRange? validity;
  final List<ScopeLocationRef> locations;
  final List<ScopeCultureRef> cultures;
  final List<ScopeFactionRef> factions;
  final List<ScopeLanguageRef> languages;
  final List<ScopeBranchRef> branches;

  bool get hasAnyFacet =>
      validity != null ||
      locations.isNotEmpty ||
      cultures.isNotEmpty ||
      factions.isNotEmpty ||
      languages.isNotEmpty ||
      branches.isNotEmpty;

  bool get isAlwaysApplicable => !hasAnyFacet;

  bool activeAt(int tick) {
    final v = validity;
    if (v == null) return true;
    return v.containsTick(tick);
  }

  bool forLocation(String locationId) {
    if (locations.isEmpty) return true;
    for (final l in locations) {
      if (l.locationId == locationId) return true;
    }
    return false;
  }

  bool forCulture(String cultureId) {
    if (cultures.isEmpty) return true;
    for (final c in cultures) {
      if (c.cultureId == cultureId) return true;
    }
    return false;
  }

  bool forFaction(String factionId) {
    if (factions.isEmpty) return true;
    for (final f in factions) {
      if (f.factionId == factionId) return true;
    }
    return false;
  }

  bool forLanguage(String languageId) {
    if (languages.isEmpty) return true;
    for (final l in languages) {
      if (l.languageId == languageId) return true;
    }
    return false;
  }

  bool forBranch(String branchId) {
    if (branches.isEmpty) return true;
    for (final b in branches) {
      if (b.branchId == branchId) return true;
    }
    return false;
  }

  String explain() {
    final parts = <String>[];
    final v = validity;
    parts.add(
      v == null
          ? 'validity=none'
          : (v.isOpenEnded
                ? 'validity=${v.validFrom}..'
                : 'validity=${v.validFrom}..${v.validUntil}'),
    );
    parts.add('locations=${locations.length}');
    parts.add('cultures=${cultures.length}');
    parts.add('factions=${factions.length}');
    parts.add('languages=${languages.length}');
    parts.add('branches=${branches.length}');
    return parts.join(' ');
  }
}

/// Mutable registry of scope identifiers mapped to their aggregated
/// [EncyclopediaScope]. Rejects empty and duplicate ids; lookup returns
/// `null` for unknown ids.
class ScopeRegistry {
  final Map<String, EncyclopediaScope> _scopes = <String, EncyclopediaScope>{};

  int get length => _scopes.length;

  Iterable<String> get ids => _scopes.keys;

  void register(EncyclopediaScope scope, {required String id}) {
    final key = id.trim();
    if (key.isEmpty) {
      throw ArgumentError.value(id, 'id', 'scope id cannot be empty');
    }
    if (_scopes.containsKey(key)) {
      throw ArgumentError.value(key, 'id', 'scope id already registered: $key');
    }
    _scopes[key] = scope;
  }

  EncyclopediaScope? scopeFor(String id) => _scopes[id];
}
