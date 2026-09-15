// Sprint 111.21 - Ownership Lineage & Historical Events.

//

// Domain-only contract for the ownership history of an artifact: ownership

// periods, custody arrangements, transfer events, loss and recovery events,

// location history, and a deterministic provenance ledger assembled from

// those records.

//

// No persistence, UI, locale, network, wall clock, or random input.

library;

/// How an artifact changed hands. Labels are stable and UI-friendly.

enum TransferType {
  sale('Sale'),

  gift('Gift'),

  inheritance('Inheritance'),

  marriage('Marriage Dower'),

  purchase('Purchase'),

  theft('Theft'),

  seizure('Seizure'),

  ransom('Ransom'),

  found('Found'),

  other('Other');

  const TransferType(this.label);

  final String label;
}

/// How an artifact was lost.

enum LossKind {
  stolen('Stolen'),

  battle('Lost in Battle'),

  wreck('Wreck'),

  fire('Lost to Fire'),

  buried('Buried'),

  disappeared('Disappeared'),

  unknown('Unknown');

  const LossKind(this.label);

  final String label;
}

/// How a lost artifact was recovered.

enum RecoveryKind {
  found('Found'),

  returned('Returned'),

  ransomed('Ransomed'),

  excavated('Excavated'),

  reclaimed('Reclaimed'),

  repurchased('Repurchased'),

  unknown('Unknown');

  const RecoveryKind(this.label);

  final String label;
}

/// Role of a custodian holding an artifact without owning it. Higher

/// [weight] means more trusted custody.

enum CustodyRole {
  borrower('Borrower', 0),

  tenant('Tenant Keeper', 1),

  museum('Museum Display', 2),

  templeGuardian('Temple Guardian', 3),

  vaultWarden('Vault Warden', 4),

  bloodlineSteward('Bloodline Steward', 5);

  const CustodyRole(this.label, this.weight);

  final String label;

  final int weight;
}

/// Kind of entry in a provenance ledger; mirrors the six acceptance families.

enum ProvenanceKind {
  period('Period'),

  custody('Custody'),

  transfer('Transfer'),

  loss('Loss'),

  recovery('Recovery'),

  location('Location');

  const ProvenanceKind(this.label);

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

/// One span during which a named holder owned the artifact. Markers are

/// symbolic era labels (no wall clock): when [endMarker] is absent the period

/// is still open.

class OwnershipPeriod {
  const OwnershipPeriod._({
    required this.periodId,

    required this.holderId,

    required this.holderName,

    this.startMarker,

    this.endMarker,

    this.note,
  });

  factory OwnershipPeriod.validated({
    required String periodId,

    required String holderId,

    required String holderName,

    String? startMarker,

    String? endMarker,

    String? note,
  }) {
    return OwnershipPeriod._(
      periodId: _requireTrimmed(periodId, 'periodId'),

      holderId: _requireTrimmed(holderId, 'holderId'),

      holderName: _requireTrimmed(holderName, 'holderName'),

      startMarker: _optionalTrimmed(startMarker, 'startMarker'),

      endMarker: _optionalTrimmed(endMarker, 'endMarker'),

      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String periodId;

  final String holderId;

  final String holderName;

  final String? startMarker;

  final String? endMarker;

  final String? note;

  bool get isOpenPeriod => endMarker == null;
}

/// A custody arrangement: someone keeps the artifact without owning it.

class CustodyArrangement {
  const CustodyArrangement._({
    required this.custodyId,

    required this.custodianId,

    required this.custodianName,

    required this.role,

    this.institution,

    this.terms,
  });

  factory CustodyArrangement.validated({
    required String custodyId,

    required String custodianId,

    required String custodianName,

    required CustodyRole role,

    String? institution,

    String? terms,
  }) {
    return CustodyArrangement._(
      custodyId: _requireTrimmed(custodyId, 'custodyId'),

      custodianId: _requireTrimmed(custodianId, 'custodianId'),

      custodianName: _requireTrimmed(custodianName, 'custodianName'),

      role: role,

      institution: _optionalTrimmed(institution, 'institution'),

      terms: _optionalTrimmed(terms, 'terms'),
    );
  }

  final String custodyId;

  final String custodianId;

  final String custodianName;

  final CustodyRole role;

  final String? institution;

  final String? terms;
}

/// An event moving the artifact from one holder to another.

class TransferEvent {
  const TransferEvent._({
    required this.transferId,

    required this.type,

    required this.fromHolderId,

    required this.toHolderId,

    this.marker,

    this.note,
  });

  factory TransferEvent.validated({
    required String transferId,

    required TransferType type,

    required String fromHolderId,

    required String toHolderId,

    String? marker,

    String? note,
  }) {
    final from = _requireTrimmed(fromHolderId, 'fromHolderId');

    final to = _requireTrimmed(toHolderId, 'toHolderId');

    if (from == to) {
      throw ArgumentError('transfer from and to holder must differ');
    }

    return TransferEvent._(
      transferId: _requireTrimmed(transferId, 'transferId'),

      type: type,

      fromHolderId: from,

      toHolderId: to,

      marker: _optionalTrimmed(marker, 'marker'),

      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String transferId;

  final TransferType type;

  final String fromHolderId;

  final String toHolderId;

  final String? marker;

  final String? note;

  bool get isViolent {
    return type == TransferType.theft ||
        type == TransferType.seizure ||
        type == TransferType.ransom;
  }
}

/// A loss event; optionally linked to a location record by [locationId].

class LossEvent {
  const LossEvent._({
    required this.lossId,

    required this.kind,

    required this.description,

    this.locationId,

    this.marker,

    this.note,
  });

  factory LossEvent.validated({
    required String lossId,

    required LossKind kind,

    required String description,

    String? locationId,

    String? marker,

    String? note,
  }) {
    return LossEvent._(
      lossId: _requireTrimmed(lossId, 'lossId'),

      kind: kind,

      description: _requireTrimmed(description, 'description'),

      locationId: _optionalTrimmed(locationId, 'locationId'),

      marker: _optionalTrimmed(marker, 'marker'),

      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String lossId;

  final LossKind kind;

  final String description;

  final String? locationId;

  final String? marker;

  final String? note;
}

/// A recovery event chained to the loss it closes.

class RecoveryEvent {
  const RecoveryEvent._({
    required this.recoveryId,

    required this.lossId,

    required this.kind,

    required this.description,

    required this.recoveredById,

    this.marker,

    this.note,
  });

  factory RecoveryEvent.validated({
    required String recoveryId,

    required String lossId,

    required RecoveryKind kind,

    required String description,

    required String recoveredById,

    String? marker,

    String? note,
  }) {
    return RecoveryEvent._(
      recoveryId: _requireTrimmed(recoveryId, 'recoveryId'),

      lossId: _requireTrimmed(lossId, 'lossId'),

      kind: kind,

      description: _requireTrimmed(description, 'description'),

      recoveredById: _requireTrimmed(recoveredById, 'recoveredById'),

      marker: _optionalTrimmed(marker, 'marker'),

      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String recoveryId;

  final String lossId;

  final RecoveryKind kind;

  final String description;

  final String recoveredById;

  final String? marker;

  final String? note;
}

/// A stay of the artifact at some place; open when [endMarker] is absent.

class LocationRecord {
  const LocationRecord._({
    required this.locationId,

    required this.placeId,

    required this.placeName,

    this.startMarker,

    this.endMarker,

    this.note,
  });

  factory LocationRecord.validated({
    required String locationId,

    required String placeId,

    required String placeName,

    String? startMarker,

    String? endMarker,

    String? note,
  }) {
    return LocationRecord._(
      locationId: _requireTrimmed(locationId, 'locationId'),

      placeId: _requireTrimmed(placeId, 'placeId'),

      placeName: _requireTrimmed(placeName, 'placeName'),

      startMarker: _optionalTrimmed(startMarker, 'startMarker'),

      endMarker: _optionalTrimmed(endMarker, 'endMarker'),

      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String locationId;

  final String placeId;

  final String placeName;

  final String? startMarker;

  final String? endMarker;

  final String? note;

  bool get isCurrent => endMarker == null;
}

/// Full ownership lineage of one artifact. Recovery events must reference a

/// loss recorded in the same lineage.

class OwnershipLineageRecord {
  const OwnershipLineageRecord._({
    required this.artifactId,

    required this.periods,

    required this.custodies,

    required this.transfers,

    required this.losses,

    required this.recoveries,

    required this.locations,
  });

  factory OwnershipLineageRecord.validated({
    required String artifactId,

    List<OwnershipPeriod> periods = const [],

    List<CustodyArrangement> custody = const [],

    List<TransferEvent> transfers = const [],

    List<LossEvent> losses = const [],

    List<RecoveryEvent> recoveries = const [],

    List<LocationRecord> locations = const [],
  }) {
    final periodIds = <String, String>{};

    for (final p in periods) {
      if (periodIds.containsKey(p.periodId)) {
        throw ArgumentError('duplicate periodId: ${p.periodId}');
      }

      periodIds[p.periodId] = p.periodId;
    }

    final custodyIds = <String, String>{};

    for (final c in custody) {
      if (custodyIds.containsKey(c.custodyId)) {
        throw ArgumentError('duplicate custodyId: ${c.custodyId}');
      }

      custodyIds[c.custodyId] = c.custodyId;
    }

    final transferIds = <String, String>{};

    for (final t in transfers) {
      if (transferIds.containsKey(t.transferId)) {
        throw ArgumentError('duplicate transferId: ${t.transferId}');
      }

      transferIds[t.transferId] = t.transferId;
    }

    final lossIds = <String, String>{};

    for (final l in losses) {
      if (lossIds.containsKey(l.lossId)) {
        throw ArgumentError('duplicate lossId: ${l.lossId}');
      }

      lossIds[l.lossId] = l.lossId;
    }

    final recoveryIds = <String, String>{};

    for (final r in recoveries) {
      if (recoveryIds.containsKey(r.recoveryId)) {
        throw ArgumentError('duplicate recoveryId: ${r.recoveryId}');
      }

      recoveryIds[r.recoveryId] = r.recoveryId;

      if (!lossIds.containsKey(r.lossId)) {
        throw ArgumentError(
          'recovery ${r.recoveryId} references unknown loss ${r.lossId}',
        );
      }
    }

    final locationIds = <String, String>{};

    for (final loc in locations) {
      if (locationIds.containsKey(loc.locationId)) {
        throw ArgumentError('duplicate locationId: ${loc.locationId}');
      }

      locationIds[loc.locationId] = loc.locationId;
    }

    return OwnershipLineageRecord._(
      artifactId: _requireTrimmed(artifactId, 'artifactId'),

      periods: List.unmodifiable(periods),

      custodies: List.unmodifiable(custody),

      transfers: List.unmodifiable(transfers),

      losses: List.unmodifiable(losses),

      recoveries: List.unmodifiable(recoveries),

      locations: List.unmodifiable(locations),
    );
  }

  final String artifactId;

  final List<OwnershipPeriod> periods;

  final List<CustodyArrangement> custodies;

  final List<TransferEvent> transfers;

  final List<LossEvent> losses;

  final List<RecoveryEvent> recoveries;

  final List<LocationRecord> locations;

  int get periodCount => periods.length;

  int get transferCount => transfers.length;

  int get lossCount => losses.length;

  int get custodyCount => custodies.length;

  int get locationCount => locations.length;

  /// Losses not closed by any recovery event.

  int get openLossCount {
    final closed = recoveries.map((r) => r.lossId).toSet();

    return losses.where((l) => !closed.contains(l.lossId)).length;
  }

  bool get isMissing => openLossCount > 0;

  bool hasHolder(String holderId) => periods.any((p) => p.holderId == holderId);

  String? holderNameFor(String holderId) {
    for (final p in periods) {
      if (p.holderId == holderId) return p.holderName;
    }

    return null;
  }

  bool get hasViolentTransfer => transfers.any((t) => t.isViolent);

  bool isCustodianKnown(String custodianId) =>
      custodies.any((c) => c.custodianId == custodianId);

  /// Place name of the latest open residence, or null when every stay closed.

  String? get currentLocation {
    for (final loc in locations.reversed) {
      if (loc.isCurrent) return loc.placeName;
    }

    return null;
  }
}

/// One ordered entry in a provenance ledger, linking to a record by [refId].

class ProvenanceEntry {
  const ProvenanceEntry._({
    required this.entryId,

    required this.sequence,

    required this.kind,

    required this.refId,

    this.summary,
  });

  factory ProvenanceEntry.validated({
    required String entryId,

    required int sequence,

    required ProvenanceKind kind,

    required String refId,

    String? summary,
  }) {
    if (sequence < 0) {
      throw ArgumentError('sequence must not be negative');
    }

    return ProvenanceEntry._(
      entryId: _requireTrimmed(entryId, 'entryId'),

      sequence: sequence,

      kind: kind,

      refId: _requireTrimmed(refId, 'refId'),

      summary: _optionalTrimmed(summary, 'summary'),
    );
  }

  final String entryId;

  final int sequence;

  final ProvenanceKind kind;

  final String refId;

  final String? summary;

  /// Test/demo helper: same entry with a different sequence value.

  ProvenanceEntry copyWithSequence(int newSequence) {
    if (newSequence < 0) {
      throw ArgumentError('sequence must not be negative');
    }

    return ProvenanceEntry._(
      entryId: entryId,

      sequence: newSequence,

      kind: kind,

      refId: refId,

      summary: summary,
    );
  }

  String describe() {
    final base = '#$sequence ${kind.label} $refId';

    if (summary == null) return base;

    return '$base - $summary';
  }
}

/// Immutable, sequence-ordered provenance ledger for one artifact.

class ProvenanceLedger {
  const ProvenanceLedger._(this.artifactId, this._entries);

  factory ProvenanceLedger.empty(String artifactId) {
    return ProvenanceLedger._(
      _requireTrimmed(artifactId, 'artifactId'),
      const [],
    );
  }

  factory ProvenanceLedger.withEntries({
    required String artifactId,

    required List<ProvenanceEntry> entries,
  }) {
    final id = _requireTrimmed(artifactId, 'artifactId');

    final entryIds = <String, String>{};

    final sequences = <int, int>{};

    for (final e in entries) {
      if (entryIds.containsKey(e.entryId)) {
        throw ArgumentError('duplicate entryId: ${e.entryId}');
      }

      entryIds[e.entryId] = e.entryId;

      if (sequences.containsKey(e.sequence)) {
        throw ArgumentError('duplicate sequence: ${e.sequence}');
      }

      sequences[e.sequence] = e.sequence;
    }

    final sorted = List<ProvenanceEntry>.of(entries)
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    return ProvenanceLedger._(id, List.unmodifiable(sorted));
  }

  final String artifactId;

  final List<ProvenanceEntry> _entries;

  List<ProvenanceEntry> get entries => _entries;

  int get length => _entries.length;

  List<ProvenanceEntry> entriesForKind(ProvenanceKind kind) {
    return _entries.where((e) => e.kind == kind).toList();
  }

  /// Ordered human-readable chain of the provenance story.

  List<String> chain() {
    return _entries.map((e) => e.describe()).toList();
  }

  bool hasRef(String refId) => _entries.any((e) => e.refId == refId);

  /// Entry refs that are not present in [availableRefs] (dangling links).

  List<String> danglingRefs({required Set<String> availableRefs}) {
    final dangling = <String>[];

    for (final e in _entries) {
      if (!availableRefs.contains(e.refId)) dangling.add(e.refId);
    }

    return dangling;
  }
}

/// Immutable catalog of ownership lineages keyed by artifact.

class OwnershipLineageCatalog {
  const OwnershipLineageCatalog._(this._records);

  factory OwnershipLineageCatalog.empty() =>
      const OwnershipLineageCatalog._([]);

  factory OwnershipLineageCatalog.withRecords(
    List<OwnershipLineageRecord> records,
  ) {
    final ids = <String, String>{};

    for (final r in records) {
      if (ids.containsKey(r.artifactId)) {
        throw ArgumentError('duplicate artifactId: ${r.artifactId}');
      }

      ids[r.artifactId] = r.artifactId;
    }

    final sorted = List<OwnershipLineageRecord>.of(records)
      ..sort((a, b) => a.artifactId.compareTo(b.artifactId));

    return OwnershipLineageCatalog._(List.unmodifiable(sorted));
  }

  final List<OwnershipLineageRecord> _records;

  List<OwnershipLineageRecord> get records => _records;

  int get length => _records.length;

  OwnershipLineageRecord? recordFor(String artifactId) {
    for (final r in _records) {
      if (r.artifactId == artifactId) return r;
    }

    return null;
  }

  /// Distinct holder ids across all lineages, sorted deterministically.

  List<String> holderIds() {
    final set = <String>{};

    for (final r in _records) {
      for (final p in r.periods) {
        set.add(p.holderId);
      }
    }

    final list = set.toList()..sort();

    return list;
  }

  int get missingCount => _records.where((r) => r.isMissing).length;
}
