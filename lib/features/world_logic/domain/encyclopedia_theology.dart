// Sprint 111.26 - Theology, Deity & Doctrine Model.
//
// Domain-only contract for a faith: its deities and divine domains, its
// doctrines, rituals, religious institutions, taboos, sacred texts, and the
// schisms that split institutions apart. Referential integrity is enforced
// at the record boundary — a schism can only split registered institutions,
// a ritual/taboo/head-deity reference must name a registered deity, and
// doctrine and text references must resolve inside the same record.
//
// Consumes nothing outside this file; MythCategory.deity and
// FigureRole.deity from 111.24 stay narrative roles — this file is the
// organized-theology layer above them.
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

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

List<String> _trimUniqueList(
  List<String> values,
  String fieldName,
  String collectionName, {
  bool caseInsensitive = false,
}) {
  final trimmed = values.map((v) => _requireTrimmed(v, fieldName)).toList();
  final seen = <String>{};
  for (final value in trimmed) {
    final key = caseInsensitive ? value.toLowerCase() : value;
    if (!seen.add(key)) {
      throw ArgumentError('Duplicate $fieldName in $collectionName: $value');
    }
  }
  return trimmed;
}

/// The cosmic function a deity embodies within the faith.
enum DeityRole {
  supreme('Supreme'),
  creator('Creator'),
  sustainer('Sustainer'),
  destruction('Destruction'),
  war('War'),
  wisdom('Wisdom'),
  nature('Nature'),
  underworld('Underworld'),
  trickster('Trickster'),
  other('Other');

  const DeityRole(this.label);

  final String label;
}

/// What kind of teaching a doctrine carries.
enum DoctrineKind {
  tenet('Tenet'),
  moralLaw('Moral Law'),
  sacrament('Sacrament'),
  mystery('Mystery'),
  eschatology('Eschatology'),
  other('Other');

  const DoctrineKind(this.label);

  final String label;
}

/// How often a ritual is performed.
enum RitualCadence {
  daily('Daily'),
  weekly('Weekly'),
  seasonal('Seasonal'),
  annual('Annual'),
  lifeEvent('Life Event'),
  onceInAges('Once in Ages'),
  other('Other');

  const RitualCadence(this.label);

  final String label;
}

/// The organizational shape of a religious institution.
enum InstitutionKind {
  church('Church'),
  order('Religious Order'),
  sect('Sect'),
  seminary('Seminary'),
  shrine('Shrine'),
  clergyHouse('Clergy House'),
  other('Other');

  const InstitutionKind(this.label);

  final String label;
}

/// How serious breaking a taboo is. Weight ladder: 1..3.
enum TabooSeverity {
  mild(1, 'Mild'),
  grave(2, 'Grave'),
  mortal(3, 'Mortal');

  const TabooSeverity(this.weight, this.label);

  final int weight;
  final String label;
}

/// How authoritative a sacred text is inside the faith. Weight 0..3.
enum TextCanonicity {
  apocryphal(0, 'Apocryphal'),
  disputed(1, 'Disputed'),
  canonical(2, 'Canonical'),
  revealed(3, 'Revealed');

  const TextCanonicity(this.weight, this.label);

  final int weight;
  final String label;
}

/// A sphere of divine authority (sun, sea, thresholds, ...).
class DivineDomain {
  const DivineDomain._({
    required this.domainId,
    required this.name,
    this.description,
  });

  factory DivineDomain.validated({
    required String domainId,
    required String name,
    String? description,
  }) {
    return DivineDomain._(
      domainId: _requireTrimmed(domainId, 'domainId'),
      name: _requireTrimmed(name, 'name'),
      description: _optionalTrimmed(description, 'description'),
    );
  }

  final String domainId;
  final String name;
  final String? description;
}

/// A god, saint, or holy being within the theology.
class Deity {
  const Deity._({
    required this.deityId,
    required this.name,
    required this.role,
    required this.immortal,
    required this.domains,
    required this.epithets,
    this.parentDeityId,
    this.description,
  });

  factory Deity.validated({
    required String deityId,
    required String name,
    DeityRole role = DeityRole.other,
    List<DivineDomain> domains = const [],
    List<String> epithets = const [],
    bool immortal = true,
    String? parentDeityId,
    String? description,
  }) {
    _requireUniqueIds(domains.map((d) => d.domainId), 'domains', 'domainId');
    return Deity._(
      deityId: _requireTrimmed(deityId, 'deityId'),
      name: _requireTrimmed(name, 'name'),
      role: role,
      immortal: immortal,
      domains: List.unmodifiable(domains),
      epithets: List.unmodifiable(
        _trimUniqueList(epithets, 'epithet', 'epithets', caseInsensitive: true),
      ),
      parentDeityId: _optionalTrimmed(parentDeityId, 'parentDeityId'),
      description: _optionalTrimmed(description, 'description'),
    );
  }

  final String deityId;
  final String name;
  final DeityRole role;
  final bool immortal;
  final List<DivineDomain> domains;
  final List<String> epithets;

  /// Optional lineage link to a senior deity of the same faith.
  final String? parentDeityId;
  final String? description;

  String get roleLabel => role.label;

  bool isOfRole(DeityRole value) => role == value;

  /// Domain ids, sorted ascending, immutable.
  List<String> get domainIds =>
      List.unmodifiable((domains.map((d) => d.domainId).toList()..sort()));

  bool hasDomain(String domainId) {
    final trimmed = domainId.trim();
    return domains.any((d) => d.domainId == trimmed);
  }
}

/// A formal teaching of the faith.
class Doctrine {
  const Doctrine._({
    required this.doctrineId,
    required this.title,
    required this.statement,
    required this.kind,
    this.sourceTextId,
    this.note,
  });

  factory Doctrine.validated({
    required String doctrineId,
    required String title,
    required String statement,
    DoctrineKind kind = DoctrineKind.tenet,
    String? sourceTextId,
    String? note,
  }) {
    return Doctrine._(
      doctrineId: _requireTrimmed(doctrineId, 'doctrineId'),
      title: _requireTrimmed(title, 'title'),
      statement: _requireTrimmed(statement, 'statement'),
      kind: kind,
      sourceTextId: _optionalTrimmed(sourceTextId, 'sourceTextId'),
      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String doctrineId;
  final String title;
  final String statement;
  final DoctrineKind kind;

  /// Optional sacred text this doctrine is drawn from.
  final String? sourceTextId;
  final String? note;

  String get kindLabel => kind.label;
}

/// A prescribed act of worship or observance.
class Ritual {
  const Ritual._({
    required this.ritualId,
    required this.name,
    required this.cadence,
    required this.offerings,
    this.deityId,
    this.description,
  });

  factory Ritual.validated({
    required String ritualId,
    required String name,
    RitualCadence cadence = RitualCadence.annual,
    List<String> offerings = const [],
    String? deityId,
    String? description,
  }) {
    return Ritual._(
      ritualId: _requireTrimmed(ritualId, 'ritualId'),
      name: _requireTrimmed(name, 'name'),
      cadence: cadence,
      offerings: List.unmodifiable(
        _trimUniqueList(offerings, 'offering', 'offerings'),
      ),
      // A communal rite may honor no single deity.
      deityId: _optionalTrimmed(deityId, 'deityId'),
      description: _optionalTrimmed(description, 'description'),
    );
  }

  final String ritualId;
  final String name;
  final RitualCadence cadence;
  final List<String> offerings;
  final String? deityId;
  final String? description;

  String get cadenceLabel => cadence.label;
}

/// An organized religious body: church, order, shrine, clergy house.
class ReligiousInstitution {
  const ReligiousInstitution._({
    required this.institutionId,
    required this.name,
    required this.kind,
    required this.doctrineIds,
    this.headDeityId,
    this.headClericId,
    this.foundedMarker,
    this.note,
  });

  factory ReligiousInstitution.validated({
    required String institutionId,
    required String name,
    InstitutionKind kind = InstitutionKind.church,
    List<String> doctrineIds = const [],
    String? headDeityId,
    String? headClericId,
    String? foundedMarker,
    String? note,
  }) {
    return ReligiousInstitution._(
      institutionId: _requireTrimmed(institutionId, 'institutionId'),
      name: _requireTrimmed(name, 'name'),
      kind: kind,
      doctrineIds: List.unmodifiable(
        _trimUniqueList(doctrineIds, 'doctrineId', 'doctrineIds'),
      ),
      headDeityId: _optionalTrimmed(headDeityId, 'headDeityId'),
      headClericId: _optionalTrimmed(headClericId, 'headClericId'),
      foundedMarker: _optionalTrimmed(foundedMarker, 'foundedMarker'),
      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String institutionId;
  final String name;
  final InstitutionKind kind;
  final List<String> doctrineIds;
  final String? headDeityId;

  /// Id of a registered cleric (external identity; validated elsewhere).
  final String? headClericId;
  final String? foundedMarker;
  final String? note;

  String get kindLabel => kind.label;

  bool teachesDoctrine(String doctrineId) {
    final trimmed = doctrineId.trim();
    return doctrineIds.contains(trimmed);
  }
}

/// A forbidden act, word, or object, with its spiritual gravity.
class Taboo {
  const Taboo._({
    required this.tabooId,
    required this.description,
    required this.severity,
    this.deityId,
    this.atonement,
  });

  factory Taboo.validated({
    required String tabooId,
    required String description,
    TabooSeverity severity = TabooSeverity.mild,
    String? deityId,
    String? atonement,
  }) {
    return Taboo._(
      tabooId: _requireTrimmed(tabooId, 'tabooId'),
      description: _requireTrimmed(description, 'description'),
      severity: severity,
      deityId: _optionalTrimmed(deityId, 'deityId'),
      atonement: _optionalTrimmed(atonement, 'atonement'),
    );
  }

  final String tabooId;
  final String description;
  final TabooSeverity severity;
  final String? deityId;

  /// Optional rite that restores standing after breaking the taboo.
  final String? atonement;

  String get severityLabel => severity.label;
}

/// A scripture or holy writing recognized by the faith.
class SacredText {
  const SacredText._({
    required this.textId,
    required this.title,
    required this.canonicity,
    this.authorship,
    this.note,
  });

  factory SacredText.validated({
    required String textId,
    required String title,
    TextCanonicity canonicity = TextCanonicity.canonical,
    String? authorship,
    String? note,
  }) {
    return SacredText._(
      textId: _requireTrimmed(textId, 'textId'),
      title: _requireTrimmed(title, 'title'),
      canonicity: canonicity,
      authorship: _optionalTrimmed(authorship, 'authorship'),
      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String textId;
  final String title;
  final TextCanonicity canonicity;
  final String? authorship;
  final String? note;

  String get canonicityLabel => canonicity.label;
}

/// A split: an offspring institution breaking away from its parent.
class SchismEvent {
  const SchismEvent._({
    required this.schismId,
    required this.name,
    required this.parentInstitutionId,
    required this.offspringInstitutionId,
    this.doctrineId,
    this.marker,
    this.note,
  });

  factory SchismEvent.validated({
    required String schismId,
    required String name,
    required String parentInstitutionId,
    required String offspringInstitutionId,
    String? doctrineId,
    String? marker,
    String? note,
  }) {
    return SchismEvent._(
      schismId: _requireTrimmed(schismId, 'schismId'),
      name: _requireTrimmed(name, 'name'),
      parentInstitutionId: _requireTrimmed(
        parentInstitutionId,
        'parentInstitutionId',
      ),
      offspringInstitutionId: _requireTrimmed(
        offspringInstitutionId,
        'offspringInstitutionId',
      ),
      // The disputed teaching, when the split hinged on one.
      doctrineId: _optionalTrimmed(doctrineId, 'doctrineId'),
      marker: _optionalTrimmed(marker, 'marker'),
      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String schismId;
  final String name;
  final String parentInstitutionId;
  final String offspringInstitutionId;
  final String? doctrineId;

  /// Story-time marker of when the split happened (free-form, ordered
  /// elsewhere by the timeline system).
  final String? marker;
  final String? note;

  bool tanglesWith(String institutionId) {
    final trimmed = institutionId.trim();
    return parentInstitutionId == trimmed || offspringInstitutionId == trimmed;
  }
}

/// One organized faith and everything it teaches, forbids, and celebrates.
class TheologyRecord {
  const TheologyRecord._({
    required this.theologyId,
    required this.name,
    required this.deities,
    required this.doctrines,
    required this.rituals,
    required this.institutions,
    required this.taboos,
    required this.texts,
    required this.schisms,
    this.summary,
  });

  factory TheologyRecord.validated({
    required String theologyId,
    required String name,
    List<Deity> deities = const [],
    List<Doctrine> doctrines = const [],
    List<Ritual> rituals = const [],
    List<ReligiousInstitution> institutions = const [],
    List<Taboo> taboos = const [],
    List<SacredText> texts = const [],
    List<SchismEvent> schisms = const [],
    String? summary,
  }) {
    _requireUniqueIds(deities.map((d) => d.deityId), 'deities', 'deityId');
    _requireUniqueIds(
      doctrines.map((d) => d.doctrineId),
      'doctrines',
      'doctrineId',
    );
    _requireUniqueIds(rituals.map((r) => r.ritualId), 'rituals', 'ritualId');
    _requireUniqueIds(
      institutions.map((i) => i.institutionId),
      'institutions',
      'institutionId',
    );
    _requireUniqueIds(taboos.map((t) => t.tabooId), 'taboos', 'tabooId');
    _requireUniqueIds(texts.map((t) => t.textId), 'texts', 'textId');
    _requireUniqueIds(schisms.map((s) => s.schismId), 'schisms', 'schismId');

    final deityIds = {for (final d in deities) d.deityId};
    final doctrineIds = {for (final d in doctrines) d.doctrineId};
    final textIds = {for (final t in texts) t.textId};
    final institutionIds = {for (final i in institutions) i.institutionId};

    for (final deity in deities) {
      final parent = deity.parentDeityId;
      if (parent != null && !deityIds.contains(parent)) {
        throw ArgumentError(
          'Deity ${deity.deityId} links to unknown parentDeityId: $parent',
        );
      }
    }
    for (final ritual in rituals) {
      final target = ritual.deityId;
      if (target != null && !deityIds.contains(target)) {
        throw ArgumentError(
          'Ritual ${ritual.ritualId} references unknown deityId: $target',
        );
      }
    }
    for (final taboo in taboos) {
      final target = taboo.deityId;
      if (target != null && !deityIds.contains(target)) {
        throw ArgumentError(
          'Taboo ${taboo.tabooId} references unknown deityId: $target',
        );
      }
    }
    for (final institution in institutions) {
      final head = institution.headDeityId;
      if (head != null && !deityIds.contains(head)) {
        throw ArgumentError(
          'Institution ${institution.institutionId} '
          'references unknown headDeityId: $head',
        );
      }
      for (final ref in institution.doctrineIds) {
        if (!doctrineIds.contains(ref)) {
          throw ArgumentError(
            'Institution ${institution.institutionId} '
            'teaches unknown doctrineId: $ref',
          );
        }
      }
    }
    for (final doctrine in doctrines) {
      final source = doctrine.sourceTextId;
      if (source != null && !textIds.contains(source)) {
        throw ArgumentError(
          'Doctrine ${doctrine.doctrineId} '
          'cites unknown sourceTextId: $source',
        );
      }
    }
    for (final schism in schisms) {
      if (!institutionIds.contains(schism.parentInstitutionId)) {
        throw ArgumentError(
          'Schism ${schism.schismId} splits unknown parent institution: '
          '${schism.parentInstitutionId}',
        );
      }
      if (!institutionIds.contains(schism.offspringInstitutionId)) {
        throw ArgumentError(
          'Schism ${schism.schismId} produces unknown institution: '
          '${schism.offspringInstitutionId}',
        );
      }
      final disputed = schism.doctrineId;
      if (disputed != null && !doctrineIds.contains(disputed)) {
        throw ArgumentError(
          'Schism ${schism.schismId} disputes unknown doctrineId: $disputed',
        );
      }
    }

    return TheologyRecord._(
      theologyId: _requireTrimmed(theologyId, 'theologyId'),
      name: _requireTrimmed(name, 'name'),
      deities: List.unmodifiable(deities),
      doctrines: List.unmodifiable(doctrines),
      rituals: List.unmodifiable(rituals),
      institutions: List.unmodifiable(institutions),
      taboos: List.unmodifiable(taboos),
      texts: List.unmodifiable(texts),
      schisms: List.unmodifiable(schisms),
      summary: _optionalTrimmed(summary, 'summary'),
    );
  }

  final String theologyId;
  final String name;
  final List<Deity> deities;
  final List<Doctrine> doctrines;
  final List<Ritual> rituals;
  final List<ReligiousInstitution> institutions;
  final List<Taboo> taboos;
  final List<SacredText> texts;
  final List<SchismEvent> schisms;
  final String? summary;

  int get deityCount => deities.length;
  int get doctrineCount => doctrines.length;
  int get ritualCount => rituals.length;
  int get institutionCount => institutions.length;
  int get tabooCount => taboos.length;
  int get textCount => texts.length;
  int get schismCount => schisms.length;

  List<String> get deityIds =>
      List.unmodifiable((deities.map((d) => d.deityId).toList()..sort()));
  List<String> get doctrineIds =>
      List.unmodifiable((doctrines.map((d) => d.doctrineId).toList()..sort()));
  List<String> get ritualIds =>
      List.unmodifiable((rituals.map((r) => r.ritualId).toList()..sort()));
  List<String> get institutionIds => List.unmodifiable(
    (institutions.map((i) => i.institutionId).toList()..sort()),
  );
  List<String> get tabooIds =>
      List.unmodifiable((taboos.map((t) => t.tabooId).toList()..sort()));
  List<String> get textIds =>
      List.unmodifiable((texts.map((t) => t.textId).toList()..sort()));
  List<String> get schismIds =>
      List.unmodifiable((schisms.map((s) => s.schismId).toList()..sort()));

  bool hasDeity(String deityId) => deityIds.contains(deityId.trim());
  bool hasDoctrine(String doctrineId) =>
      doctrineIds.contains(doctrineId.trim());
  bool hasRitual(String ritualId) => ritualIds.contains(ritualId.trim());
  bool hasInstitution(String institutionId) =>
      institutionIds.contains(institutionId.trim());
  bool hasTaboo(String tabooId) => tabooIds.contains(tabooId.trim());
  bool hasText(String textId) => textIds.contains(textId.trim());
  bool hasSchism(String schismId) => schismIds.contains(schismId.trim());

  String? deityNameFor(String deityId) {
    final trimmed = deityId.trim();
    for (final deity in deities) {
      if (deity.deityId == trimmed) return deity.name;
    }
    return null;
  }

  /// Deity ids holding [role], sorted ascending.
  List<String> deitiesWithRole(DeityRole role) => List.unmodifiable(
    (deities.where((d) => d.role == role).map((d) => d.deityId).toList()
      ..sort()),
  );

  /// Deity ids whose domain set contains [domainId], sorted ascending.
  List<String> deityIdsGoverningDomain(String domainId) {
    final trimmed = domainId.trim();
    return List.unmodifiable(
      (deities.where((d) => d.hasDomain(trimmed)).map((d) => d.deityId).toList()
        ..sort()),
    );
  }

  /// Ritual ids honoring [deityId], sorted ascending.
  List<String> ritualIdsForDeity(String deityId) {
    final trimmed = deityId.trim();
    return List.unmodifiable(
      (rituals
          .where((r) => r.deityId == trimmed)
          .map((r) => r.ritualId)
          .toList()
        ..sort()),
    );
  }

  /// Institution ids headed by [deityId], sorted ascending.
  List<String> institutionIdsForDeity(String deityId) {
    final trimmed = deityId.trim();
    return List.unmodifiable(
      (institutions
          .where((i) => i.headDeityId == trimmed)
          .map((i) => i.institutionId)
          .toList()
        ..sort()),
    );
  }

  /// Institution ids teaching [doctrineId], sorted ascending.
  List<String> institutionIdsTeaching(String doctrineId) {
    final trimmed = doctrineId.trim();
    return List.unmodifiable(
      (institutions
          .where((i) => i.teachesDoctrine(trimmed))
          .map((i) => i.institutionId)
          .toList()
        ..sort()),
    );
  }

  /// Taboos at or above [severity], sorted by tabooId.
  List<Taboo> taboosAtLeast(TabooSeverity severity) => List.unmodifiable(
    (taboos.where((t) => t.severity.weight >= severity.weight).toList()
      ..sort((a, b) => a.tabooId.compareTo(b.tabooId))),
  );

  /// Heaviest taboo present; null when there are none.
  TabooSeverity? get maxTabooSeverity {
    TabooSeverity? max;
    for (final taboo in taboos) {
      if (max == null || taboo.severity.weight > max.weight) {
        max = taboo.severity;
      }
    }
    return max;
  }

  /// Text ids at or above [canonicity], sorted ascending.
  List<String> textIdsAtLeast(TextCanonicity canonicity) => List.unmodifiable(
    (texts
        .where((t) => t.canonicity.weight >= canonicity.weight)
        .map((t) => t.textId)
        .toList()
      ..sort()),
  );

  /// Schisms involving [institutionId] as either side, sorted by schismId.
  List<SchismEvent> schismsSplittingFrom(String institutionId) =>
      List.unmodifiable(
        (schisms.where((s) => s.tanglesWith(institutionId)).toList()
          ..sort((a, b) => a.schismId.compareTo(b.schismId))),
      );
}

/// Deterministic filter over theology records; null fields do not constrain.
class TheologyQuery {
  const TheologyQuery({
    this.role,
    this.doctrineKind,
    this.cadence,
    this.institutionKind,
    this.minTabooSeverity,
    this.minCanonicity,
  });

  final DeityRole? role;
  final DoctrineKind? doctrineKind;
  final RitualCadence? cadence;
  final InstitutionKind? institutionKind;
  final TabooSeverity? minTabooSeverity;
  final TextCanonicity? minCanonicity;

  bool get isEmpty =>
      role == null &&
      doctrineKind == null &&
      cadence == null &&
      institutionKind == null &&
      minTabooSeverity == null &&
      minCanonicity == null;

  bool matches(TheologyRecord record) {
    if (role != null && record.deitiesWithRole(role!).isEmpty) {
      return false;
    }
    if (doctrineKind != null &&
        !record.doctrines.any((d) => d.kind == doctrineKind)) {
      return false;
    }
    if (cadence != null && !record.rituals.any((r) => r.cadence == cadence)) {
      return false;
    }
    if (institutionKind != null &&
        !record.institutions.any((i) => i.kind == institutionKind)) {
      return false;
    }
    if (minTabooSeverity != null) {
      final max = record.maxTabooSeverity;
      if (max == null || max.weight < minTabooSeverity!.weight) {
        return false;
      }
    }
    if (minCanonicity != null &&
        record.textIdsAtLeast(minCanonicity!).isEmpty) {
      return false;
    }
    return true;
  }

  String describe() {
    if (isEmpty) return 'TheologyQuery(no filters)';
    final parts = <String>[
      if (role != null) 'role: ${role!.label}',
      if (doctrineKind != null) 'doctrineKind: ${doctrineKind!.label}',
      if (cadence != null) 'cadence: ${cadence!.label}',
      if (institutionKind != null) 'institutionKind: ${institutionKind!.label}',
      if (minTabooSeverity != null)
        'minTabooSeverity: ${minTabooSeverity!.label}',
      if (minCanonicity != null) 'minCanonicity: ${minCanonicity!.label}',
    ];
    return 'TheologyQuery(${parts.join(', ')})';
  }
}

/// Immutable collection of theologies with deterministic reverse indexes.
class TheologyCatalog {
  const TheologyCatalog._(this._records);

  factory TheologyCatalog.empty() => const TheologyCatalog._([]);

  factory TheologyCatalog.withRecords(List<TheologyRecord> records) {
    _requireUniqueIds(
      records.map((r) => r.theologyId),
      'records',
      'theologyId',
    );
    final sorted = records.toList()
      ..sort((a, b) => a.theologyId.compareTo(b.theologyId));
    return TheologyCatalog._(List.unmodifiable(sorted));
  }

  final List<TheologyRecord> _records;

  List<TheologyRecord> get records => _records;

  bool get isEmpty => _records.isEmpty;

  int get length => _records.length;

  List<String> get theologyIds =>
      List.unmodifiable(_records.map((r) => r.theologyId));

  TheologyRecord? recordFor(String theologyId) {
    final trimmed = theologyId.trim();
    for (final record in _records) {
      if (record.theologyId == trimmed) return record;
    }
    return null;
  }

  /// Sum of deities across every record.
  int get totalDeityCount =>
      _records.fold<int>(0, (acc, r) => acc + r.deityCount);

  /// Theology ids containing a deity with [value], sorted, deduped.
  List<String> theologyIdsWithDeityRole(DeityRole value) => List.unmodifiable(
    (_records
        .where((r) => r.deitiesWithRole(value).isNotEmpty)
        .map((r) => r.theologyId)
        .toList()
      ..sort()),
  );

  /// Institution ids on either side of any schism, sorted, deduped.
  List<String> institutionIdsInvolvedInSchisms() {
    final ids = <String>{};
    for (final record in _records) {
      for (final schism in record.schisms) {
        ids.add(schism.parentInstitutionId);
        ids.add(schism.offspringInstitutionId);
      }
    }
    return List.unmodifiable((ids.toList()..sort()));
  }

  /// Records matching [query], sorted by theologyId.
  List<TheologyRecord> query(TheologyQuery query) {
    final matched = _records.where(query.matches).toList()
      ..sort((a, b) => a.theologyId.compareTo(b.theologyId));
    return List.unmodifiable(matched);
  }
}
