// Sprint 111.24 - Myth & Legend Registry.
//
// Domain-only contract for myths and legends: the myth record itself, its
// narrative variants, recurring motifs, figures, sacred or referenced
// locations, and the groups that believe the story.
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

/// Narrative families a myth can belong to. Labels are stable and UI-friendly.
enum MythCategory {
  creation('Creation'),
  flood('Flood'),
  trickster('Trickster'),
  origin('Origin'),
  endtimes('Endtimes'),
  hero('Hero Journey'),
  deity('Deity'),
  place('Place'),
  other('Other');

  const MythCategory(this.label);

  final String label;
}

/// Roles a figure can play inside a myth.
enum FigureRole {
  deity('Deity'),
  hero('Hero'),
  villain('Villain'),
  trickster('Trickster'),
  martyr('Martyr'),
  ancestor('Ancestor'),
  beast('Beast'),
  guide('Guide'),
  other('Other');

  const FigureRole(this.label);

  final String label;
}

/// How a group relates to the myth it holds.
enum GroupStance {
  devout('Devout'),
  sympathetic('Sympathetic'),
  skeptical('Skeptical'),
  hostile('Hostile'),
  syncretic('Syncretic');

  const GroupStance(this.label);

  final String label;
}

String _requireTrimmed(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return value.trim();
}

String? _optionalTrimmed(String? value, String fieldName) {
  final trimmed = value?.trim();
  if (trimmed != null && trimmed.isEmpty) {
    throw ArgumentError('$fieldName must be non-empty when provided');
  }
  return trimmed;
}

void _requireUniqueIds(
  Iterable<String> ids,
  String collectionName,
  String idField,
) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) {
      throw ArgumentError('Duplicate $idField in $collectionName: $id');
    }
  }
}

/// A regional or cultural retelling of a myth.
class MythVariant {
  const MythVariant._({
    required this.variantId,
    required this.name,
    this.region,
    this.culture,
    this.note,
  });

  factory MythVariant.validated({
    required String variantId,
    required String name,
    String? region,
    String? culture,
    String? note,
  }) {
    return MythVariant._(
      variantId: _requireTrimmed(variantId, 'variantId'),
      name: _requireTrimmed(name, 'name'),
      region: _optionalTrimmed(region, 'region'),
      culture: _optionalTrimmed(culture, 'culture'),
      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String variantId;
  final String name;
  final String? region;
  final String? culture;
  final String? note;
}

/// A recurring narrative element inside a myth.
class MythMotif {
  const MythMotif._({
    required this.motifId,
    required this.name,
    this.description,
  });

  factory MythMotif.validated({
    required String motifId,
    required String name,
    String? description,
  }) {
    return MythMotif._(
      motifId: _requireTrimmed(motifId, 'motifId'),
      name: _requireTrimmed(name, 'name'),
      description: _optionalTrimmed(description, 'description'),
    );
  }

  final String motifId;
  final String name;
  final String? description;
}

/// A being or person who appears in a myth.
class MythFigure {
  const MythFigure._({
    required this.figureId,
    required this.name,
    required this.role,
    this.description,
  });

  factory MythFigure.validated({
    required String figureId,
    required String name,
    FigureRole role = FigureRole.other,
    String? description,
  }) {
    return MythFigure._(
      figureId: _requireTrimmed(figureId, 'figureId'),
      name: _requireTrimmed(name, 'name'),
      role: role,
      description: _optionalTrimmed(description, 'description'),
    );
  }

  final String figureId;
  final String name;
  final FigureRole role;
  final String? description;

  String get roleLabel => role.label;
}

/// A place a myth references; sacred places anchor rituals and pilgrimage.
class MythLocationReference {
  const MythLocationReference._({
    required this.locationId,
    required this.placeName,
    required this.sacred,
    this.description,
  });

  factory MythLocationReference.validated({
    required String locationId,
    required String placeName,
    bool sacred = false,
    String? description,
  }) {
    return MythLocationReference._(
      locationId: _requireTrimmed(locationId, 'locationId'),
      placeName: _requireTrimmed(placeName, 'placeName'),
      sacred: sacred,
      description: _optionalTrimmed(description, 'description'),
    );
  }

  final String locationId;
  final String placeName;
  final bool sacred;
  final String? description;
}

/// A community, sect, or culture that believes (or disbelieves) the myth.
class BelievingGroup {
  const BelievingGroup._({
    required this.groupId,
    required this.name,
    required this.stance,
    this.region,
  });

  factory BelievingGroup.validated({
    required String groupId,
    required String name,
    GroupStance stance = GroupStance.devout,
    String? region,
  }) {
    return BelievingGroup._(
      groupId: _requireTrimmed(groupId, 'groupId'),
      name: _requireTrimmed(name, 'name'),
      stance: stance,
      region: _optionalTrimmed(region, 'region'),
    );
  }

  final String groupId;
  final String name;
  final GroupStance stance;
  final String? region;
}

/// A single myth with its variants, motifs, figures, locations, and believers.
class MythRecord {
  const MythRecord._({
    required this.mythId,
    required this.title,
    required this.variants,
    required this.motifs,
    required this.figures,
    required this.locations,
    required this.believingGroups,
    this.summary,
    this.category,
    this.eraLabel,
  });

  factory MythRecord.validated({
    required String mythId,
    required String title,
    List<MythVariant> variants = const [],
    List<MythMotif> motifs = const [],
    List<MythFigure> figures = const [],
    List<MythLocationReference> locations = const [],
    List<BelievingGroup> believingGroups = const [],
    String? summary,
    MythCategory? category,
    String? eraLabel,
  }) {
    _requireUniqueIds(
      variants.map((v) => v.variantId),
      'variants',
      'variantId',
    );
    _requireUniqueIds(motifs.map((m) => m.motifId), 'motifs', 'motifId');
    _requireUniqueIds(figures.map((f) => f.figureId), 'figures', 'figureId');
    _requireUniqueIds(
      locations.map((l) => l.locationId),
      'locations',
      'locationId',
    );
    _requireUniqueIds(
      believingGroups.map((g) => g.groupId),
      'believingGroups',
      'groupId',
    );
    return MythRecord._(
      mythId: _requireTrimmed(mythId, 'mythId'),
      title: _requireTrimmed(title, 'title'),
      variants: List.unmodifiable(variants),
      motifs: List.unmodifiable(motifs),
      figures: List.unmodifiable(figures),
      locations: List.unmodifiable(locations),
      believingGroups: List.unmodifiable(believingGroups),
      summary: _optionalTrimmed(summary, 'summary'),
      category: category,
      eraLabel: _optionalTrimmed(eraLabel, 'eraLabel'),
    );
  }

  final String mythId;
  final String title;
  final List<MythVariant> variants;
  final List<MythMotif> motifs;
  final List<MythFigure> figures;
  final List<MythLocationReference> locations;
  final List<BelievingGroup> believingGroups;
  final String? summary;
  final MythCategory? category;
  final String? eraLabel;

  int get variantCount => variants.length;
  int get motifCount => motifs.length;
  int get figureCount => figures.length;
  int get locationCount => locations.length;
  int get groupCount => believingGroups.length;

  bool hasVariant(String variantId) =>
      variants.any((v) => v.variantId == variantId);

  bool hasMotif(String motifId) => motifs.any((m) => m.motifId == motifId);

  bool hasFigure(String figureId) => figures.any((f) => f.figureId == figureId);

  bool hasLocation(String locationId) =>
      locations.any((l) => l.locationId == locationId);

  bool hasGroup(String groupId) =>
      believingGroups.any((g) => g.groupId == groupId);

  List<String> get motifIds {
    final ids = motifs.map((m) => m.motifId).toList()..sort();
    return List.unmodifiable(ids);
  }

  List<String> get figureIds {
    final ids = figures.map((f) => f.figureId).toList()..sort();
    return List.unmodifiable(ids);
  }

  List<MythFigure> figuresWithRole(FigureRole role) {
    final matched = figures.where((f) => f.role == role).toList()
      ..sort((a, b) => a.figureId.compareTo(b.figureId));
    return List.unmodifiable(matched);
  }

  List<BelievingGroup> groupsHolding(GroupStance stance) {
    final matched = believingGroups.where((g) => g.stance == stance).toList()
      ..sort((a, b) => a.groupId.compareTo(b.groupId));
    return List.unmodifiable(matched);
  }

  bool isOfCategory(MythCategory other) => category == other;

  bool get hasSacredLocation => locations.any((l) => l.sacred);
}

/// Deterministic catalog query over [MythRecord]s.
class MythQuery {
  const MythQuery({
    this.category,
    this.motifId,
    this.figureId,
    this.locationId,
    this.groupId,
    this.stance,
  });

  final MythCategory? category;
  final String? motifId;
  final String? figureId;
  final String? locationId;
  final String? groupId;
  final GroupStance? stance;

  bool matches(MythRecord record) {
    if (category != null && !record.isOfCategory(category!)) {
      return false;
    }
    if (motifId != null && !record.hasMotif(motifId!)) {
      return false;
    }
    if (figureId != null && !record.hasFigure(figureId!)) {
      return false;
    }
    if (locationId != null && !record.hasLocation(locationId!)) {
      return false;
    }
    if (groupId != null && !record.hasGroup(groupId!)) {
      return false;
    }
    if (stance != null &&
        !record.believingGroups.any((g) => g.stance == stance)) {
      return false;
    }
    return true;
  }

  String describe() {
    final parts = <String>[];
    if (category != null) {
      parts.add('category=${category!.name}');
    }
    if (motifId != null) {
      parts.add('motif=$motifId');
    }
    if (figureId != null) {
      parts.add('figure=$figureId');
    }
    if (locationId != null) {
      parts.add('location=$locationId');
    }
    if (groupId != null) {
      parts.add('group=$groupId');
    }
    if (stance != null) {
      parts.add('stance=${stance!.name}');
    }
    if (parts.isEmpty) {
      return 'MythQuery(no filters)';
    }
    return 'MythQuery(${parts.join(', ')})';
  }
}

/// A sacred-place entry produced by [MythCatalog.sacredLocations].
class SacredLocationEntry {
  const SacredLocationEntry({
    required this.mythId,
    required this.locationId,
    required this.placeName,
  });

  final String mythId;
  final String locationId;
  final String placeName;
}

/// Immutable collection of myths with deterministic reverse indexes.
class MythCatalog {
  MythCatalog._(List<MythRecord> records)
    : _records = List.unmodifiable(records);

  factory MythCatalog.empty() => MythCatalog._(const []);

  factory MythCatalog.withRecords(List<MythRecord> records) {
    _requireUniqueIds(records.map((r) => r.mythId), 'records', 'mythId');
    final sorted = records.toList()
      ..sort((a, b) => a.mythId.compareTo(b.mythId));
    return MythCatalog._(sorted);
  }

  final List<MythRecord> _records;

  List<MythRecord> get records => _records;

  bool get isEmpty => _records.isEmpty;

  int get length => _records.length;

  List<String> get mythIds => List.unmodifiable(_records.map((r) => r.mythId));

  String? titleFor(String mythId) {
    for (final r in _records) {
      if (r.mythId == mythId) {
        return r.title;
      }
    }
    return null;
  }

  List<String> _mythsWhere(bool Function(MythRecord) test) {
    final ids = _records.where(test).map((r) => r.mythId).toList()..sort();
    return List.unmodifiable(ids);
  }

  List<String> mythsFeaturingMotif(String motifId) =>
      _mythsWhere((r) => r.hasMotif(motifId));

  List<String> mythsFeaturingFigure(String figureId) =>
      _mythsWhere((r) => r.hasFigure(figureId));

  List<String> mythsTiedToLocation(String locationId) =>
      _mythsWhere((r) => r.hasLocation(locationId));

  List<String> mythsHeldByGroup(String groupId) =>
      _mythsWhere((r) => r.hasGroup(groupId));

  Map<String, int> motifFrequency() {
    final counts = <String, int>{};
    for (final r in _records) {
      for (final m in r.motifs) {
        counts[m.motifId] = (counts[m.motifId] ?? 0) + 1;
      }
    }
    return Map.unmodifiable(counts);
  }

  /// Most-used motif id; ties break on motifId ascending. Null when empty.
  String? mostCommonMotifId() {
    final counts = motifFrequency();
    if (counts.isEmpty) {
      return null;
    }
    final ids = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        if (byCount != 0) {
          return byCount;
        }
        return a.compareTo(b);
      });
    return ids.first;
  }

  List<MythRecord> query(MythQuery query) {
    final matched = _records.where(query.matches).toList()
      ..sort((a, b) => a.mythId.compareTo(b.mythId));
    return List.unmodifiable(matched);
  }

  /// All sacred location refs, sorted by mythId then locationId.
  List<SacredLocationEntry> sacredLocations() {
    final entries = <SacredLocationEntry>[];
    for (final r in _records) {
      for (final l in r.locations) {
        if (l.sacred) {
          entries.add(
            SacredLocationEntry(
              mythId: r.mythId,
              locationId: l.locationId,
              placeName: l.placeName,
            ),
          );
        }
      }
    }
    entries.sort((a, b) {
      final byMyth = a.mythId.compareTo(b.mythId);
      if (byMyth != 0) {
        return byMyth;
      }
      return a.locationId.compareTo(b.locationId);
    });
    return List.unmodifiable(entries);
  }
}
