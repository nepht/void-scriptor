// Sprint 110.27 - Character Location History (RED).
//
// Verifies the canonical 110.27 acceptance from sprint_110.json:
//   - location_events (validated event log with source provenance)
//   - travel_segments (validated travel segments between two locations)
//   - uncertain_location (fuzzy candidate location over a tick range)
//   - source_reference (revision+reason provenance on every record)
//   - timeline_query (resolveAt(tick) returns the most plausible location
//     with confidence and source chain)
//
// Domain-only, deterministic, no persistence/UI/wall clock/locale/random.

library;

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/character_location_history.dart";

void main() {
  group("Sprint 110.27 CharacterLocationHistory", () {
    final source = LocationHistorySource.validated(
      id: "novel-1",
      revision: "rev-1",
      reason: "chapter 3",
      kind: LocationSourceKind.novel,
    );

    test("location_events: validated factory rejects bad payload", () {
      expect(
        () => LocationEvent.validated(
          id: "",
          personId: "p1",
          locationId: "loc-1",
          tick: 0,
          kind: LocationEventKind.arrival,
          source: source,
        ),
        throwsArgumentError,
      );
      expect(
        () => LocationEvent.validated(
          id: "ev-1",
          personId: "",
          locationId: "loc-1",
          tick: 0,
          kind: LocationEventKind.arrival,
          source: source,
        ),
        throwsArgumentError,
      );
      expect(
        () => LocationEvent.validated(
          id: "ev-1",
          personId: "p1",
          locationId: "",
          tick: 0,
          kind: LocationEventKind.arrival,
          source: source,
        ),
        throwsArgumentError,
      );
      expect(
        () => LocationEvent.validated(
          id: "ev-1",
          personId: "p1",
          locationId: "loc-1",
          tick: -1,
          kind: LocationEventKind.arrival,
          source: source,
        ),
        throwsArgumentError,
      );
    });

    test("location_events: isActiveAt carry-forward across dwell window", () {
      final arrive = LocationEvent.validated(
        id: "ev-arrive",
        personId: "p1",
        locationId: "loc-1",
        tick: 10,
        kind: LocationEventKind.arrival,
        source: source,
      );
      final depart = LocationEvent.validated(
        id: "ev-depart",
        personId: "p1",
        locationId: "loc-2",
        tick: 30,
        kind: LocationEventKind.departure,
        source: source,
      );
      expect(arrive.isActiveAt(20), isTrue);
      expect(depart.isActiveAt(20), isFalse);
    });

    test("travel_segments: validated factory enforces endpoints and order", () {
      expect(
        () => TravelSegment.validated(
          id: "",
          personId: "p1",
          fromLocationId: "loc-1",
          toLocationId: "loc-2",
          startTick: 0,
          endTick: 5,
          source: source,
        ),
        throwsArgumentError,
      );
      expect(
        () => TravelSegment.validated(
          id: "seg-1",
          personId: "p1",
          fromLocationId: "loc-1",
          toLocationId: "loc-1",
          startTick: 0,
          endTick: 5,
          source: source,
        ),
        throwsArgumentError,
      );
      expect(
        () => TravelSegment.validated(
          id: "seg-1",
          personId: "p1",
          fromLocationId: "loc-1",
          toLocationId: "loc-2",
          startTick: 10,
          endTick: 5,
          source: source,
        ),
        throwsArgumentError,
      );
    });

    test("travel_segments: tick inclusive is in transit", () {
      final seg = TravelSegment.validated(
        id: "seg-1",
        personId: "p1",
        fromLocationId: "loc-1",
        toLocationId: "loc-2",
        startTick: 10,
        endTick: 20,
        source: source,
      );
      expect(seg.isInTransitAt(10), isTrue);
      expect(seg.isInTransitAt(15), isTrue);
      expect(seg.isInTransitAt(20), isTrue);
      expect(seg.isInTransitAt(9), isFalse);
      expect(seg.isInTransitAt(21), isFalse);
    });

    test("uncertain_location: validated factory and containsTick", () {
      expect(
        () => UncertainLocationRange.validated(
          id: "",
          personId: "p1",
          fromTick: 0,
          toTick: 10,
          candidateLocationIds: const ["loc-1"],
          source: source,
        ),
        throwsArgumentError,
      );
      final uncertain = UncertainLocationRange.validated(
        id: "unc-1",
        personId: "p1",
        fromTick: 50,
        toTick: 70,
        candidateLocationIds: const ["loc-a", "loc-b"],
        source: source,
      );
      expect(uncertain.containsTick(50), isTrue);
      expect(uncertain.containsTick(60), isTrue);
      expect(uncertain.containsTick(70), isTrue);
      expect(uncertain.containsTick(49), isFalse);
      expect(uncertain.containsTick(71), isFalse);
    });

    test("source_reference: revision+reason retained on every record", () {
      final ev = LocationEvent.validated(
        id: "ev-1",
        personId: "p1",
        locationId: "loc-1",
        tick: 5,
        kind: LocationEventKind.arrival,
        source: source,
      );
      final seg = TravelSegment.validated(
        id: "seg-1",
        personId: "p1",
        fromLocationId: "loc-1",
        toLocationId: "loc-2",
        startTick: 5,
        endTick: 10,
        source: source,
      );
      final unc = UncertainLocationRange.validated(
        id: "unc-1",
        personId: "p1",
        fromTick: 5,
        toTick: 10,
        candidateLocationIds: const ["loc-1", "loc-2"],
        source: source,
      );
      for (final s in [ev.source, seg.source, unc.source]) {
        expect(s.id, "novel-1");
        expect(s.revision, "rev-1");
        expect(s.reason, "chapter 3");
      }
    });

    test(
      "timeline_query: resolveAt returns event location with source chain",
      () {
        final tl = CharacterLocationTimeline(personId: "p1")
          ..record(
            LocationEvent.validated(
              id: "ev-1",
              personId: "p1",
              locationId: "loc-1",
              tick: 0,
              kind: LocationEventKind.arrival,
              source: source,
            ),
          )
          ..record(
            LocationEvent.validated(
              id: "ev-2",
              personId: "p1",
              locationId: "loc-2",
              tick: 20,
              kind: LocationEventKind.arrival,
              source: source,
            ),
          );
        final resolved = tl.resolveAt(10);
        expect(resolved.locationId, "loc-1");
        expect(resolved.isKnown, isTrue);
        expect(resolved.sourceChain, contains("ev-1"));
      },
    );

    test("timeline_query: resolveAt in-transit uses segment endpoints", () {
      final tl = CharacterLocationTimeline(personId: "p1")
        ..record(
          LocationEvent.validated(
            id: "ev-1",
            personId: "p1",
            locationId: "loc-1",
            tick: 0,
            kind: LocationEventKind.arrival,
            source: source,
          ),
        )
        ..record(
          TravelSegment.validated(
            id: "seg-1",
            personId: "p1",
            fromLocationId: "loc-1",
            toLocationId: "loc-2",
            startTick: 10,
            endTick: 20,
            source: source,
          ),
        );
      final mid = tl.resolveAt(15);
      expect(mid.isInTransit, isTrue);
      expect(mid.locationId, anyOf("loc-1", "loc-2"));
      expect(mid.sourceChain, contains("seg-1"));
    });

    test("timeline_query: resolveAt within uncertain range is unknown", () {
      final tl = CharacterLocationTimeline(personId: "p1")
        ..record(
          LocationEvent.validated(
            id: "ev-1",
            personId: "p1",
            locationId: "loc-1",
            tick: 0,
            kind: LocationEventKind.arrival,
            source: source,
          ),
        )
        ..record(
          UncertainLocationRange.validated(
            id: "unc-1",
            personId: "p1",
            fromTick: 10,
            toTick: 20,
            candidateLocationIds: const ["loc-2", "loc-3"],
            source: source,
          ),
        );
      final r = tl.resolveAt(15);
      expect(r.isKnown, isFalse);
      expect(r.candidateLocationIds, containsAll(["loc-2", "loc-3"]));
      expect(r.sourceChain, contains("unc-1"));
    });

    test("timeline_query: resolveAt before any event returns unknown", () {
      final tl = CharacterLocationTimeline(personId: "p1");
      final r = tl.resolveAt(0);
      expect(r.isKnown, isFalse);
      expect(r.reason, contains("no record"));
    });
  });
}
