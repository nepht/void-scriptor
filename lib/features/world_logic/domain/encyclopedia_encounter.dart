// Sprint 111.18 - Encounter and Observation Journal.
//
// Domain-only contract for bestiary encounter and observation records:
// encounter events, witnesses, time and location, outcome, reliability,
// and scene links.
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

String _requireTrimmed(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return value.trim();
}

/// A witness to an encounter, with an optional note.
class EncounterWitness {
  const EncounterWitness._({
    required this.witnessId,
    required this.name,
    this.note,
  });

  factory EncounterWitness.validated({
    required String witnessId,
    required String name,
    String? note,
  }) {
    final trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.isEmpty) {
      throw ArgumentError('note must be non-empty when provided');
    }
    return EncounterWitness._(
      witnessId: _requireTrimmed(witnessId, 'witnessId'),
      name: _requireTrimmed(name, 'name'),
      note: trimmedNote,
    );
  }

  final String witnessId;
  final String name;
  final String? note;
}

/// The location where an encounter happened, with an optional region.
class EncounterLocation {
  const EncounterLocation._({
    required this.locationId,
    required this.name,
    this.region,
  });

  factory EncounterLocation.validated({
    required String locationId,
    required String name,
    String? region,
  }) {
    final trimmedRegion = region?.trim();
    if (trimmedRegion != null && trimmedRegion.isEmpty) {
      throw ArgumentError('region must be non-empty when provided');
    }
    return EncounterLocation._(
      locationId: _requireTrimmed(locationId, 'locationId'),
      name: _requireTrimmed(name, 'name'),
      region: trimmedRegion,
    );
  }

  final String locationId;
  final String name;
  final String? region;
}

/// What happened during an encounter.
enum EncounterOutcome {
  observed('Observed'),
  engaged('Engaged'),
  attacked('Attacked'),
  fled('Fled'),
  captured('Captured'),
  inconclusive('Inconclusive');

  const EncounterOutcome(this.label);

  final String label;
}

/// How reliable an encounter report is.
enum ReliabilityLevel {
  unverified('Unverified'),
  single('Single source'),
  corroborated('Corroborated'),
  confirmed('Confirmed');

  const ReliabilityLevel(this.label);

  final String label;
}

/// A link to a story scene where the encounter is relevant.
class SceneLink {
  const SceneLink._({required this.sceneId});

  factory SceneLink.validated({required String sceneId}) {
    return SceneLink._(sceneId: _requireTrimmed(sceneId, 'sceneId'));
  }

  final String sceneId;
}

/// Immutable encounter record. Optional collections are guarded against
/// duplicate identity keys.
class EncounterRecord {
  const EncounterRecord._({
    required this.encounterId,
    required this.speciesId,
    required this.witnesses,
    required this.sceneLinks,
    this.location,
    this.timeDescription,
    this.outcome,
    this.reliability,
    this.summary,
  });

  factory EncounterRecord.validated({
    required String encounterId,
    required String speciesId,
    List<EncounterWitness> witnesses = const [],
    EncounterLocation? location,
    String? timeDescription,
    EncounterOutcome? outcome,
    ReliabilityLevel? reliability,
    String? summary,
    List<SceneLink> sceneLinks = const [],
  }) {
    final witnessIds = <String, String>{};
    for (final w in witnesses) {
      if (witnessIds.containsKey(w.witnessId)) {
        throw ArgumentError('duplicate witnessId: ${w.witnessId}');
      }
      witnessIds[w.witnessId] = w.witnessId;
    }
    final sceneIds = <String, String>{};
    for (final s in sceneLinks) {
      if (sceneIds.containsKey(s.sceneId)) {
        throw ArgumentError('duplicate sceneId: ${s.sceneId}');
      }
      sceneIds[s.sceneId] = s.sceneId;
    }
    final trimmedTime = timeDescription?.trim();
    if (trimmedTime != null && trimmedTime.isEmpty) {
      throw ArgumentError('timeDescription must be non-empty when provided');
    }
    final trimmedSummary = summary?.trim();
    if (trimmedSummary != null && trimmedSummary.isEmpty) {
      throw ArgumentError('summary must be non-empty when provided');
    }
    return EncounterRecord._(
      encounterId: _requireTrimmed(encounterId, 'encounterId'),
      speciesId: _requireTrimmed(speciesId, 'speciesId'),
      witnesses: List.unmodifiable(witnesses),
      sceneLinks: List.unmodifiable(sceneLinks),
      location: location,
      timeDescription: trimmedTime,
      outcome: outcome,
      reliability: reliability,
      summary: trimmedSummary,
    );
  }

  final String encounterId;
  final String speciesId;
  final List<EncounterWitness> witnesses;
  final EncounterLocation? location;
  final String? timeDescription;
  final EncounterOutcome? outcome;
  final ReliabilityLevel? reliability;
  final String? summary;
  final List<SceneLink> sceneLinks;

  bool hasWitness(String witnessId) =>
      witnesses.any((w) => w.witnessId == witnessId);

  bool linksToScene(String sceneId) =>
      sceneLinks.any((s) => s.sceneId == sceneId);
}

/// Immutable journal of encounter records with deterministic query support.
class EncounterJournal {
  const EncounterJournal._(this._records);

  factory EncounterJournal.empty() => const EncounterJournal._([]);

  factory EncounterJournal.withRecords(List<EncounterRecord> records) {
    final ids = <String, String>{};
    for (final r in records) {
      if (ids.containsKey(r.encounterId)) {
        throw ArgumentError('duplicate encounterId: ${r.encounterId}');
      }
      ids[r.encounterId] = r.encounterId;
    }
    final sorted = List<EncounterRecord>.of(records)
      ..sort((a, b) => a.encounterId.compareTo(b.encounterId));
    return EncounterJournal._(List.unmodifiable(sorted));
  }

  final List<EncounterRecord> _records;

  int get length => _records.length;

  EncounterRecord? recordFor(String encounterId) {
    for (final r in _records) {
      if (r.encounterId == encounterId) return r;
    }
    return null;
  }

  /// Records for [speciesId], sorted by encounter id.
  List<EncounterRecord> recordsForSpecies(String speciesId) {
    return _records.where((r) => r.speciesId == speciesId).toList();
  }

  /// Records with [reliability], sorted by encounter id.
  List<EncounterRecord> byReliability(ReliabilityLevel reliability) {
    return _records.where((r) => r.reliability == reliability).toList();
  }
}
