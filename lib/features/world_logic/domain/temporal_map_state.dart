// Sprint 110.20 - Temporal Map State Model.
//
// Domain-only contract for storing location existence, boundaries, names,
// control, and status across time. Supports validity ranges, boundary
// versioning, control history, location status, and parallel branch
// awareness. No persistence, UI, locale, network, wall clock, or random
// input. Consumed by 110.21 (Map Time Slider) and 110.22 (Temporal
// Location & Route Validation).

library;

enum LocationStatus { active, ruined, abandoned, hidden, contested }

class MapPoint {
  const MapPoint({required this.x, required this.y});
  final num x;
  final num y;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapPoint && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'MapPoint($x, $y)';
}

class BoundaryVersion {
  const BoundaryVersion({
    required this.id,
    required this.validFrom,
    required this.vertices,
    this.note = '',
  });

  factory BoundaryVersion.validated({
    required String id,
    required int validFrom,
    required List<MapPoint> vertices,
    String note = '',
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'id cannot be empty');
    }
    if (validFrom < 0) {
      throw ArgumentError.value(
        validFrom,
        'validFrom',
        'validFrom cannot be negative',
      );
    }
    if (vertices.isEmpty) {
      throw ArgumentError.value(
        vertices,
        'vertices',
        'vertices cannot be empty',
      );
    }
    return BoundaryVersion(
      id: id,
      validFrom: validFrom,
      vertices: List<MapPoint>.unmodifiable(vertices),
      note: note,
    );
  }

  final String id;
  final int validFrom;
  final List<MapPoint> vertices;
  final String note;
}

class ControlChange {
  const ControlChange({
    required this.id,
    required this.validFrom,
    required this.factionId,
    this.note = '',
  });

  factory ControlChange.validated({
    required String id,
    required int validFrom,
    required String factionId,
    String note = '',
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'id cannot be empty');
    }
    if (validFrom < 0) {
      throw ArgumentError.value(
        validFrom,
        'validFrom',
        'validFrom cannot be negative',
      );
    }
    if (factionId.isEmpty) {
      throw ArgumentError.value(
        factionId,
        'factionId',
        'factionId cannot be empty',
      );
    }
    return ControlChange(
      id: id,
      validFrom: validFrom,
      factionId: factionId,
      note: note,
    );
  }

  final String id;
  final int validFrom;
  final String factionId;
  final String note;
}

class StatusChange {
  const StatusChange({
    required this.id,
    required this.validFrom,
    required this.status,
    this.note = '',
  });

  factory StatusChange.validated({
    required String id,
    required int validFrom,
    required LocationStatus status,
    String note = '',
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'id cannot be empty');
    }
    if (validFrom < 0) {
      throw ArgumentError.value(
        validFrom,
        'validFrom',
        'validFrom cannot be negative',
      );
    }
    return StatusChange(
      id: id,
      validFrom: validFrom,
      status: status,
      note: note,
    );
  }

  final String id;
  final int validFrom;
  final LocationStatus status;
  final String note;
}

class TemporalLocation {
  const TemporalLocation({
    required this.id,
    required this.name,
    required this.validFrom,
    this.validUntil,
    this.boundaries = const [],
    this.controlHistory = const [],
    this.statusHistory = const [],
    this.note = '',
  });

  factory TemporalLocation.validated({
    required String id,
    required String name,
    required int validFrom,
    int? validUntil,
    List<BoundaryVersion> boundaries = const [],
    List<ControlChange> controlHistory = const [],
    List<StatusChange> statusHistory = const [],
    String note = '',
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'id cannot be empty');
    }
    if (validFrom < 0) {
      throw ArgumentError.value(
        validFrom,
        'validFrom',
        'validFrom cannot be negative',
      );
    }
    if (validUntil != null && validUntil < validFrom) {
      throw ArgumentError(
        'validUntil ($validUntil) cannot be less than validFrom ($validFrom)',
      );
    }
    return TemporalLocation(
      id: id,
      name: name,
      validFrom: validFrom,
      validUntil: validUntil,
      boundaries: List<BoundaryVersion>.unmodifiable(boundaries),
      controlHistory: List<ControlChange>.unmodifiable(controlHistory),
      statusHistory: List<StatusChange>.unmodifiable(statusHistory),
      note: note,
    );
  }

  final String id;
  final String name;
  final int validFrom;
  final int? validUntil;
  final List<BoundaryVersion> boundaries;
  final List<ControlChange> controlHistory;
  final List<StatusChange> statusHistory;
  final String note;

  bool isActiveAt(int tick) {
    if (tick < validFrom) return false;
    if (validUntil != null && tick > validUntil!) return false;
    return true;
  }

  BoundaryVersion? boundaryAt(int tick) {
    if (!isActiveAt(tick)) return null;
    BoundaryVersion? pick;
    for (final bv in boundaries) {
      if (bv.validFrom > tick) continue;
      if (pick == null || bv.validFrom > pick.validFrom) {
        pick = bv;
      }
    }
    return pick;
  }

  String? controllingFactionAt(int tick) {
    if (!isActiveAt(tick)) return null;
    ControlChange? pick;
    for (final cc in controlHistory) {
      if (cc.validFrom > tick) continue;
      if (pick == null || cc.validFrom > pick.validFrom) {
        pick = cc;
      }
    }
    return pick?.factionId;
  }

  LocationStatus statusAt(int tick) {
    if (!isActiveAt(tick)) return LocationStatus.hidden;
    StatusChange? pick;
    for (final sc in statusHistory) {
      if (sc.validFrom > tick) continue;
      if (pick == null || sc.validFrom > pick.validFrom) {
        pick = sc;
      }
    }
    return pick?.status ?? LocationStatus.active;
  }
}

class TemporalLocationSnapshot {
  const TemporalLocationSnapshot({
    required this.id,
    required this.name,
    required this.controllingFactionId,
    required this.status,
    required this.activeBoundary,
  });

  final String id;
  final String name;
  final String? controllingFactionId;
  final LocationStatus status;
  final BoundaryVersion? activeBoundary;
}

class TemporalMapSnapshot {
  const TemporalMapSnapshot({
    required this.branchId,
    required this.tick,
    required this.locations,
  });

  final String branchId;
  final int tick;
  final List<TemporalLocationSnapshot> locations;
}

class TemporalMapState {
  TemporalMapState({
    required this.branchId,
    List<TemporalLocation> locations = const [],
    Map<String, List<TemporalLocation>> branches = const {},
  }) : _primeLocations = List<TemporalLocation>.unmodifiable(locations),
       _branches = Map<String, List<TemporalLocation>>.unmodifiable(
         branches.map(
           (key, value) =>
               MapEntry(key, List<TemporalLocation>.unmodifiable(value)),
         ),
       ) {
    if (branchId.isEmpty) {
      throw ArgumentError.value(
        branchId,
        'branchId',
        'branchId cannot be empty',
      );
    }
  }

  final String branchId;
  final List<TemporalLocation> _primeLocations;
  final Map<String, List<TemporalLocation>> _branches;

  List<TemporalLocation> get primeLocations => _primeLocations;

  List<TemporalLocation> locationsFor(String branchId) {
    if (branchId == this.branchId) return _primeLocations;
    final list = _branches[branchId];
    if (list == null) {
      throw ArgumentError.value(
        branchId,
        'branchId',
        'Unknown branch; available: '
            '${[this.branchId, ..._branches.keys].join(', ')}',
      );
    }
    return list;
  }

  TemporalMapSnapshot snapshotAt({
    required String branchId,
    required int tick,
  }) {
    if (tick < 0) {
      throw ArgumentError.value(tick, 'tick', 'tick cannot be negative');
    }
    final source = locationsFor(branchId);
    final active = <TemporalLocationSnapshot>[];
    for (final loc in source) {
      if (!loc.isActiveAt(tick)) continue;
      active.add(
        TemporalLocationSnapshot(
          id: loc.id,
          name: loc.name,
          controllingFactionId: loc.controllingFactionAt(tick),
          status: loc.statusAt(tick),
          activeBoundary: loc.boundaryAt(tick),
        ),
      );
    }
    return TemporalMapSnapshot(
      branchId: branchId,
      tick: tick,
      locations: List<TemporalLocationSnapshot>.unmodifiable(active),
    );
  }
}
