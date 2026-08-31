// Sprint 111.20 - Artifact & Relic Registry.

//

// Domain-only contract for artifacts and relics: artifact types, creators,

// origins, materials, components, condition, and authenticity, plus a

// deterministic catalog query.

//

// No persistence, UI, locale, network, wall clock, or random input.

library;

/// Type categories for an artifact. Labels are stable and UI-friendly.

enum ArtifactType {
  weapon('Weapon'),

  armor('Armor'),

  tool('Tool'),

  instrument('Instrument'),

  vessel('Vessel'),

  talisman('Talisman'),

  relic('Relic'),

  manuscript('Manuscript'),

  other('Other');

  const ArtifactType(this.label);

  final String label;
}

/// Condition ladder for an artifact. Higher [weight] means better condition.

enum ArtifactCondition {
  destroyed('Destroyed', 0),

  damaged('Damaged', 1),

  worn('Worn', 2),

  good('Good', 3),

  pristine('Pristine', 4);

  const ArtifactCondition(this.label, this.weight);

  final String label;

  final int weight;
}

/// Authenticity ladder for an artifact. Higher [weight] means more certain.

enum ArtifactAuthenticity {
  unknown('Unknown', 0),

  disputed('Disputed', 1),

  forged('Forged', 2),

  suspected('Suspected', 3),

  verified('Verified', 4),

  authentic('Authentic', 5);

  const ArtifactAuthenticity(this.label, this.weight);

  final String label;

  final int weight;
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

/// A known creator of an artifact, with an optional note.

class ArtifactCreator {
  const ArtifactCreator._({
    required this.creatorId,
    required this.name,
    this.note,
  });

  factory ArtifactCreator.validated({
    required String creatorId,

    required String name,

    String? note,
  }) {
    return ArtifactCreator._(
      creatorId: _requireTrimmed(creatorId, 'creatorId'),

      name: _requireTrimmed(name, 'name'),

      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String creatorId;

  final String name;

  final String? note;
}

/// A known origin of an artifact, with optional region and culture.

class ArtifactOrigin {
  const ArtifactOrigin._({
    required this.originId,

    required this.description,

    this.region,

    this.culture,
  });

  factory ArtifactOrigin.validated({
    required String originId,

    required String description,

    String? region,

    String? culture,
  }) {
    return ArtifactOrigin._(
      originId: _requireTrimmed(originId, 'originId'),

      description: _requireTrimmed(description, 'description'),

      region: _optionalTrimmed(region, 'region'),

      culture: _optionalTrimmed(culture, 'culture'),
    );
  }

  final String originId;

  final String description;

  final String? region;

  final String? culture;
}

/// A material component used in an artifact, with an optional quantity.

class MaterialComponent {
  const MaterialComponent._({
    required this.componentId,

    required this.name,

    this.quantity,
  });

  factory MaterialComponent.validated({
    required String componentId,

    required String name,

    String? quantity,
  }) {
    return MaterialComponent._(
      componentId: _requireTrimmed(componentId, 'componentId'),

      name: _requireTrimmed(name, 'name'),

      quantity: _optionalTrimmed(quantity, 'quantity'),
    );
  }

  final String componentId;

  final String name;

  final String? quantity;
}

/// A reference to a sub-component of an artifact, with a role and optional note.

class ComponentRef {
  const ComponentRef._({required this.refId, required this.role, this.note});

  factory ComponentRef.validated({
    required String refId,

    required String role,

    String? note,
  }) {
    return ComponentRef._(
      refId: _requireTrimmed(refId, 'refId'),

      role: _requireTrimmed(role, 'role'),

      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String refId;

  final String role;

  final String? note;
}

/// Immutable artifact record. Optional collections are guarded against

/// duplicate identity keys.

class ArtifactRecord {
  const ArtifactRecord._({
    required this.artifactId,

    required this.name,

    this.type,

    this.typeName,

    this.condition,

    this.authenticity,

    required this.creators,

    required this.origins,

    required this.materials,

    required this.components,

    this.notes,
  });

  factory ArtifactRecord.validated({
    required String artifactId,

    required String name,

    ArtifactType? type,

    String? typeName,

    ArtifactCondition? condition,

    ArtifactAuthenticity? authenticity,

    List<ArtifactCreator> creators = const [],

    List<ArtifactOrigin> origins = const [],

    List<MaterialComponent> materials = const [],

    List<ComponentRef> components = const [],

    String? notes,
  }) {
    final creatorIds = <String, String>{};

    for (final c in creators) {
      if (creatorIds.containsKey(c.creatorId)) {
        throw ArgumentError('duplicate creatorId: ${c.creatorId}');
      }

      creatorIds[c.creatorId] = c.creatorId;
    }

    final originIds = <String, String>{};

    for (final o in origins) {
      if (originIds.containsKey(o.originId)) {
        throw ArgumentError('duplicate originId: ${o.originId}');
      }

      originIds[o.originId] = o.originId;
    }

    final materialIds = <String, String>{};

    for (final m in materials) {
      if (materialIds.containsKey(m.componentId)) {
        throw ArgumentError('duplicate componentId: ${m.componentId}');
      }

      materialIds[m.componentId] = m.componentId;
    }

    final componentIds = <String, String>{};

    for (final c in components) {
      if (componentIds.containsKey(c.refId)) {
        throw ArgumentError('duplicate refId: ${c.refId}');
      }

      componentIds[c.refId] = c.refId;
    }

    return ArtifactRecord._(
      artifactId: _requireTrimmed(artifactId, 'artifactId'),

      name: _requireTrimmed(name, 'name'),

      type: type,

      typeName: _optionalTrimmed(typeName, 'typeName'),

      condition: condition,

      authenticity: authenticity,

      creators: List.unmodifiable(creators),

      origins: List.unmodifiable(origins),

      materials: List.unmodifiable(materials),

      components: List.unmodifiable(components),

      notes: _optionalTrimmed(notes, 'notes'),
    );
  }

  final String artifactId;

  final String name;

  final ArtifactType? type;

  final String? typeName;

  final ArtifactCondition? condition;

  final ArtifactAuthenticity? authenticity;

  final List<ArtifactCreator> creators;

  final List<ArtifactOrigin> origins;

  final List<MaterialComponent> materials;

  final List<ComponentRef> components;

  final String? notes;

  bool hasCreator(String creatorId) =>
      creators.any((c) => c.creatorId == creatorId);

  bool hasOrigin(String originId) => origins.any((o) => o.originId == originId);

  bool hasMaterial(String componentId) =>
      materials.any((m) => m.componentId == componentId);

  bool hasComponent(String refId) => components.any((c) => c.refId == refId);

  bool isAtLeastCondition(ArtifactCondition level) {
    final c = condition;

    if (c == null) return false;

    return c.weight >= level.weight;
  }

  bool hasAuthenticityStatus(ArtifactAuthenticity status) =>
      authenticity != null && authenticity == status;

  bool isOfType(ArtifactType type) => this.type == type;
}

/// Immutable query over [ArtifactRecord]s. All filters are optional; a blank

/// query matches every record.

class ArtifactQuery {
  const ArtifactQuery({
    this.type,

    this.minCondition,

    this.authenticity,

    this.creatorId,

    this.originId,

    this.materialId,
  });

  final ArtifactType? type;

  final ArtifactCondition? minCondition;

  final ArtifactAuthenticity? authenticity;

  final String? creatorId;

  final String? originId;

  final String? materialId;

  bool matches(ArtifactRecord a) {
    if (type != null && !a.isOfType(type!)) return false;

    if (minCondition != null && !a.isAtLeastCondition(minCondition!)) {
      return false;
    }

    if (authenticity != null && !a.hasAuthenticityStatus(authenticity!)) {
      return false;
    }

    if (creatorId != null && !a.hasCreator(creatorId!)) return false;

    if (originId != null && !a.hasOrigin(originId!)) return false;

    if (materialId != null && !a.hasMaterial(materialId!)) return false;

    return true;
  }

  String describe() {
    final parts = <String>[];

    if (type != null) parts.add('type: ${type!.label}');

    if (minCondition != null) {
      parts.add('condition >= ${minCondition!.label}');
    }

    if (authenticity != null) parts.add('authenticity: ${authenticity!.label}');

    if (creatorId != null) parts.add('creator: $creatorId');

    if (originId != null) parts.add('origin: $originId');

    if (materialId != null) parts.add('material: $materialId');

    if (parts.isEmpty) return 'no filters';

    return parts.join(', ');
  }
}

/// Immutable catalog of artifacts with deterministic query support.

class ArtifactCatalog {
  const ArtifactCatalog._(this._records);

  factory ArtifactCatalog.empty() => const ArtifactCatalog._([]);

  factory ArtifactCatalog.withRecords(List<ArtifactRecord> records) {
    final ids = <String, String>{};

    for (final r in records) {
      if (ids.containsKey(r.artifactId)) {
        throw ArgumentError('duplicate artifactId: ${r.artifactId}');
      }

      ids[r.artifactId] = r.artifactId;
    }

    final sorted = List<ArtifactRecord>.of(records)
      ..sort((a, b) => a.artifactId.compareTo(b.artifactId));

    return ArtifactCatalog._(List.unmodifiable(sorted));
  }

  final List<ArtifactRecord> _records;

  int get length => _records.length;

  ArtifactRecord? recordFor(String artifactId) {
    for (final r in _records) {
      if (r.artifactId == artifactId) return r;
    }

    return null;
  }

  List<ArtifactRecord> query(ArtifactQuery q) {
    return _records.where((r) => q.matches(r)).toList();
  }
}
