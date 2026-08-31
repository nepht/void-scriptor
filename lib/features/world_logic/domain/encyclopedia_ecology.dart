// Sprint 111.16 - Habitat, Ecology and Behavior.
//
// Domain-only contract for bestiary ecology and behavior: habitats, diet,
// predators, prey, social structures, migration patterns, and hunting
// behaviors.
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

String _requireTrimmed(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return value.trim();
}

/// A habitat where a species lives.
class EcologyHabitat {
  const EcologyHabitat._({required this.habitatId, required this.description});

  factory EcologyHabitat.validated({
    required String habitatId,
    required String description,
  }) {
    return EcologyHabitat._(
      habitatId: _requireTrimmed(habitatId, 'habitatId'),
      description: _requireTrimmed(description, 'description'),
    );
  }

  final String habitatId;
  final String description;
}

/// An item in a species diet, with an optional proportion description.
class DietItem {
  const DietItem._({required this.itemId, required this.name, this.proportion});

  factory DietItem.validated({
    required String itemId,
    required String name,
    String? proportion,
  }) {
    final trimmedProportion = proportion?.trim();
    if (trimmedProportion != null && trimmedProportion.isEmpty) {
      throw ArgumentError('proportion must be non-empty when provided');
    }
    return DietItem._(
      itemId: _requireTrimmed(itemId, 'itemId'),
      name: _requireTrimmed(name, 'name'),
      proportion: trimmedProportion,
    );
  }

  final String itemId;
  final String name;
  final String? proportion;
}

/// A reference to another species (predator or prey).
class SpeciesRef {
  const SpeciesRef._({required this.speciesId});

  factory SpeciesRef.validated({required String speciesId}) {
    return SpeciesRef._(speciesId: _requireTrimmed(speciesId, 'speciesId'));
  }

  final String speciesId;
}

/// A social structure of the species, with an optional description.
class SocialStructure {
  const SocialStructure._({
    required this.structureId,
    required this.name,
    this.description,
  });

  factory SocialStructure.validated({
    required String structureId,
    required String name,
    String? description,
  }) {
    final trimmedDescription = description?.trim();
    if (trimmedDescription != null && trimmedDescription.isEmpty) {
      throw ArgumentError('description must be non-empty when provided');
    }
    return SocialStructure._(
      structureId: _requireTrimmed(structureId, 'structureId'),
      name: _requireTrimmed(name, 'name'),
      description: trimmedDescription,
    );
  }

  final String structureId;
  final String name;
  final String? description;
}

/// A migration pattern of the species, with an optional route.
class MigrationPattern {
  const MigrationPattern._({
    required this.patternId,
    required this.description,
    this.route,
  });

  factory MigrationPattern.validated({
    required String patternId,
    required String description,
    String? route,
  }) {
    final trimmedRoute = route?.trim();
    if (trimmedRoute != null && trimmedRoute.isEmpty) {
      throw ArgumentError('route must be non-empty when provided');
    }
    return MigrationPattern._(
      patternId: _requireTrimmed(patternId, 'patternId'),
      description: _requireTrimmed(description, 'description'),
      route: trimmedRoute,
    );
  }

  final String patternId;
  final String description;
  final String? route;
}

/// A hunting behavior of the species, with an optional description.
class HuntingBehavior {
  const HuntingBehavior._({
    required this.behaviorId,
    required this.name,
    this.description,
  });

  factory HuntingBehavior.validated({
    required String behaviorId,
    required String name,
    String? description,
  }) {
    final trimmedDescription = description?.trim();
    if (trimmedDescription != null && trimmedDescription.isEmpty) {
      throw ArgumentError('description must be non-empty when provided');
    }
    return HuntingBehavior._(
      behaviorId: _requireTrimmed(behaviorId, 'behaviorId'),
      name: _requireTrimmed(name, 'name'),
      description: trimmedDescription,
    );
  }

  final String behaviorId;
  final String name;
  final String? description;
}

/// Immutable ecology profile for a species. Optional collections are
/// guarded against duplicate identity keys.
class EcologyProfile {
  const EcologyProfile._({
    required this.speciesId,
    required this.habitats,
    required this.diet,
    required this.predators,
    required this.prey,
    required this.socialStructures,
    required this.migrations,
    required this.huntingBehaviors,
  });

  factory EcologyProfile.validated({
    required String speciesId,
    List<EcologyHabitat> habitats = const [],
    List<DietItem> diet = const [],
    List<SpeciesRef> predators = const [],
    List<SpeciesRef> prey = const [],
    List<SocialStructure> socialStructures = const [],
    List<MigrationPattern> migrations = const [],
    List<HuntingBehavior> huntingBehaviors = const [],
  }) {
    final habitatIds = <String, String>{};
    for (final h in habitats) {
      if (habitatIds.containsKey(h.habitatId)) {
        throw ArgumentError('duplicate habitatId: ${h.habitatId}');
      }
      habitatIds[h.habitatId] = h.habitatId;
    }
    final dietIds = <String, String>{};
    for (final d in diet) {
      if (dietIds.containsKey(d.itemId)) {
        throw ArgumentError('duplicate itemId: ${d.itemId}');
      }
      dietIds[d.itemId] = d.itemId;
    }
    final predatorIds = <String, String>{};
    for (final p in predators) {
      if (predatorIds.containsKey(p.speciesId)) {
        throw ArgumentError('duplicate predator speciesId: ${p.speciesId}');
      }
      predatorIds[p.speciesId] = p.speciesId;
    }
    final preyIds = <String, String>{};
    for (final p in prey) {
      if (preyIds.containsKey(p.speciesId)) {
        throw ArgumentError('duplicate prey speciesId: ${p.speciesId}');
      }
      preyIds[p.speciesId] = p.speciesId;
    }
    final structureIds = <String, String>{};
    for (final s in socialStructures) {
      if (structureIds.containsKey(s.structureId)) {
        throw ArgumentError('duplicate structureId: ${s.structureId}');
      }
      structureIds[s.structureId] = s.structureId;
    }
    final migrationIds = <String, String>{};
    for (final m in migrations) {
      if (migrationIds.containsKey(m.patternId)) {
        throw ArgumentError('duplicate patternId: ${m.patternId}');
      }
      migrationIds[m.patternId] = m.patternId;
    }
    final behaviorIds = <String, String>{};
    for (final b in huntingBehaviors) {
      if (behaviorIds.containsKey(b.behaviorId)) {
        throw ArgumentError('duplicate behaviorId: ${b.behaviorId}');
      }
      behaviorIds[b.behaviorId] = b.behaviorId;
    }
    return EcologyProfile._(
      speciesId: _requireTrimmed(speciesId, 'speciesId'),
      habitats: List.unmodifiable(habitats),
      diet: List.unmodifiable(diet),
      predators: List.unmodifiable(predators),
      prey: List.unmodifiable(prey),
      socialStructures: List.unmodifiable(socialStructures),
      migrations: List.unmodifiable(migrations),
      huntingBehaviors: List.unmodifiable(huntingBehaviors),
    );
  }

  final String speciesId;
  final List<EcologyHabitat> habitats;
  final List<DietItem> diet;
  final List<SpeciesRef> predators;
  final List<SpeciesRef> prey;
  final List<SocialStructure> socialStructures;
  final List<MigrationPattern> migrations;
  final List<HuntingBehavior> huntingBehaviors;

  bool inHabitat(String habitatId) =>
      habitats.any((h) => h.habitatId == habitatId);

  bool eats(String itemId) => diet.any((d) => d.itemId == itemId);

  bool hasPredator(String speciesId) =>
      predators.any((p) => p.speciesId == speciesId);

  bool hasPrey(String speciesId) => prey.any((p) => p.speciesId == speciesId);

  bool hasHuntingBehavior(String behaviorId) =>
      huntingBehaviors.any((b) => b.behaviorId == behaviorId);
}

/// Immutable catalog of ecology profiles with deterministic query support.
class EcologyCatalog {
  const EcologyCatalog._(this._profiles);

  factory EcologyCatalog.empty() => const EcologyCatalog._([]);

  factory EcologyCatalog.withProfiles(List<EcologyProfile> profiles) {
    final ids = <String, String>{};
    for (final p in profiles) {
      if (ids.containsKey(p.speciesId)) {
        throw ArgumentError('duplicate speciesId: ${p.speciesId}');
      }
      ids[p.speciesId] = p.speciesId;
    }
    final sorted = List<EcologyProfile>.of(profiles)
      ..sort((a, b) => a.speciesId.compareTo(b.speciesId));
    return EcologyCatalog._(List.unmodifiable(sorted));
  }

  final List<EcologyProfile> _profiles;

  int get length => _profiles.length;

  EcologyProfile? profileFor(String speciesId) {
    for (final p in _profiles) {
      if (p.speciesId == speciesId) return p;
    }
    return null;
  }

  /// Profiles living in [habitatId], sorted by species id.
  List<EcologyProfile> inHabitat(String habitatId) {
    return _profiles.where((p) => p.inHabitat(habitatId)).toList();
  }
}
