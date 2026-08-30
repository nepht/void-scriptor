// Sprint 110.27 - Character Location History (Wave 2 F6).
//
// Domain-only record of where a character has been, where they are
// currently traveling, and where the author marked their position as
// uncertain. Each record carries a `LocationHistorySource` so a writer
// can trace a continuity claim back to the novel/scene/outline that
// established it. `CharacterLocationTimeline.resolveAt(tick)` returns a
// `LocationResolution` carrying the most plausible location id, an
// in-transit flag, the candidate list when the position is uncertain,
// and the source chain that produced the answer.
//
// Consumed by 110.28 (Age & Location Continuity Alerts). Pure,
// deterministic, no persistence, UI, locale, network, wall clock, or
// random input.

library;

/// Identifies the kind of work a [LocationHistorySource] came from.
enum LocationSourceKind {
  novel,
  outline,
  characterWorkspace,
  authorNote,
  campaignLog,
  custom,
}

/// Provenance reference attached to every record in the timeline.
class LocationHistorySource {
  const LocationHistorySource._({
    required this.id,
    required this.revision,
    required this.reason,
    required this.kind,
  });

  factory LocationHistorySource.validated({
    required String id,
    required String revision,
    required String reason,
    required LocationSourceKind kind,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, "id", "must be non-empty");
    }
    if (revision.isEmpty) {
      throw ArgumentError.value(revision, "revision", "must be non-empty");
    }
    if (reason.isEmpty) {
      throw ArgumentError.value(reason, "reason", "must be non-empty");
    }
    return LocationHistorySource._(
      id: id,
      revision: revision,
      reason: reason,
      kind: kind,
    );
  }

  final String id;
  final String revision;
  final String reason;
  final LocationSourceKind kind;
}

/// Kind of point-in-time event recorded on the timeline.
enum LocationEventKind { arrival, departure, confirmed, rumored, killed }

/// A single canonical event: a person is at a location at a tick.
class LocationEvent {
  const LocationEvent._({
    required this.id,
    required this.personId,
    required this.locationId,
    required this.tick,
    required this.kind,
    required this.source,
  });

  factory LocationEvent.validated({
    required String id,
    required String personId,
    required String locationId,
    required int tick,
    required LocationEventKind kind,
    required LocationHistorySource source,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, "id", "must be non-empty");
    }
    if (personId.isEmpty) {
      throw ArgumentError.value(personId, "personId", "must be non-empty");
    }
    if (locationId.isEmpty) {
      throw ArgumentError.value(locationId, "locationId", "must be non-empty");
    }
    if (tick < 0) {
      throw ArgumentError.value(tick, "tick", "must be >= 0");
    }
    return LocationEvent._(
      id: id,
      personId: personId,
      locationId: locationId,
      tick: tick,
      kind: kind,
      source: source,
    );
  }

  final String id;
  final String personId;
  final String locationId;
  final int tick;
  final LocationEventKind kind;
  final LocationHistorySource source;

  /// A point-in-time arrival or confirmation is "active" from its tick
  /// forward until the next event for the same person supersedes it. A
  /// departure is never itself active â€” it only marks the end of the
  /// preceding arrival.
  bool isActiveAt(int t) {
    if (kind == LocationEventKind.departure) return false;
    return t >= tick;
  }
}

class TravelSegment {
  const TravelSegment._({
    required this.id,
    required this.personId,
    required this.fromLocationId,
    required this.toLocationId,
    required this.startTick,
    required this.endTick,
    required this.source,
  });

  factory TravelSegment.validated({
    required String id,
    required String personId,
    required String fromLocationId,
    required String toLocationId,
    required int startTick,
    required int endTick,
    required LocationHistorySource source,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, "id", "must be non-empty");
    }
    if (personId.isEmpty) {
      throw ArgumentError.value(personId, "personId", "must be non-empty");
    }
    if (fromLocationId.isEmpty) {
      throw ArgumentError.value(
        fromLocationId,
        "fromLocationId",
        "must be non-empty",
      );
    }
    if (toLocationId.isEmpty) {
      throw ArgumentError.value(
        toLocationId,
        "toLocationId",
        "must be non-empty",
      );
    }
    if (fromLocationId == toLocationId) {
      throw ArgumentError.value(
        toLocationId,
        "toLocationId",
        "travel segment endpoints must differ",
      );
    }
    if (startTick < 0) {
      throw ArgumentError.value(startTick, "startTick", "must be >= 0");
    }
    if (endTick < startTick) {
      throw ArgumentError.value(endTick, "endTick", "must be >= startTick");
    }
    return TravelSegment._(
      id: id,
      personId: personId,
      fromLocationId: fromLocationId,
      toLocationId: toLocationId,
      startTick: startTick,
      endTick: endTick,
      source: source,
    );
  }

  final String id;
  final String personId;
  final String fromLocationId;
  final String toLocationId;
  final int startTick;
  final int endTick;
  final LocationHistorySource source;

  bool isInTransitAt(int t) => t >= startTick && t <= endTick;
}

class UncertainLocationRange {
  const UncertainLocationRange._({
    required this.id,
    required this.personId,
    required this.fromTick,
    required this.toTick,
    required this.candidateLocationIds,
    required this.source,
  });

  factory UncertainLocationRange.validated({
    required String id,
    required String personId,
    required int fromTick,
    required int toTick,
    required List<String> candidateLocationIds,
    required LocationHistorySource source,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, "id", "must be non-empty");
    }
    if (personId.isEmpty) {
      throw ArgumentError.value(personId, "personId", "must be non-empty");
    }
    if (fromTick < 0) {
      throw ArgumentError.value(fromTick, "fromTick", "must be >= 0");
    }
    if (toTick < fromTick) {
      throw ArgumentError.value(toTick, "toTick", "must be >= fromTick");
    }
    if (candidateLocationIds.isEmpty) {
      throw ArgumentError.value(
        candidateLocationIds,
        "candidateLocationIds",
        "must list at least one candidate",
      );
    }
    for (final c in candidateLocationIds) {
      if (c.isEmpty) {
        throw ArgumentError.value(
          c,
          "candidateLocationIds",
          "must not contain empty ids",
        );
      }
    }
    return UncertainLocationRange._(
      id: id,
      personId: personId,
      fromTick: fromTick,
      toTick: toTick,
      candidateLocationIds: List.unmodifiable(candidateLocationIds),
      source: source,
    );
  }

  final String id;
  final String personId;
  final int fromTick;
  final int toTick;
  final List<String> candidateLocationIds;
  final LocationHistorySource source;

  bool containsTick(int t) => t >= fromTick && t <= toTick;
}

/// Result of asking "where is this character at tick T?".
///
/// When [isKnown] is false, [locationId] is null and either
/// [candidateLocationIds] is non-empty (uncertain range) or
/// [reason] explains why nothing is recorded yet (e.g. "no record"
/// before any event). When [isInTransit] is true, [locationId] is
/// the most plausible endpoint of an in-progress travel segment and
/// [sourceChain] includes the segment id.
class LocationResolution {
  const LocationResolution._({
    required this.isKnown,
    required this.locationId,
    required this.isInTransit,
    required this.candidateLocationIds,
    required this.sourceChain,
    required this.reason,
  });

  factory LocationResolution.unknown(String reason) {
    return LocationResolution._(
      isKnown: false,
      locationId: null,
      isInTransit: false,
      candidateLocationIds: const <String>[],
      sourceChain: const <String>[],
      reason: reason,
    );
  }

  factory LocationResolution.certain({
    required String locationId,
    required List<String> sourceChain,
  }) {
    return LocationResolution._(
      isKnown: true,
      locationId: locationId,
      isInTransit: false,
      candidateLocationIds: const <String>[],
      sourceChain: List.unmodifiable(sourceChain),
      reason: "event-anchored",
    );
  }

  factory LocationResolution.inTransit({
    required String fromLocationId,
    required String toLocationId,
    required List<String> sourceChain,
  }) {
    return LocationResolution._(
      isKnown: true,
      locationId: fromLocationId,
      isInTransit: true,
      candidateLocationIds: List<String>.unmodifiable([
        fromLocationId,
        toLocationId,
      ]),
      sourceChain: List.unmodifiable(sourceChain),
      reason: "in-transit",
    );
  }

  factory LocationResolution.uncertain({
    required List<String> candidateLocationIds,
    required List<String> sourceChain,
  }) {
    return LocationResolution._(
      isKnown: false,
      locationId: null,
      isInTransit: false,
      candidateLocationIds: List.unmodifiable(candidateLocationIds),
      sourceChain: List.unmodifiable(sourceChain),
      reason: "uncertain-range",
    );
  }

  final bool isKnown;
  final String? locationId;
  final bool isInTransit;
  final List<String> candidateLocationIds;
  final List<String> sourceChain;
  final String reason;
}

/// In-memory log of location events, travel segments, and uncertain
/// ranges for a single person. The timeline is append-only via
/// [record]; resolution is deterministic via [resolveAt].
class CharacterLocationTimeline {
  CharacterLocationTimeline({required this.personId})
    : assert(personId.isNotEmpty, "personId must be non-empty"),
      _events = <LocationEvent>[],
      _segments = <TravelSegment>[],
      _uncertain = <UncertainLocationRange>[];

  final String personId;
  final List<LocationEvent> _events;
  final List<TravelSegment> _segments;
  final List<UncertainLocationRange> _uncertain;

  void record(Object entry) {
    if (entry is LocationEvent) {
      if (entry.personId != personId) {
        throw ArgumentError.value(
          entry.personId,
          "event.personId",
          "does not match timeline personId",
        );
      }
      _events.add(entry);
    } else if (entry is TravelSegment) {
      recordSegment(entry);
    } else if (entry is UncertainLocationRange) {
      recordUncertain(entry);
    } else {
      throw ArgumentError.value(
        entry,
        "entry",
        "must be LocationEvent, TravelSegment, or UncertainLocationRange",
      );
    }
  }

  void recordSegment(TravelSegment segment) {
    if (segment.personId != personId) {
      throw ArgumentError.value(
        segment.personId,
        "segment.personId",
        "does not match timeline personId",
      );
    }
    _segments.add(segment);
  }

  void recordUncertain(UncertainLocationRange range) {
    if (range.personId != personId) {
      throw ArgumentError.value(
        range.personId,
        "range.personId",
        "does not match timeline personId",
      );
    }
    _uncertain.add(range);
  }

  /// Returns the most plausible location for [personId] at [tick].
  ///
  /// Priority:
  /// 1. If any travel segment covers the tick, the person is in-transit.
  /// 2. If an uncertain range covers the tick, return the candidate set.
  /// 3. Otherwise, the latest event whose `isActiveAt(tick)` is true.
  /// 4. If none, return unknown("no record for $personId at tick $tick").
  LocationResolution resolveAt(int tick) {
    if (tick < 0) {
      throw ArgumentError.value(tick, "tick", "must be >= 0");
    }
    final segment = _firstSegmentAt(tick);
    if (segment != null) {
      return LocationResolution.inTransit(
        fromLocationId: segment.fromLocationId,
        toLocationId: segment.toLocationId,
        sourceChain: <String>[segment.id, segment.source.id],
      );
    }
    final uncertain = _firstUncertainAt(tick);
    if (uncertain != null) {
      return LocationResolution.uncertain(
        candidateLocationIds: uncertain.candidateLocationIds,
        sourceChain: <String>[uncertain.id, uncertain.source.id],
      );
    }
    final active = _activeEventAt(tick);
    if (active != null) {
      return LocationResolution.certain(
        locationId: active.locationId,
        sourceChain: <String>[active.id, active.source.id],
      );
    }
    return LocationResolution.unknown("no record for $personId at tick $tick");
  }

  TravelSegment? _firstSegmentAt(int tick) {
    for (final s in _segments) {
      if (s.isInTransitAt(tick)) return s;
    }
    return null;
  }

  UncertainLocationRange? _firstUncertainAt(int tick) {
    for (final u in _uncertain) {
      if (u.containsTick(tick)) return u;
    }
    return null;
  }

  LocationEvent? _activeEventAt(int tick) {
    LocationEvent? latest;
    int latestTick = -1;
    for (final e in _events) {
      if (e.isActiveAt(tick) && e.tick >= latestTick) {
        latest = e;
        latestTick = e.tick;
      }
    }
    return latest;
  }
}
