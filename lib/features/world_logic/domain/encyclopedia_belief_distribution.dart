// Sprint 111.27 - Belief Distribution & Historical Change.
//
// Domain-only contract recording where a faith is held (per region, per
// time range, per believing group) and how it changes over history:
// conversions, reforms, persecution, and syncretism. Time ranges use
// free-form story markers ordered by an optional sequence, matching the
// convention of SchismEvent.marker in 111.26 — absolute chronology stays
// with the timeline system.
//
// Consumes GroupStance from 111.24 (encyclopedia_myth).
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

import 'package:void_scriptor/features/world_logic/domain/encyclopedia_myth.dart';

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

/// How a community or convert reached a new faith.
enum ConversionMechanism {
  missionary('Missionary'),
  trade('Trade'),
  conquest('Conquest'),
  decree('Decree'),
  marriage('Marriage'),
  personalRevelation('Personal revelation'),
  other('Other');

  const ConversionMechanism(this.label);

  final String label;
}

/// What a reform touched.
enum ReformKind {
  doctrinal('Doctrinal'),
  liturgical('Liturgical'),
  organizational('Organizational'),
  moral('Moral'),
  calendar('Calendar'),
  other('Other');

  const ReformKind(this.label);

  final String label;
}

/// Escalation ladder of hostility toward a faith; weights strictly increase.
enum PersecutionSeverity {
  discrimination('Discrimination', 1),
  propertySeizure('Property seizure', 2),
  imprisonment('Imprisonment', 3),
  execution('Execution', 4),
  extermination('Extermination', 5);

  const PersecutionSeverity(this.label, this.weight);

  final String label;
  final int weight;

  bool atLeast(PersecutionSeverity other) => weight >= other.weight;
}

/// A named stretch of story time that a distribution entry or change event
/// is scoped to. [toMarker] null means the span is still ongoing.
class BeliefTimeRange {
  const BeliefTimeRange._({
    required this.rangeId,
    required this.fromMarker,
    required this.toMarker,
    required this.sequence,
  });

  factory BeliefTimeRange.validated({
    required String rangeId,
    required String fromMarker,
    String? toMarker,
    int? sequence,
  }) {
    return BeliefTimeRange._(
      rangeId: _requireTrimmed(rangeId, 'rangeId'),
      fromMarker: _requireTrimmed(fromMarker, 'fromMarker'),
      toMarker: _optionalTrimmed(toMarker, 'toMarker'),
      sequence: sequence,
    );
  }

  final String rangeId;
  final String fromMarker;

  /// End marker; null while the span is ongoing.
  final String? toMarker;

  /// Optional chronological rank supplied by the timeline system; ranges
  /// without one sort after every sequenced range.
  final int? sequence;

  bool get isOngoing => toMarker == null;

  /// Order ranges by sequence (nulls last), then rangeId ascending.
  static int compare(BeliefTimeRange a, BeliefTimeRange b) {
    final sa = a.sequence;
    final sb = b.sequence;
    if (sa != null && sb != null && sa != sb) return sa.compareTo(sb);
    if (sa == null && sb != null) return 1;
    if (sa != null && sb == null) return -1;
    return a.rangeId.compareTo(b.rangeId);
  }

  String describe() {
    final end = toMarker;
    return end == null
        ? '$fromMarker..ongoing ($rangeId)'
        : '$fromMarker..$end ($rangeId)';
  }
}

/// How strongly a region holds the faith during one time range.
class RegionalDistribution {
  const RegionalDistribution._({
    required this.regionId,
    required this.timeRangeId,
    required this.adherents,
    required this.population,
    required this.groupIds,
    required this.stance,
    required this.note,
  });

  factory RegionalDistribution.validated({
    required String regionId,
    required String timeRangeId,
    required int adherents,
    int? population,
    List<String> groupIds = const [],
    GroupStance stance = GroupStance.devout,
    String? note,
  }) {
    if (adherents < 0) {
      throw ArgumentError.value(
        adherents,
        'adherents',
        'adherents must be >= 0',
      );
    }
    if (population != null && population < 0) {
      throw ArgumentError.value(
        population,
        'population',
        'population must be >= 0',
      );
    }
    if (population != null && population > 0 && adherents > population) {
      throw ArgumentError.value(
        adherents,
        'adherents',
        'adherents cannot exceed population',
      );
    }
    _requireUniqueIds(groupIds, 'groupIds', 'groupId');
    return RegionalDistribution._(
      regionId: _requireTrimmed(regionId, 'regionId'),
      timeRangeId: _requireTrimmed(timeRangeId, 'timeRangeId'),
      adherents: adherents,
      population: population,
      groupIds: List.unmodifiable(groupIds.toList()..sort()),
      stance: stance,
      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String regionId;
  final String timeRangeId;
  final int adherents;
  final int? population;

  /// Believing groups counted in this region for this span.
  final List<String> groupIds;
  final GroupStance stance;
  final String? note;

  String get stanceLabel => stance.label;

  /// Share of the population holding the faith, or null when the
  /// population is unknown or zero.
  double? get share {
    final pop = population;
    if (pop == null || pop <= 0) return null;
    return adherents / pop;
  }

  bool countsGroup(String groupId) {
    final trimmed = groupId.trim();
    return groupIds.contains(trimmed);
  }
}

/// A change of allegiance from one faith to another.
class ConversionEvent {
  const ConversionEvent._({
    required this.conversionId,
    required this.name,
    required this.fromFaithId,
    required this.toFaithId,
    required this.mechanism,
    required this.timeRangeId,
    required this.groupIds,
    required this.scale,
    required this.note,
  });

  factory ConversionEvent.validated({
    required String conversionId,
    required String name,
    required String fromFaithId,
    required String toFaithId,
    ConversionMechanism mechanism = ConversionMechanism.missionary,
    String? timeRangeId,
    List<String> groupIds = const [],
    int? scale,
    String? note,
  }) {
    final from = _requireTrimmed(fromFaithId, 'fromFaithId');
    final to = _requireTrimmed(toFaithId, 'toFaithId');
    if (from == to) {
      throw ArgumentError('fromFaithId and toFaithId must differ');
    }
    if (scale != null && scale < 0) {
      throw ArgumentError.value(scale, 'scale', 'scale must be >= 0');
    }
    _requireUniqueIds(groupIds, 'groupIds', 'groupId');
    return ConversionEvent._(
      conversionId: _requireTrimmed(conversionId, 'conversionId'),
      name: _requireTrimmed(name, 'name'),
      fromFaithId: from,
      toFaithId: to,
      mechanism: mechanism,
      timeRangeId: _optionalTrimmed(timeRangeId, 'timeRangeId'),
      groupIds: List.unmodifiable(groupIds.toList()..sort()),
      scale: scale,
      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String conversionId;
  final String name;
  final String fromFaithId;
  final String toFaithId;
  final ConversionMechanism mechanism;
  final String? timeRangeId;
  final List<String> groupIds;

  /// Rough number of converts, when the record claims one.
  final int? scale;
  final String? note;

  String get mechanismLabel => mechanism.label;

  bool involves(String faithId) {
    final trimmed = faithId.trim();
    return fromFaithId == trimmed || toFaithId == trimmed;
  }
}

/// An internal change of teaching, practice, or structure.
class ReformEvent {
  const ReformEvent._({
    required this.reformId,
    required this.name,
    required this.kind,
    required this.institutionId,
    required this.doctrineIds,
    required this.timeRangeId,
    required this.note,
  });

  factory ReformEvent.validated({
    required String reformId,
    required String name,
    ReformKind kind = ReformKind.doctrinal,
    String? institutionId,
    List<String> doctrineIds = const [],
    String? timeRangeId,
    String? note,
  }) {
    _requireUniqueIds(doctrineIds, 'doctrineIds', 'doctrineId');
    return ReformEvent._(
      reformId: _requireTrimmed(reformId, 'reformId'),
      name: _requireTrimmed(name, 'name'),
      kind: kind,
      institutionId: _optionalTrimmed(institutionId, 'institutionId'),
      doctrineIds: List.unmodifiable(doctrineIds.toList()..sort()),
      timeRangeId: _optionalTrimmed(timeRangeId, 'timeRangeId'),
      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String reformId;
  final String name;
  final ReformKind kind;

  /// Institution that carried the reform, when it was institutional.
  final String? institutionId;

  /// Doctrines touched by the reform.
  final List<String> doctrineIds;
  final String? timeRangeId;
  final String? note;

  String get kindLabel => kind.label;

  bool touchesDoctrine(String doctrineId) {
    final trimmed = doctrineId.trim();
    return doctrineIds.contains(trimmed);
  }
}

/// Hostility directed at a faith by a perpetrator.
class PersecutionEvent {
  const PersecutionEvent._({
    required this.persecutionId,
    required this.name,
    required this.perpetrator,
    required this.targetFaithId,
    required this.severity,
    required this.timeRangeId,
    required this.estimatedVictims,
    required this.note,
  });

  factory PersecutionEvent.validated({
    required String persecutionId,
    required String name,
    required String perpetrator,
    required String targetFaithId,
    PersecutionSeverity severity = PersecutionSeverity.discrimination,
    String? timeRangeId,
    int? estimatedVictims,
    String? note,
  }) {
    if (estimatedVictims != null && estimatedVictims < 0) {
      throw ArgumentError.value(
        estimatedVictims,
        'estimatedVictims',
        'estimatedVictims must be >= 0',
      );
    }
    return PersecutionEvent._(
      persecutionId: _requireTrimmed(persecutionId, 'persecutionId'),
      name: _requireTrimmed(name, 'name'),
      perpetrator: _requireTrimmed(perpetrator, 'perpetrator'),
      targetFaithId: _requireTrimmed(targetFaithId, 'targetFaithId'),
      severity: severity,
      timeRangeId: _optionalTrimmed(timeRangeId, 'timeRangeId'),
      estimatedVictims: estimatedVictims,
      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String persecutionId;
  final String name;
  final String perpetrator;
  final String targetFaithId;
  final PersecutionSeverity severity;
  final String? timeRangeId;
  final int? estimatedVictims;
  final String? note;

  String get severityLabel => severity.label;

  bool targets(String faithId) {
    final trimmed = faithId.trim();
    return targetFaithId == trimmed;
  }
}

/// Two or more faiths blending into a new or reshaped one.
class SyncretismEvent {
  const SyncretismEvent._({
    required this.syncretismId,
    required this.name,
    required this.sourceFaithIds,
    required this.resultingFaithId,
    required this.sharedElements,
    required this.timeRangeId,
    required this.note,
  });

  factory SyncretismEvent.validated({
    required String syncretismId,
    required String name,
    required List<String> sourceFaithIds,
    required String resultingFaithId,
    List<String> sharedElements = const [],
    String? timeRangeId,
    String? note,
  }) {
    if (sourceFaithIds.length < 2) {
      throw ArgumentError('syncretism needs at least two source faiths');
    }
    final sources = sourceFaithIds
        .map((s) => _requireTrimmed(s, 'sourceFaithIds'))
        .toList();
    _requireUniqueIds(sources, 'sourceFaithIds', 'sourceFaithId');
    final result = _requireTrimmed(resultingFaithId, 'resultingFaithId');
    if (sources.contains(result)) {
      throw ArgumentError(
        'resultingFaithId must not be one of the source faiths: $result',
      );
    }
    final elements = sharedElements
        .map((e) => _requireTrimmed(e, 'sharedElements'))
        .toList();
    _requireUniqueIds(elements, 'sharedElements', 'element');
    return SyncretismEvent._(
      syncretismId: _requireTrimmed(syncretismId, 'syncretismId'),
      name: _requireTrimmed(name, 'name'),
      sourceFaithIds: List.unmodifiable(sources.toList()..sort()),
      resultingFaithId: result,
      sharedElements: List.unmodifiable(elements.toList()..sort()),
      timeRangeId: _optionalTrimmed(timeRangeId, 'timeRangeId'),
      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String syncretismId;
  final String name;
  final List<String> sourceFaithIds;
  final String resultingFaithId;

  /// Rites, figures, or symbols the blended faith carries over.
  final List<String> sharedElements;
  final String? timeRangeId;
  final String? note;

  bool involves(String faithId) {
    final trimmed = faithId.trim();
    return resultingFaithId == trimmed || sourceFaithIds.contains(trimmed);
  }
}

/// One faith's geographic spread and historical change over its time ranges.
class BeliefDistributionRecord {
  const BeliefDistributionRecord._({
    required this.distributionId,
    required this.theologyId,
    required this.timeRanges,
    required this.regionalDistributions,
    required this.conversions,
    required this.reforms,
    required this.persecutions,
    required this.syncretisms,
  });

  factory BeliefDistributionRecord.validated({
    required String distributionId,
    required String theologyId,
    List<BeliefTimeRange> timeRanges = const [],
    List<RegionalDistribution> regionalDistributions = const [],
    List<ConversionEvent> conversions = const [],
    List<ReformEvent> reforms = const [],
    List<PersecutionEvent> persecutions = const [],
    List<SyncretismEvent> syncretisms = const [],
  }) {
    _requireUniqueIds(
      timeRanges.map((r) => r.rangeId),
      'timeRanges',
      'rangeId',
    );
    _requireUniqueIds(
      regionalDistributions.map((e) => '${e.regionId}|${e.timeRangeId}'),
      'regionalDistributions',
      'regionId+timeRangeId',
    );
    _requireUniqueIds(
      conversions.map((c) => c.conversionId),
      'conversions',
      'conversionId',
    );
    _requireUniqueIds(reforms.map((r) => r.reformId), 'reforms', 'reformId');
    _requireUniqueIds(
      persecutions.map((p) => p.persecutionId),
      'persecutions',
      'persecutionId',
    );
    _requireUniqueIds(
      syncretisms.map((s) => s.syncretismId),
      'syncretisms',
      'syncretismId',
    );
    final declaredRanges = timeRanges.map((r) => r.rangeId).toSet();
    for (final entry in regionalDistributions) {
      if (!declaredRanges.contains(entry.timeRangeId)) {
        throw ArgumentError(
          'regional distribution ${entry.regionId} references unknown '
          'time range ${entry.timeRangeId}',
        );
      }
    }
    for (final event in conversions) {
      _requireKnownRange(
        event.timeRangeId,
        declaredRanges,
        'conversion',
        event.conversionId,
      );
    }
    for (final event in reforms) {
      _requireKnownRange(
        event.timeRangeId,
        declaredRanges,
        'reform',
        event.reformId,
      );
    }
    for (final event in persecutions) {
      _requireKnownRange(
        event.timeRangeId,
        declaredRanges,
        'persecution',
        event.persecutionId,
      );
    }
    for (final event in syncretisms) {
      _requireKnownRange(
        event.timeRangeId,
        declaredRanges,
        'syncretism',
        event.syncretismId,
      );
    }
    return BeliefDistributionRecord._(
      distributionId: _requireTrimmed(distributionId, 'distributionId'),
      theologyId: _requireTrimmed(theologyId, 'theologyId'),
      timeRanges: List.unmodifiable(timeRanges),
      regionalDistributions: List.unmodifiable(regionalDistributions),
      conversions: List.unmodifiable(conversions),
      reforms: List.unmodifiable(reforms),
      persecutions: List.unmodifiable(persecutions),
      syncretisms: List.unmodifiable(syncretisms),
    );
  }

  static void _requireKnownRange(
    String? timeRangeId,
    Set<String> declared,
    String what,
    String id,
  ) {
    if (timeRangeId != null && !declared.contains(timeRangeId)) {
      throw ArgumentError(
        '$what $id references unknown time range $timeRangeId',
      );
    }
  }

  final String distributionId;

  /// The faith (111.26 theology record) this distribution tracks.
  final String theologyId;
  final List<BeliefTimeRange> timeRanges;
  final List<RegionalDistribution> regionalDistributions;
  final List<ConversionEvent> conversions;
  final List<ReformEvent> reforms;
  final List<PersecutionEvent> persecutions;
  final List<SyncretismEvent> syncretisms;

  int get timeRangeCount => timeRanges.length;
  int get regionEntryCount => regionalDistributions.length;
  int get conversionCount => conversions.length;
  int get reformCount => reforms.length;
  int get persecutionCount => persecutions.length;
  int get syncretismCount => syncretisms.length;

  /// Conversion + reform + persecution + syncretism events.
  int get totalEventCount =>
      conversions.length +
      reforms.length +
      persecutions.length +
      syncretisms.length;

  List<String> get timeRangeIds =>
      List.unmodifiable(timeRanges.map((r) => r.rangeId));

  /// Distinct region ids, sorted ascending, immutable.
  List<String> get regionIds => List.unmodifiable(
    (regionalDistributions.map((e) => e.regionId).toSet().toList())..sort(),
  );

  /// Every faith id named by a conversion, persecution, or syncretism,
  /// sorted.
  List<String> get faithIdsMentioned {
    final ids = <String>{};
    for (final c in conversions) {
      ids.add(c.fromFaithId);
      ids.add(c.toFaithId);
    }
    for (final p in persecutions) {
      ids.add(p.targetFaithId);
    }
    for (final s in syncretisms) {
      ids.addAll(s.sourceFaithIds);
      ids.add(s.resultingFaithId);
    }
    return List.unmodifiable(ids.toList()..sort());
  }

  /// Sum of adherents across all region entries.
  int get totalAdherents =>
      regionalDistributions.fold<int>(0, (acc, e) => acc + e.adherents);

  /// Region with the most adherents; ties break on regionId ascending.
  /// Null when no entries exist.
  String? get dominantRegion {
    if (regionalDistributions.isEmpty) return null;
    final totals = <String, int>{};
    for (final e in regionalDistributions) {
      totals[e.regionId] = (totals[e.regionId] ?? 0) + e.adherents;
    }
    final ranked = totals.entries.toList()
      ..sort((a, b) {
        final byAdherents = b.value.compareTo(a.value);
        if (byAdherents != 0) return byAdherents;
        return a.key.compareTo(b.key);
      });
    return ranked.first.key;
  }

  /// Mean computed share across entries that know their population;
  /// null when none do.
  double? get averageShare {
    final shares = regionalDistributions
        .map((e) => e.share)
        .whereType<double>()
        .toList();
    if (shares.isEmpty) return null;
    return shares.reduce((a, b) => a + b) / shares.length;
  }

  List<RegionalDistribution> entriesForRegion(String regionId) {
    final trimmed = regionId.trim();
    return List.unmodifiable(
      regionalDistributions.where((e) => e.regionId == trimmed),
    );
  }

  List<RegionalDistribution> entriesForTimeRange(String timeRangeId) {
    final trimmed = timeRangeId.trim();
    return List.unmodifiable(
      regionalDistributions.where((e) => e.timeRangeId == trimmed),
    );
  }

  /// Range ids whose span has no end marker, sorted.
  List<String> get ongoingRangeIds => List.unmodifiable(
    (timeRanges.where((r) => r.isOngoing).map((r) => r.rangeId).toList())
      ..sort(),
  );

  /// Time ranges ordered by sequence (nulls last), then id.
  List<BeliefTimeRange> get sortedTimeRanges =>
      List.unmodifiable(timeRanges.toList()..sort(BeliefTimeRange.compare));

  BeliefTimeRange? timeRangeFor(String rangeId) {
    final trimmed = rangeId.trim();
    for (final range in timeRanges) {
      if (range.rangeId == trimmed) return range;
    }
    return null;
  }

  List<ConversionEvent> conversionsWithMechanism(
    ConversionMechanism mechanism,
  ) => List.unmodifiable(conversions.where((c) => c.mechanism == mechanism));

  /// Reform ids carried by [institutionId], sorted.
  List<String> reformIdsForInstitution(String institutionId) {
    final trimmed = institutionId.trim();
    return List.unmodifiable(
      reforms
          .where((r) => r.institutionId == trimmed)
          .map((r) => r.reformId)
          .toList()
        ..sort(),
    );
  }

  List<PersecutionEvent> persecutionsAtLeast(PersecutionSeverity severity) =>
      List.unmodifiable(
        persecutions.where((p) => p.severity.atLeast(severity)),
      );

  /// Worst persecution recorded; null when there are none.
  PersecutionSeverity? get maxPersecutionSeverity {
    PersecutionSeverity? max;
    for (final p in persecutions) {
      if (max == null || p.severity.weight > max.weight) max = p.severity;
    }
    return max;
  }

  List<SyncretismEvent> syncretismsInvolvingFaith(String faithId) {
    final trimmed = faithId.trim();
    return List.unmodifiable(syncretisms.where((s) => s.involves(trimmed)));
  }
}

/// Filter over distribution records; null fields do not constrain.
class BeliefDistributionQuery {
  const BeliefDistributionQuery({
    this.regionId,
    this.mechanism,
    this.reformKind,
    this.minSeverity,
    this.faithId,
  });

  final String? regionId;
  final ConversionMechanism? mechanism;
  final ReformKind? reformKind;
  final PersecutionSeverity? minSeverity;
  final String? faithId;

  bool get isEmpty =>
      regionId == null &&
      mechanism == null &&
      reformKind == null &&
      minSeverity == null &&
      faithId == null;

  bool matches(BeliefDistributionRecord record) {
    final region = regionId?.trim();
    if (region != null && region.isNotEmpty) {
      if (!record.regionalDistributions.any((e) => e.regionId == region)) {
        return false;
      }
    }
    if (mechanism != null &&
        record.conversionsWithMechanism(mechanism!).isEmpty) {
      return false;
    }
    if (reformKind != null &&
        !record.reforms.any((r) => r.kind == reformKind)) {
      return false;
    }
    if (minSeverity != null &&
        record.persecutionsAtLeast(minSeverity!).isEmpty) {
      return false;
    }
    final faith = faithId?.trim();
    if (faith != null && faith.isNotEmpty) {
      final mentioned =
          record.faithIdsMentioned.contains(faith) ||
          record.syncretismsInvolvingFaith(faith).isNotEmpty;
      if (!mentioned) return false;
    }
    return true;
  }

  String describe() {
    if (isEmpty) return 'BeliefDistributionQuery(no filters)';
    final parts = <String>[
      if (regionId != null) 'region: ${regionId!.trim()}',
      if (mechanism != null) 'mechanism: ${mechanism!.label}',
      if (reformKind != null) 'reformKind: ${reformKind!.label}',
      if (minSeverity != null) 'minSeverity: ${minSeverity!.label}',
      if (faithId != null) 'faith: ${faithId!.trim()}',
    ];
    return 'BeliefDistributionQuery(${parts.join(', ')})';
  }
}

/// Immutable collection of distribution records keyed by distribution id.
class BeliefDistributionCatalog {
  const BeliefDistributionCatalog._(this._records);

  factory BeliefDistributionCatalog.empty() =>
      const BeliefDistributionCatalog._([]);

  factory BeliefDistributionCatalog.withRecords(
    List<BeliefDistributionRecord> records,
  ) {
    _requireUniqueIds(
      records.map((r) => r.distributionId),
      'records',
      'distributionId',
    );
    final sorted = records.toList()
      ..sort((a, b) => a.distributionId.compareTo(b.distributionId));
    return BeliefDistributionCatalog._(List.unmodifiable(sorted));
  }

  final List<BeliefDistributionRecord> _records;

  List<BeliefDistributionRecord> get records => _records;

  List<String> get distributionIds =>
      List.unmodifiable(_records.map((r) => r.distributionId));

  BeliefDistributionRecord? recordFor(String distributionId) {
    final trimmed = distributionId.trim();
    for (final record in _records) {
      if (record.distributionId == trimmed) return record;
    }
    return null;
  }

  int get totalRegionEntryCount =>
      _records.fold<int>(0, (acc, r) => acc + r.regionEntryCount);

  int get totalEventCount =>
      _records.fold<int>(0, (acc, r) => acc + r.totalEventCount);

  /// Distribution ids holding an entry for [regionId], sorted.
  List<String> distributionIdsForRegion(String regionId) {
    final trimmed = regionId.trim();
    return List.unmodifiable(
      _records
          .where(
            (r) => r.regionalDistributions.any((e) => e.regionId == trimmed),
          )
          .map((r) => r.distributionId)
          .toList()
        ..sort(),
    );
  }

  /// Distribution ids naming [faithId] in a conversion or syncretism.
  List<String> distributionIdsMentioningFaith(String faithId) {
    final trimmed = faithId.trim();
    return List.unmodifiable(
      _records
          .where(
            (r) =>
                r.faithIdsMentioned.contains(trimmed) ||
                r.syncretismsInvolvingFaith(trimmed).isNotEmpty,
          )
          .map((r) => r.distributionId)
          .toList()
        ..sort(),
    );
  }

  List<String> distributionIdsWithPersecutionAtLeast(
    PersecutionSeverity severity,
  ) => List.unmodifiable(
    _records
        .where((r) => r.persecutions.any((p) => p.severity.atLeast(severity)))
        .map((r) => r.distributionId)
        .toList()
      ..sort(),
  );

  /// Records matching [query], sorted by distributionId.
  List<BeliefDistributionRecord> query(BeliefDistributionQuery q) =>
      List.unmodifiable(_records.where(q.matches));
}
