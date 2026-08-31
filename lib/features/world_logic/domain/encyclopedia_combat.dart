// Sprint 111.17 - Weakness, Defense and Combat Reference.
//
// Domain-only contract for bestiary combat reference: weaknesses,
// resistances, attack patterns, warning signs, combat tactics, and source
// evidence.
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

String _requireTrimmed(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return value.trim();
}

/// A known weakness of a species, with an optional description.
class CombatWeakness {
  const CombatWeakness._({
    required this.weaknessId,
    required this.name,
    this.description,
  });

  factory CombatWeakness.validated({
    required String weaknessId,
    required String name,
    String? description,
  }) {
    final trimmedDescription = description?.trim();
    if (trimmedDescription != null && trimmedDescription.isEmpty) {
      throw ArgumentError('description must be non-empty when provided');
    }
    return CombatWeakness._(
      weaknessId: _requireTrimmed(weaknessId, 'weaknessId'),
      name: _requireTrimmed(name, 'name'),
      description: trimmedDescription,
    );
  }

  final String weaknessId;
  final String name;
  final String? description;
}

/// A resistance of a species, with an optional level description.
class CombatResistance {
  const CombatResistance._({
    required this.resistanceId,
    required this.name,
    this.level,
  });

  factory CombatResistance.validated({
    required String resistanceId,
    required String name,
    String? level,
  }) {
    final trimmedLevel = level?.trim();
    if (trimmedLevel != null && trimmedLevel.isEmpty) {
      throw ArgumentError('level must be non-empty when provided');
    }
    return CombatResistance._(
      resistanceId: _requireTrimmed(resistanceId, 'resistanceId'),
      name: _requireTrimmed(name, 'name'),
      level: trimmedLevel,
    );
  }

  final String resistanceId;
  final String name;
  final String? level;
}

/// An attack pattern of a species, with an optional description.
class AttackPattern {
  const AttackPattern._({
    required this.patternId,
    required this.name,
    this.description,
  });

  factory AttackPattern.validated({
    required String patternId,
    required String name,
    String? description,
  }) {
    final trimmedDescription = description?.trim();
    if (trimmedDescription != null && trimmedDescription.isEmpty) {
      throw ArgumentError('description must be non-empty when provided');
    }
    return AttackPattern._(
      patternId: _requireTrimmed(patternId, 'patternId'),
      name: _requireTrimmed(name, 'name'),
      description: trimmedDescription,
    );
  }

  final String patternId;
  final String name;
  final String? description;
}

/// A warning sign before an attack.
class WarningSign {
  const WarningSign._({required this.signId, required this.description});

  factory WarningSign.validated({
    required String signId,
    required String description,
  }) {
    return WarningSign._(
      signId: _requireTrimmed(signId, 'signId'),
      description: _requireTrimmed(description, 'description'),
    );
  }

  final String signId;
  final String description;
}

/// A combat tactic advised against the species, with optional description.
class CombatTactic {
  const CombatTactic._({
    required this.tacticId,
    required this.name,
    this.description,
  });

  factory CombatTactic.validated({
    required String tacticId,
    required String name,
    String? description,
  }) {
    final trimmedDescription = description?.trim();
    if (trimmedDescription != null && trimmedDescription.isEmpty) {
      throw ArgumentError('description must be non-empty when provided');
    }
    return CombatTactic._(
      tacticId: _requireTrimmed(tacticId, 'tacticId'),
      name: _requireTrimmed(name, 'name'),
      description: trimmedDescription,
    );
  }

  final String tacticId;
  final String name;
  final String? description;
}

/// A source reference supporting combat data, with an optional note.
class SourceEvidence {
  const SourceEvidence._({
    required this.evidenceId,
    required this.reference,
    this.note,
  });

  factory SourceEvidence.validated({
    required String evidenceId,
    required String reference,
    String? note,
  }) {
    final trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.isEmpty) {
      throw ArgumentError('note must be non-empty when provided');
    }
    return SourceEvidence._(
      evidenceId: _requireTrimmed(evidenceId, 'evidenceId'),
      reference: _requireTrimmed(reference, 'reference'),
      note: trimmedNote,
    );
  }

  final String evidenceId;
  final String reference;
  final String? note;
}

/// Immutable combat reference profile for a species. Optional collections
/// are guarded against duplicate identity keys.
class CombatProfile {
  const CombatProfile._({
    required this.speciesId,
    required this.weaknesses,
    required this.resistances,
    required this.attackPatterns,
    required this.warningSigns,
    required this.tactics,
    required this.sourceEvidence,
  });

  factory CombatProfile.validated({
    required String speciesId,
    List<CombatWeakness> weaknesses = const [],
    List<CombatResistance> resistances = const [],
    List<AttackPattern> attackPatterns = const [],
    List<WarningSign> warningSigns = const [],
    List<CombatTactic> tactics = const [],
    List<SourceEvidence> sourceEvidence = const [],
  }) {
    final weaknessIds = <String, String>{};
    for (final w in weaknesses) {
      if (weaknessIds.containsKey(w.weaknessId)) {
        throw ArgumentError('duplicate weaknessId: ${w.weaknessId}');
      }
      weaknessIds[w.weaknessId] = w.weaknessId;
    }
    final resistanceIds = <String, String>{};
    for (final r in resistances) {
      if (resistanceIds.containsKey(r.resistanceId)) {
        throw ArgumentError('duplicate resistanceId: ${r.resistanceId}');
      }
      resistanceIds[r.resistanceId] = r.resistanceId;
    }
    final patternIds = <String, String>{};
    for (final p in attackPatterns) {
      if (patternIds.containsKey(p.patternId)) {
        throw ArgumentError('duplicate patternId: ${p.patternId}');
      }
      patternIds[p.patternId] = p.patternId;
    }
    final signIds = <String, String>{};
    for (final s in warningSigns) {
      if (signIds.containsKey(s.signId)) {
        throw ArgumentError('duplicate signId: ${s.signId}');
      }
      signIds[s.signId] = s.signId;
    }
    final tacticIds = <String, String>{};
    for (final t in tactics) {
      if (tacticIds.containsKey(t.tacticId)) {
        throw ArgumentError('duplicate tacticId: ${t.tacticId}');
      }
      tacticIds[t.tacticId] = t.tacticId;
    }
    final evidenceIds = <String, String>{};
    for (final e in sourceEvidence) {
      if (evidenceIds.containsKey(e.evidenceId)) {
        throw ArgumentError('duplicate evidenceId: ${e.evidenceId}');
      }
      evidenceIds[e.evidenceId] = e.evidenceId;
    }
    return CombatProfile._(
      speciesId: _requireTrimmed(speciesId, 'speciesId'),
      weaknesses: List.unmodifiable(weaknesses),
      resistances: List.unmodifiable(resistances),
      attackPatterns: List.unmodifiable(attackPatterns),
      warningSigns: List.unmodifiable(warningSigns),
      tactics: List.unmodifiable(tactics),
      sourceEvidence: List.unmodifiable(sourceEvidence),
    );
  }

  final String speciesId;
  final List<CombatWeakness> weaknesses;
  final List<CombatResistance> resistances;
  final List<AttackPattern> attackPatterns;
  final List<WarningSign> warningSigns;
  final List<CombatTactic> tactics;
  final List<SourceEvidence> sourceEvidence;

  bool hasWeakness(String weaknessId) =>
      weaknesses.any((w) => w.weaknessId == weaknessId);

  bool hasResistance(String resistanceId) =>
      resistances.any((r) => r.resistanceId == resistanceId);

  bool hasAttackPattern(String patternId) =>
      attackPatterns.any((p) => p.patternId == patternId);

  bool hasWarningSign(String signId) =>
      warningSigns.any((s) => s.signId == signId);
}

/// Immutable catalog of combat profiles with deterministic query support.
class CombatCatalog {
  const CombatCatalog._(this._profiles);

  factory CombatCatalog.empty() => const CombatCatalog._([]);

  factory CombatCatalog.withProfiles(List<CombatProfile> profiles) {
    final ids = <String, String>{};
    for (final p in profiles) {
      if (ids.containsKey(p.speciesId)) {
        throw ArgumentError('duplicate speciesId: ${p.speciesId}');
      }
      ids[p.speciesId] = p.speciesId;
    }
    final sorted = List<CombatProfile>.of(profiles)
      ..sort((a, b) => a.speciesId.compareTo(b.speciesId));
    return CombatCatalog._(List.unmodifiable(sorted));
  }

  final List<CombatProfile> _profiles;

  int get length => _profiles.length;

  CombatProfile? profileFor(String speciesId) {
    for (final p in _profiles) {
      if (p.speciesId == speciesId) return p;
    }
    return null;
  }

  /// Profiles weak to [weaknessId], sorted by species id.
  List<CombatProfile> weakTo(String weaknessId) {
    return _profiles.where((p) => p.hasWeakness(weaknessId)).toList();
  }
}
