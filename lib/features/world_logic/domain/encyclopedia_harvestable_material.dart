// Sprint 111.19 - Harvestable Materials and Consequences.

//

// Domain-only contract for materials that can be harvested:

// harvest methods, quality grades, uses, hazards, legality, and

// ecological impact, plus a deterministic catalog query.

//

// No persistence, UI, locale, network, wall clock, or random input.

library;

/// Quality ladder for harvested materials. Higher [weight] means better.

enum MaterialQualityGrade {
  crude('Crude', 1),

  standard('Standard', 2),

  fine('Fine', 3),

  pristine('Pristine', 4);

  const MaterialQualityGrade(this.label, this.weight);

  final String label;

  final int weight;
}

/// Legality ladder for harvesting or trading a material. Higher [weight]

/// means more restricted.

enum LegalityStatus {
  legal('Legal', 1),

  restricted('Restricted', 2),

  contraband('Contraband', 3);

  const LegalityStatus(this.label, this.weight);

  final String label;

  final int weight;
}

String _requireTrimmed(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }

  return value.trim();
}

void _requireSeverity(int? severity) {
  if (severity != null && (severity < 1 || severity > 5)) {
    throw ArgumentError.value(
      severity,

      'severity',

      'severity must be within 1..5 when provided',
    );
  }
}

/// A method used to harvest a material, with an optional tool list.

class MaterialHarvestMethod {
  const MaterialHarvestMethod._({
    required this.methodId,

    required this.description,

    this.tools,
  });

  factory MaterialHarvestMethod.validated({
    required String methodId,

    required String description,

    String? tools,
  }) {
    final trimmedTools = tools?.trim();

    if (trimmedTools != null && trimmedTools.isEmpty) {
      throw ArgumentError('tools must be non-empty when provided');
    }

    return MaterialHarvestMethod._(
      methodId: _requireTrimmed(methodId, 'methodId'),

      description: _requireTrimmed(description, 'description'),

      tools: trimmedTools,
    );
  }

  final String methodId;

  final String description;

  final String? tools;
}

/// A quality grade achievable for a material, with an optional note.

class MaterialQualityProfile {
  const MaterialQualityProfile._({required this.grade, this.notes});

  factory MaterialQualityProfile.validated({
    required MaterialQualityGrade grade,

    String? notes,
  }) {
    final trimmedNotes = notes?.trim();

    if (trimmedNotes != null && trimmedNotes.isEmpty) {
      throw ArgumentError('notes must be non-empty when provided');
    }

    return MaterialQualityProfile._(grade: grade, notes: trimmedNotes);
  }

  final MaterialQualityGrade grade;

  final String? notes;
}

/// A known use of a material, with an optional note.

class MaterialUse {
  const MaterialUse._({required this.useId, required this.purpose, this.note});

  factory MaterialUse.validated({
    required String useId,

    required String purpose,

    String? note,
  }) {
    final trimmedNote = note?.trim();

    if (trimmedNote != null && trimmedNote.isEmpty) {
      throw ArgumentError('note must be non-empty when provided');
    }

    return MaterialUse._(
      useId: _requireTrimmed(useId, 'useId'),

      purpose: _requireTrimmed(purpose, 'purpose'),

      note: trimmedNote,
    );
  }

  final String useId;

  final String purpose;

  final String? note;
}

/// A hazard associated with harvesting or handling a material, with an

/// optional severity on a 1..5 scale.

class MaterialHazard {
  const MaterialHazard._({
    required this.hazardId,
    required this.description,
    this.severity,
  });

  factory MaterialHazard.validated({
    required String hazardId,

    required String description,

    int? severity,
  }) {
    _requireSeverity(severity);

    return MaterialHazard._(
      hazardId: _requireTrimmed(hazardId, 'hazardId'),

      description: _requireTrimmed(description, 'description'),

      severity: severity,
    );
  }

  final String hazardId;

  final String description;

  final int? severity;
}

/// Legality profile of a material, optionally scoped to a jurisdiction.

class LegalityProfile {
  const LegalityProfile._({required this.status, this.jurisdiction});

  factory LegalityProfile.validated({
    required LegalityStatus status,

    String? jurisdiction,
  }) {
    final trimmedJurisdiction = jurisdiction?.trim();

    if (trimmedJurisdiction != null && trimmedJurisdiction.isEmpty) {
      throw ArgumentError('jurisdiction must be non-empty when provided');
    }

    return LegalityProfile._(status: status, jurisdiction: trimmedJurisdiction);
  }

  final LegalityStatus status;

  final String? jurisdiction;
}

/// Severity of an ecological impact.

enum EcologicalImpactSeverity {
  minor('Minor'),

  moderate('Moderate'),

  severe('Severe');

  const EcologicalImpactSeverity(this.label);

  final String label;
}

/// An ecological consequence of harvesting a material, with an optional

/// severity and mitigation.

class EcologicalImpact {
  const EcologicalImpact._({
    required this.impactId,

    required this.description,

    this.severity,

    this.mitigation,
  });

  factory EcologicalImpact.validated({
    required String impactId,

    required String description,

    EcologicalImpactSeverity? severity,

    String? mitigation,
  }) {
    final trimmedMtigation = mitigation?.trim();

    if (trimmedMtigation != null && trimmedMtigation.isEmpty) {
      throw ArgumentError('mitigation must be non-empty when provided');
    }

    return EcologicalImpact._(
      impactId: _requireTrimmed(impactId, 'impactId'),

      description: _requireTrimmed(description, 'description'),

      severity: severity,

      mitigation: trimmedMtigation,
    );
  }

  final String impactId;

  final String description;

  final EcologicalImpactSeverity? severity;

  final String? mitigation;
}

/// Immutable harvestable-material record. Optional collections are guarded

/// against duplicate identity keys.

class HarvestableMaterial {
  const HarvestableMaterial._({
    required this.materialId,

    required this.name,

    this.sourceId,

    required this.methods,

    required this.qualities,

    required this.uses,

    required this.hazards,

    this.legality,

    required this.impacts,

    this.notes,
  });

  factory HarvestableMaterial.validated({
    required String materialId,

    required String name,

    String? sourceId,

    List<MaterialHarvestMethod> methods = const [],

    List<MaterialQualityProfile> qualities = const [],

    List<MaterialUse> uses = const [],

    List<MaterialHazard> hazards = const [],

    LegalityProfile? legality,

    List<EcologicalImpact> impacts = const [],

    String? notes,
  }) {
    final methodIds = <String, String>{};

    for (final m in methods) {
      if (methodIds.containsKey(m.methodId)) {
        throw ArgumentError('duplicate methodId: ${m.methodId}');
      }

      methodIds[m.methodId] = m.methodId;
    }

    final grades = <MaterialQualityGrade, MaterialQualityGrade>{};

    for (final q in qualities) {
      if (grades.containsKey(q.grade)) {
        throw ArgumentError('duplicate grade: ${q.grade}');
      }

      grades[q.grade] = q.grade;
    }

    final useIds = <String, String>{};

    for (final u in uses) {
      if (useIds.containsKey(u.useId)) {
        throw ArgumentError('duplicate useId: ${u.useId}');
      }

      useIds[u.useId] = u.useId;
    }

    final hazardIds = <String, String>{};

    for (final h in hazards) {
      if (hazardIds.containsKey(h.hazardId)) {
        throw ArgumentError('duplicate hazardId: ${h.hazardId}');
      }

      hazardIds[h.hazardId] = h.hazardId;
    }

    final impactIds = <String, String>{};

    for (final i in impacts) {
      if (impactIds.containsKey(i.impactId)) {
        throw ArgumentError('duplicate impactId: ${i.impactId}');
      }

      impactIds[i.impactId] = i.impactId;
    }

    final trimmedSourceId = sourceId?.trim();

    if (trimmedSourceId != null && trimmedSourceId.isEmpty) {
      throw ArgumentError('sourceId must be non-empty when provided');
    }

    final trimmedNotes = notes?.trim();

    if (trimmedNotes != null && trimmedNotes.isEmpty) {
      throw ArgumentError('notes must be non-empty when provided');
    }

    return HarvestableMaterial._(
      materialId: _requireTrimmed(materialId, 'materialId'),

      name: _requireTrimmed(name, 'name'),

      sourceId: trimmedSourceId,

      methods: List.unmodifiable(methods),

      qualities: List.unmodifiable(qualities),

      uses: List.unmodifiable(uses),

      hazards: List.unmodifiable(hazards),

      legality: legality,

      impacts: List.unmodifiable(impacts),

      notes: trimmedNotes,
    );
  }

  final String materialId;

  final String name;

  final String? sourceId;

  final List<MaterialHarvestMethod> methods;

  final List<MaterialQualityProfile> qualities;

  final List<MaterialUse> uses;

  final List<MaterialHazard> hazards;

  final LegalityProfile? legality;

  final List<EcologicalImpact> impacts;

  final String? notes;

  bool hasMethod(String methodId) => methods.any((m) => m.methodId == methodId);

  bool hasUse(String useId) => uses.any((u) => u.useId == useId);

  bool hasHazard(String hazardId) => hazards.any((h) => h.hazardId == hazardId);

  /// Highest declared quality grade, or null when no quality is declared.

  MaterialQualityGrade? get bestQuality {
    if (qualities.isEmpty) return null;

    return qualities
        .map((q) => q.grade)
        .reduce((a, b) => a.weight >= b.weight ? a : b);
  }

  bool isAtLeastQuality(MaterialQualityGrade level) {
    final best = bestQuality;

    if (best == null) return false;

    return best.weight >= level.weight;
  }

  /// Highest declared hazard severity, or null when no hazard is declared.

  int? get maxHazardSeverity {
    if (hazards.isEmpty) return null;

    return hazards
        .map((h) => h.severity)
        .whereType<int>()
        .reduce((a, b) => a >= b ? a : b);
  }

  bool hasLegalityStatus(LegalityStatus status) =>
      legality != null && legality!.status == status;
}

/// Immutable query over [HarvestableMaterial]s. All filters are optional; a

/// blank query matches every record.

class HarvestableMaterialQuery {
  const HarvestableMaterialQuery({
    this.minQuality,

    this.legality,

    this.minHazardSeverity,

    this.useId,
  });

  final MaterialQualityGrade? minQuality;

  final LegalityStatus? legality;

  final int? minHazardSeverity;

  final String? useId;

  bool matches(HarvestableMaterial m) {
    if (minQuality != null && !m.isAtLeastQuality(minQuality!)) return false;

    if (legality != null && !m.hasLegalityStatus(legality!)) return false;

    if (minHazardSeverity != null) {
      final max = m.maxHazardSeverity;

      if (max == null || max < minHazardSeverity!) return false;
    }

    if (useId != null && !m.hasUse(useId!)) return false;

    return true;
  }

  String describe() {
    final parts = <String>[];

    if (minQuality != null) parts.add('quality >= ${minQuality!.label}');

    if (legality != null) parts.add('legality: ${legality!.label}');

    if (minHazardSeverity != null) {
      parts.add('hazard severity >= $minHazardSeverity');
    }

    if (useId != null) parts.add('use: $useId');

    if (parts.isEmpty) return 'no filters';

    return parts.join(', ');
  }
}

/// Immutable catalog of harvestable materials with deterministic query

/// support.

class HarvestableMaterialCatalog {
  const HarvestableMaterialCatalog._(this._records);

  factory HarvestableMaterialCatalog.empty() =>
      const HarvestableMaterialCatalog._([]);

  factory HarvestableMaterialCatalog.withRecords(
    List<HarvestableMaterial> records,
  ) {
    final ids = <String, String>{};

    for (final r in records) {
      if (ids.containsKey(r.materialId)) {
        throw ArgumentError('duplicate materialId: ${r.materialId}');
      }

      ids[r.materialId] = r.materialId;
    }

    final sorted = List<HarvestableMaterial>.of(records)
      ..sort((a, b) => a.materialId.compareTo(b.materialId));

    return HarvestableMaterialCatalog._(List.unmodifiable(sorted));
  }

  final List<HarvestableMaterial> _records;

  int get length => _records.length;

  HarvestableMaterial? recordFor(String materialId) {
    for (final r in _records) {
      if (r.materialId == materialId) return r;
    }

    return null;
  }

  List<HarvestableMaterial> query(HarvestableMaterialQuery q) {
    return _records.where((r) => q.matches(r)).toList();
  }
}
