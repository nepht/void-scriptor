// Sprint 111.10 - Habitat, Rarity and Harvest Model.
//
// Domain-only contract for ingredient/substance harvest information:
// habitats, seasonality, rarity, harvest methods, hazards, and a
// deterministic availability query over a harvest catalog.
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

/// Rarity ladder for harvested ingredients. Higher [weight] means rarer.
enum RarityLevel {
  common('Common', 1),
  uncommon('Uncommon', 2),
  rare('Rare', 3),
  veryRare('Very Rare', 4),
  unique('Unique', 5);

  const RarityLevel(this.label, this.weight);

  final String label;
  final int weight;
}

/// In-world seasons used by seasonality windows.
enum Season { spring, summer, autumn, winter }

String _requireTrimmed(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return value.trim();
}

/// A season during which an ingredient can be harvested, with an optional
/// explanatory note.
class SeasonWindow {
  const SeasonWindow._({required this.season, this.note});

  factory SeasonWindow.validated({required Season season, String? note}) {
    final trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.isEmpty) {
      throw ArgumentError('note must be non-empty when provided');
    }
    return SeasonWindow._(season: season, note: trimmedNote);
  }

  final Season season;
  final String? note;
}

/// A habitat where an ingredient can be found, optionally restricted to a
/// region.
class HabitatRef {
  const HabitatRef._({required this.habitatId, this.region});

  factory HabitatRef.validated({required String habitatId, String? region}) {
    final trimmedRegion = region?.trim();
    if (trimmedRegion != null && trimmedRegion.isEmpty) {
      throw ArgumentError('region must be non-empty when provided');
    }
    return HabitatRef._(
      habitatId: _requireTrimmed(habitatId, 'habitatId'),
      region: trimmedRegion,
    );
  }

  final String habitatId;
  final String? region;
}

/// A method used to harvest an ingredient, with an optional tool list.
class HarvestMethod {
  const HarvestMethod._({
    required this.methodId,
    required this.description,
    this.tools,
  });

  factory HarvestMethod.validated({
    required String methodId,
    required String description,
    String? tools,
  }) {
    final trimmedTools = tools?.trim();
    if (trimmedTools != null && trimmedTools.isEmpty) {
      throw ArgumentError('tools must be non-empty when provided');
    }
    return HarvestMethod._(
      methodId: _requireTrimmed(methodId, 'methodId'),
      description: _requireTrimmed(description, 'description'),
      tools: trimmedTools,
    );
  }

  final String methodId;
  final String description;
  final String? tools;
}

/// A hazard associated with harvesting an ingredient, with an optional
/// severity on a 1..5 scale.
class HarvestHazard {
  const HarvestHazard._({
    required this.hazardId,
    required this.description,
    this.severity,
  });

  factory HarvestHazard.validated({
    required String hazardId,
    required String description,
    int? severity,
  }) {
    final s = severity;
    if (s != null && (s < 1 || s > 5)) {
      throw ArgumentError.value(
        severity,
        'severity',
        'severity must be within 1..5 when provided',
      );
    }
    return HarvestHazard._(
      hazardId: _requireTrimmed(hazardId, 'hazardId'),
      description: _requireTrimmed(description, 'description'),
      severity: s,
    );
  }

  final String hazardId;
  final String description;
  final int? severity;
}

/// Immutable harvest record for an ingredient. Optional collections are
/// guarded against duplicate identity keys.
class HarvestRecord {
  const HarvestRecord._({
    required this.ingredientId,
    required this.rarity,
    required this.habitats,
    required this.seasonality,
    required this.methods,
    required this.hazards,
    this.notes,
  });

  factory HarvestRecord.validated({
    required String ingredientId,
    required RarityLevel rarity,
    List<HabitatRef> habitats = const [],
    List<SeasonWindow> seasonality = const [],
    List<HarvestMethod> methods = const [],
    List<HarvestHazard> hazards = const [],
    String? notes,
  }) {
    final habitatIds = <String, String>{};
    for (final h in habitats) {
      if (habitatIds.containsKey(h.habitatId)) {
        throw ArgumentError('duplicate habitatId: ${h.habitatId}');
      }
      habitatIds[h.habitatId] = h.habitatId;
    }
    final seasons = <Season, Season>{};
    for (final w in seasonality) {
      if (seasons.containsKey(w.season)) {
        throw ArgumentError('duplicate season: ${w.season}');
      }
      seasons[w.season] = w.season;
    }
    final methodIds = <String, String>{};
    for (final m in methods) {
      if (methodIds.containsKey(m.methodId)) {
        throw ArgumentError('duplicate methodId: ${m.methodId}');
      }
      methodIds[m.methodId] = m.methodId;
    }
    final hazardIds = <String, String>{};
    for (final h in hazards) {
      if (hazardIds.containsKey(h.hazardId)) {
        throw ArgumentError('duplicate hazardId: ${h.hazardId}');
      }
      hazardIds[h.hazardId] = h.hazardId;
    }
    final trimmedNotes = notes?.trim();
    if (trimmedNotes != null && trimmedNotes.isEmpty) {
      throw ArgumentError('notes must be non-empty when provided');
    }
    return HarvestRecord._(
      ingredientId: _requireTrimmed(ingredientId, 'ingredientId'),
      rarity: rarity,
      habitats: List.unmodifiable(habitats),
      seasonality: List.unmodifiable(seasonality),
      methods: List.unmodifiable(methods),
      hazards: List.unmodifiable(hazards),
      notes: trimmedNotes,
    );
  }

  final String ingredientId;
  final RarityLevel rarity;
  final List<HabitatRef> habitats;
  final List<SeasonWindow> seasonality;
  final List<HarvestMethod> methods;
  final List<HarvestHazard> hazards;
  final String? notes;

  /// True when the record declares [season], or when no seasonality is
  /// declared (year-round availability).
  bool isHarvestableInSeason(Season season) {
    if (seasonality.isEmpty) return true;
    return seasonality.any((w) => w.season == season);
  }

  bool matchesHabitat(String habitatId) =>
      habitats.any((h) => h.habitatId == habitatId);

  /// True when [this] record is at least as rare as [level] on the ladder.
  bool isAtLeast(RarityLevel level) => rarity.weight >= level.weight;
}

/// Immutable availability query over [HarvestRecord]s. All filters are
/// optional; a blank query matches every record.
class HarvestAvailabilityQuery {
  const HarvestAvailabilityQuery({this.minRarity, this.season, this.habitatId});

  final RarityLevel? minRarity;
  final Season? season;
  final String? habitatId;

  /// Returns true when [record] satisfies all non-null filters.
  bool matches(HarvestRecord record) {
    if (minRarity != null && !record.isAtLeast(minRarity!)) return false;
    if (season != null && !record.isHarvestableInSeason(season!)) return false;
    if (habitatId != null && !record.matchesHabitat(habitatId!)) return false;
    return true;
  }

  /// A human-readable description of the active filters.
  String describe() {
    final parts = <String>[];
    if (minRarity != null) parts.add('rarity >= ${minRarity!.label}');
    if (season != null) parts.add('season: ${season!.name}');
    if (habitatId != null) parts.add('habitat: $habitatId');
    if (parts.isEmpty) return 'no filters';
    return parts.join(', ');
  }
}

/// Immutable catalog of harvest records with deterministic query support.
class HarvestCatalog {
  const HarvestCatalog._(this._records);

  factory HarvestCatalog.empty() => const HarvestCatalog._([]);

  factory HarvestCatalog.withRecords(List<HarvestRecord> records) {
    final ids = <String, String>{};
    for (final r in records) {
      if (ids.containsKey(r.ingredientId)) {
        throw ArgumentError('duplicate ingredientId: ${r.ingredientId}');
      }
      ids[r.ingredientId] = r.ingredientId;
    }
    // Sort by ingredientId for deterministic query order.
    final sorted = List<HarvestRecord>.of(records)
      ..sort((a, b) => a.ingredientId.compareTo(b.ingredientId));
    return HarvestCatalog._(List.unmodifiable(sorted));
  }

  final List<HarvestRecord> _records;

  int get length => _records.length;

  HarvestRecord? recordFor(String ingredientId) {
    // Linear scan is fine for domain-only contracts (no performance requirement).
    for (final r in _records) {
      if (r.ingredientId == ingredientId) return r;
    }
    return null;
  }

  List<HarvestRecord> query(HarvestAvailabilityQuery q) {
    return _records.where((r) => q.matches(r)).toList();
  }
}
