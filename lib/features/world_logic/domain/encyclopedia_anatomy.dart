// Sprint 111.15 - Anatomy and Physiology Profile.
//
// Domain-only contract for bestiary anatomy and physiology: body plan,
// organs, senses, locomotion, defenses, reproduction, and biological needs.
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

String _requireTrimmed(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return value.trim();
}

/// The overall body plan of a species.
class BodyPlan {
  const BodyPlan._({required this.bodyPlanId, required this.description});

  factory BodyPlan.validated({
    required String bodyPlanId,
    required String description,
  }) {
    return BodyPlan._(
      bodyPlanId: _requireTrimmed(bodyPlanId, 'bodyPlanId'),
      description: _requireTrimmed(description, 'description'),
    );
  }

  final String bodyPlanId;
  final String description;
}

/// An organ present in the species, with an optional note.
class OrganRef {
  const OrganRef._({required this.organId, required this.name, this.note});

  factory OrganRef.validated({
    required String organId,
    required String name,
    String? note,
  }) {
    final trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.isEmpty) {
      throw ArgumentError('note must be non-empty when provided');
    }
    return OrganRef._(
      organId: _requireTrimmed(organId, 'organId'),
      name: _requireTrimmed(name, 'name'),
      note: trimmedNote,
    );
  }

  final String organId;
  final String name;
  final String? note;
}

/// A sense the species possesses, with an optional range description.
class SenseRef {
  const SenseRef._({required this.senseId, required this.name, this.range});

  factory SenseRef.validated({
    required String senseId,
    required String name,
    String? range,
  }) {
    final trimmedRange = range?.trim();
    if (trimmedRange != null && trimmedRange.isEmpty) {
      throw ArgumentError('range must be non-empty when provided');
    }
    return SenseRef._(
      senseId: _requireTrimmed(senseId, 'senseId'),
      name: _requireTrimmed(name, 'name'),
      range: trimmedRange,
    );
  }

  final String senseId;
  final String name;
  final String? range;
}

/// A locomotion mode of the species, with an optional speed description.
class LocomotionMode {
  const LocomotionMode._({
    required this.modeId,
    required this.name,
    this.speed,
  });

  factory LocomotionMode.validated({
    required String modeId,
    required String name,
    String? speed,
  }) {
    final trimmedSpeed = speed?.trim();
    if (trimmedSpeed != null && trimmedSpeed.isEmpty) {
      throw ArgumentError('speed must be non-empty when provided');
    }
    return LocomotionMode._(
      modeId: _requireTrimmed(modeId, 'modeId'),
      name: _requireTrimmed(name, 'name'),
      speed: trimmedSpeed,
    );
  }

  final String modeId;
  final String name;
  final String? speed;
}

/// A defense mechanism of the species, with an optional description.
class DefenseMechanism {
  const DefenseMechanism._({
    required this.defenseId,
    required this.name,
    this.description,
  });

  factory DefenseMechanism.validated({
    required String defenseId,
    required String name,
    String? description,
  }) {
    final trimmedDescription = description?.trim();
    if (trimmedDescription != null && trimmedDescription.isEmpty) {
      throw ArgumentError('description must be non-empty when provided');
    }
    return DefenseMechanism._(
      defenseId: _requireTrimmed(defenseId, 'defenseId'),
      name: _requireTrimmed(name, 'name'),
      description: trimmedDescription,
    );
  }

  final String defenseId;
  final String name;
  final String? description;
}

/// How the species reproduces, with optional details.
class ReproductionProfile {
  const ReproductionProfile._({required this.method, this.details});

  factory ReproductionProfile.validated({
    required String method,
    String? details,
  }) {
    final trimmedDetails = details?.trim();
    if (trimmedDetails != null && trimmedDetails.isEmpty) {
      throw ArgumentError('details must be non-empty when provided');
    }
    return ReproductionProfile._(
      method: _requireTrimmed(method, 'method'),
      details: trimmedDetails,
    );
  }

  final String method;
  final String? details;
}

/// A biological need of the species, with an optional description.
class BiologicalNeed {
  const BiologicalNeed._({
    required this.needId,
    required this.name,
    this.description,
  });

  factory BiologicalNeed.validated({
    required String needId,
    required String name,
    String? description,
  }) {
    final trimmedDescription = description?.trim();
    if (trimmedDescription != null && trimmedDescription.isEmpty) {
      throw ArgumentError('description must be non-empty when provided');
    }
    return BiologicalNeed._(
      needId: _requireTrimmed(needId, 'needId'),
      name: _requireTrimmed(name, 'name'),
      description: trimmedDescription,
    );
  }

  final String needId;
  final String name;
  final String? description;
}

/// Immutable anatomy profile for a species. Optional collections are
/// guarded against duplicate identity keys.
class AnatomyProfile {
  const AnatomyProfile._({
    required this.speciesId,
    required this.organs,
    required this.senses,
    required this.locomotion,
    required this.defenses,
    required this.biologicalNeeds,
    this.bodyPlan,
    this.reproduction,
  });

  factory AnatomyProfile.validated({
    required String speciesId,
    BodyPlan? bodyPlan,
    List<OrganRef> organs = const [],
    List<SenseRef> senses = const [],
    List<LocomotionMode> locomotion = const [],
    List<DefenseMechanism> defenses = const [],
    ReproductionProfile? reproduction,
    List<BiologicalNeed> biologicalNeeds = const [],
  }) {
    final organIds = <String, String>{};
    for (final o in organs) {
      if (organIds.containsKey(o.organId)) {
        throw ArgumentError('duplicate organId: ${o.organId}');
      }
      organIds[o.organId] = o.organId;
    }
    final senseIds = <String, String>{};
    for (final s in senses) {
      if (senseIds.containsKey(s.senseId)) {
        throw ArgumentError('duplicate senseId: ${s.senseId}');
      }
      senseIds[s.senseId] = s.senseId;
    }
    final modeIds = <String, String>{};
    for (final m in locomotion) {
      if (modeIds.containsKey(m.modeId)) {
        throw ArgumentError('duplicate modeId: ${m.modeId}');
      }
      modeIds[m.modeId] = m.modeId;
    }
    final defenseIds = <String, String>{};
    for (final d in defenses) {
      if (defenseIds.containsKey(d.defenseId)) {
        throw ArgumentError('duplicate defenseId: ${d.defenseId}');
      }
      defenseIds[d.defenseId] = d.defenseId;
    }
    final needIds = <String, String>{};
    for (final n in biologicalNeeds) {
      if (needIds.containsKey(n.needId)) {
        throw ArgumentError('duplicate needId: ${n.needId}');
      }
      needIds[n.needId] = n.needId;
    }
    return AnatomyProfile._(
      speciesId: _requireTrimmed(speciesId, 'speciesId'),
      organs: List.unmodifiable(organs),
      senses: List.unmodifiable(senses),
      locomotion: List.unmodifiable(locomotion),
      defenses: List.unmodifiable(defenses),
      biologicalNeeds: List.unmodifiable(biologicalNeeds),
      bodyPlan: bodyPlan,
      reproduction: reproduction,
    );
  }

  final String speciesId;
  final BodyPlan? bodyPlan;
  final List<OrganRef> organs;
  final List<SenseRef> senses;
  final List<LocomotionMode> locomotion;
  final List<DefenseMechanism> defenses;
  final ReproductionProfile? reproduction;
  final List<BiologicalNeed> biologicalNeeds;

  bool hasOrgan(String organId) => organs.any((o) => o.organId == organId);

  bool hasSense(String senseId) => senses.any((s) => s.senseId == senseId);

  bool hasLocomotion(String modeId) =>
      locomotion.any((m) => m.modeId == modeId);

  bool hasDefense(String defenseId) =>
      defenses.any((d) => d.defenseId == defenseId);

  bool hasBiologicalNeed(String needId) =>
      biologicalNeeds.any((n) => n.needId == needId);
}

/// Immutable catalog of anatomy profiles with deterministic query support.
class AnatomyCatalog {
  const AnatomyCatalog._(this._profiles);

  factory AnatomyCatalog.empty() => const AnatomyCatalog._([]);

  factory AnatomyCatalog.withProfiles(List<AnatomyProfile> profiles) {
    final ids = <String, String>{};
    for (final p in profiles) {
      if (ids.containsKey(p.speciesId)) {
        throw ArgumentError('duplicate speciesId: ${p.speciesId}');
      }
      ids[p.speciesId] = p.speciesId;
    }
    final sorted = List<AnatomyProfile>.of(profiles)
      ..sort((a, b) => a.speciesId.compareTo(b.speciesId));
    return AnatomyCatalog._(List.unmodifiable(sorted));
  }

  final List<AnatomyProfile> _profiles;

  int get length => _profiles.length;

  AnatomyProfile? profileFor(String speciesId) {
    for (final p in _profiles) {
      if (p.speciesId == speciesId) return p;
    }
    return null;
  }

  /// Profiles that include [organId], sorted by species id.
  List<AnatomyProfile> profilesWithOrgan(String organId) {
    return _profiles.where((p) => p.hasOrgan(organId)).toList();
  }
}
