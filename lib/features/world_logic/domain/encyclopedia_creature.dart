// Sprint 111.14 - Creature and Species Registry.
//
// Domain-only contract for the bestiary species registry: species,
// variants, life stages, classification, local names, and canon status.
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

String _requireTrimmed(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return value.trim();
}

/// Broad classification of a creature species.
enum CreatureClassification {
  animal('Animal'),
  plant('Plant'),
  fungus('Fungus'),
  elemental('Elemental'),
  spirit('Spirit'),
  construct('Construct'),
  other('Other');

  const CreatureClassification(this.label);

  final String label;
}

/// A distinct variant or subspecies of a species, with optional notes.
class SpeciesVariant {
  const SpeciesVariant._({
    required this.variantId,
    required this.name,
    this.notes,
  });

  factory SpeciesVariant.validated({
    required String variantId,
    required String name,
    String? notes,
  }) {
    final trimmedNotes = notes?.trim();
    if (trimmedNotes != null && trimmedNotes.isEmpty) {
      throw ArgumentError('notes must be non-empty when provided');
    }
    return SpeciesVariant._(
      variantId: _requireTrimmed(variantId, 'variantId'),
      name: _requireTrimmed(name, 'name'),
      notes: trimmedNotes,
    );
  }

  final String variantId;
  final String name;
  final String? notes;
}

/// A life stage of a species, with an optional description.
class LifeStage {
  const LifeStage._({
    required this.stageId,
    required this.name,
    this.description,
  });

  factory LifeStage.validated({
    required String stageId,
    required String name,
    String? description,
  }) {
    final trimmedDescription = description?.trim();
    if (trimmedDescription != null && trimmedDescription.isEmpty) {
      throw ArgumentError('description must be non-empty when provided');
    }
    return LifeStage._(
      stageId: _requireTrimmed(stageId, 'stageId'),
      name: _requireTrimmed(name, 'name'),
      description: trimmedDescription,
    );
  }

  final String stageId;
  final String name;
  final String? description;
}

/// A culture-specific name for a species, with an optional meaning.
class LocalName {
  const LocalName._({required this.name, required this.culture, this.meaning});

  factory LocalName.validated({
    required String name,
    required String culture,
    String? meaning,
  }) {
    final trimmedMeaning = meaning?.trim();
    if (trimmedMeaning != null && trimmedMeaning.isEmpty) {
      throw ArgumentError('meaning must be non-empty when provided');
    }
    return LocalName._(
      name: _requireTrimmed(name, 'name'),
      culture: _requireTrimmed(culture, 'culture'),
      meaning: trimmedMeaning,
    );
  }

  final String name;
  final String culture;
  final String? meaning;
}

/// Canon status ladder for a species, mirroring the shared encyclopedia
/// canon model (111.4).
enum CanonStatus {
  canon('Canon'),
  rumor('Rumor'),
  myth('Myth'),
  hypothesis('Hypothesis'),
  generated('Generated');

  const CanonStatus(this.label);

  final String label;
}

/// Immutable creature species. Optional collections are guarded against
/// duplicate identity keys.
class CreatureSpecies {
  const CreatureSpecies._({
    required this.speciesId,
    required this.name,
    required this.variants,
    required this.lifeStages,
    required this.localNames,
    this.classification,
    this.canonStatus,
  });

  factory CreatureSpecies.validated({
    required String speciesId,
    required String name,
    List<SpeciesVariant> variants = const [],
    List<LifeStage> lifeStages = const [],
    List<LocalName> localNames = const [],
    CreatureClassification? classification,
    CanonStatus? canonStatus,
  }) {
    final variantIds = <String, String>{};
    for (final v in variants) {
      if (variantIds.containsKey(v.variantId)) {
        throw ArgumentError('duplicate variantId: ${v.variantId}');
      }
      variantIds[v.variantId] = v.variantId;
    }
    final stageIds = <String, String>{};
    for (final s in lifeStages) {
      if (stageIds.containsKey(s.stageId)) {
        throw ArgumentError('duplicate stageId: ${s.stageId}');
      }
      stageIds[s.stageId] = s.stageId;
    }
    final localNameKeys = <String, String>{};
    for (final n in localNames) {
      final key = '${n.culture}|${n.name}';
      if (localNameKeys.containsKey(key)) {
        throw ArgumentError(
          'duplicate local name for culture ${n.culture}: ${n.name}',
        );
      }
      localNameKeys[key] = key;
    }
    return CreatureSpecies._(
      speciesId: _requireTrimmed(speciesId, 'speciesId'),
      name: _requireTrimmed(name, 'name'),
      variants: List.unmodifiable(variants),
      lifeStages: List.unmodifiable(lifeStages),
      localNames: List.unmodifiable(localNames),
      classification: classification,
      canonStatus: canonStatus,
    );
  }

  final String speciesId;
  final String name;
  final List<SpeciesVariant> variants;
  final List<LifeStage> lifeStages;
  final List<LocalName> localNames;
  final CreatureClassification? classification;
  final CanonStatus? canonStatus;

  bool hasVariant(String variantId) =>
      variants.any((v) => v.variantId == variantId);

  bool hasLifeStage(String stageId) =>
      lifeStages.any((s) => s.stageId == stageId);

  /// The local name for [culture], or null when none is declared.
  String? localNameForCulture(String culture) {
    for (final n in localNames) {
      if (n.culture == culture) return n.name;
    }
    return null;
  }
}

/// Immutable catalog of creature species with deterministic query support.
class CreatureCatalog {
  const CreatureCatalog._(this._species);

  factory CreatureCatalog.empty() => const CreatureCatalog._([]);

  factory CreatureCatalog.withSpecies(List<CreatureSpecies> species) {
    final ids = <String, String>{};
    for (final s in species) {
      if (ids.containsKey(s.speciesId)) {
        throw ArgumentError('duplicate speciesId: ${s.speciesId}');
      }
      ids[s.speciesId] = s.speciesId;
    }
    final sorted = List<CreatureSpecies>.of(species)
      ..sort((a, b) => a.speciesId.compareTo(b.speciesId));
    return CreatureCatalog._(List.unmodifiable(sorted));
  }

  final List<CreatureSpecies> _species;

  int get length => _species.length;

  CreatureSpecies? speciesFor(String speciesId) {
    for (final s in _species) {
      if (s.speciesId == speciesId) return s;
    }
    return null;
  }

  /// Species matching [classification], sorted by species id.
  List<CreatureSpecies> byClassification(
    CreatureClassification classification,
  ) {
    return _species.where((s) => s.classification == classification).toList();
  }

  /// Species matching [canonStatus], sorted by species id.
  List<CreatureSpecies> byCanonStatus(CanonStatus canonStatus) {
    return _species.where((s) => s.canonStatus == canonStatus).toList();
  }
}
