// Sprint 110.21 - Map Time Slider & Historical Layers (resolver).
//
// RED tests covering time_slider, historical_layers, change_highlight,
// legend, and keyboard_control surfaces of the resolver that backs the
// 110.21 widget. Domain-only: no persistence, UI, locale, network, wall
// clock, or random input.

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/historical_layer_resolver.dart";
import "package:void_scriptor/features/world_logic/domain/temporal_map_state.dart";

TemporalMapState _sampleState() {
  return TemporalMapState(
    branchId: "prime",
    locations: const [
      TemporalLocation(
        id: "loc-a",
        name: "A",
        validFrom: 0,
        validUntil: 100,
        boundaries: [
          BoundaryVersion(
            id: "bv-a",
            validFrom: 0,
            vertices: [MapPoint(x: 0, y: 0)],
          ),
          BoundaryVersion(
            id: "bv-a2",
            validFrom: 50,
            vertices: [MapPoint(x: 1, y: 1)],
          ),
        ],
        controlHistory: [
          ControlChange(id: "cc-a1", validFrom: 0, factionId: "fac-old"),
          ControlChange(id: "cc-a2", validFrom: 30, factionId: "fac-new"),
        ],
        statusHistory: [
          StatusChange(
            id: "sc-a1",
            validFrom: 0,
            status: LocationStatus.active,
          ),
          StatusChange(
            id: "sc-a2",
            validFrom: 40,
            status: LocationStatus.ruined,
          ),
        ],
      ),
      TemporalLocation(id: "loc-b", name: "B", validFrom: 0, validUntil: 60),
      TemporalLocation(id: "loc-c", name: "C", validFrom: 80),
    ],
  );
}

void main() {
  group("MapTimeSliderController (time_slider)", () {
    test("computes min/max tick from locations when not provided", () {
      final c = MapTimeSliderController.forState(_sampleState());
      expect(c.minTick, 0);
      expect(c.maxTick, 100);
      expect(c.currentTick, 0);
    });

    test("clamps currentTick inside [minTick, maxTick]", () {
      final c = MapTimeSliderController.forState(
        _sampleState(),
        initialTick: -5,
      );
      expect(c.currentTick, 0);

      final c2 = MapTimeSliderController.forState(
        _sampleState(),
        initialTick: 999,
      );
      expect(c2.currentTick, 100);
    });

    test("seekTo updates currentTick and notifies listeners", () {
      final c = MapTimeSliderController.forState(_sampleState());
      var notifyCount = 0;
      c.addListener(() => notifyCount += 1);
      c.seekTo(40);
      expect(c.currentTick, 40);
      expect(notifyCount, 1);
      c.seekTo(40);
      expect(notifyCount, 1);
    });

    test("keyTicks returns sorted unique validFrom + validUntil anchors", () {
      final c = MapTimeSliderController.forState(_sampleState());
      expect(c.keyTicks, containsAll(<int>[0, 30, 40, 50, 60, 80, 100]));
      final sorted = List<int>.from(c.keyTicks)..sort();
      expect(c.keyTicks, sorted);
    });

    test("tickRange returns max - min + 1", () {
      final c = MapTimeSliderController.forState(_sampleState());
      expect(c.tickRange, 101);
    });
  });

  group("Historical layers (historical_layers)", () {
    test("activeLayers returns snapshot per enabled key tick", () {
      final state = _sampleState();
      final c = MapTimeSliderController.forState(state);
      c.enableLayerAt(0);
      c.enableLayerAt(50);
      c.enableLayerAt(80);

      final layers = c.activeLayers;
      expect(layers.length, 3);
      expect(layers.first.tick, 0);
      expect(layers.last.tick, 80);
    });

    test("activeLayerForTick returns layer for arbitrary tick (nullable)", () {
      final c = MapTimeSliderController.forState(_sampleState());
      c.enableLayerAt(40);
      expect(c.activeLayerForTick(40), isNotNull);
      expect(c.activeLayerForTick(40)!.tick, 40);
      expect(c.activeLayerForTick(99), isNull);
    });

    test("disabled layer is omitted from activeLayers", () {
      final c = MapTimeSliderController.forState(_sampleState());
      c.enableLayerAt(0);
      c.enableLayerAt(40);
      c.disableLayerAt(0);
      expect(c.activeLayers.map((e) => e.tick), [40]);
    });

    test("HistoricalLayer.locations respects temporal validity", () {
      final c = MapTimeSliderController.forState(_sampleState());
      c.enableLayerAt(70);
      final layer = c.activeLayerForTick(70)!;
      expect(layer.locations.map((e) => e.id), ["loc-a"]);
      expect(layer.locations.first.status, LocationStatus.ruined);
      expect(layer.locations.first.controllingFactionId, "fac-new");
    });
  });

  group("Change highlight (change_highlight)", () {
    test("compares against previous key tick to detect status changes", () {
      final c = MapTimeSliderController.forState(_sampleState());
      c.enableLayerAt(0);
      c.enableLayerAt(40);
      c.seekTo(40);
      final layer = c.activeLayerForTick(40)!;
      final highlights = layer.highlights;
      final statusChange = highlights.firstWhere(
        (h) => h.kind == HighlightKind.statusChange,
        orElse: () => throw StateError("expected status change"),
      );
      expect(statusChange.locationId, "loc-a");
      expect(statusChange.reason.contains("ruined"), isTrue);
    });

    test("flags new locations when they appear after validFrom", () {
      final c = MapTimeSliderController.forState(_sampleState());
      c.enableLayerAt(0);
      c.enableLayerAt(80);
      c.seekTo(80);
      final layer = c.activeLayerForTick(80)!;
      final newLoc = layer.highlights.firstWhere(
        (h) => h.kind == HighlightKind.appeared,
      );
      expect(newLoc.locationId, "loc-c");
    });

    test("flags boundary revision when active boundary changes", () {
      final c = MapTimeSliderController.forState(_sampleState());
      c.enableLayerAt(0);
      c.enableLayerAt(50);
      c.seekTo(50);
      final layer = c.activeLayerForTick(50)!;
      final boundary = layer.highlights.firstWhere(
        (h) => h.kind == HighlightKind.boundaryChange,
      );
      expect(boundary.locationId, "loc-a");
    });

    test("flags control change when faction shifts", () {
      final c = MapTimeSliderController.forState(_sampleState());
      c.enableLayerAt(0);
      c.enableLayerAt(30);
      c.seekTo(30);
      final layer = c.activeLayerForTick(30)!;
      final control = layer.highlights.firstWhere(
        (h) => h.kind == HighlightKind.controlChange,
      );
      expect(control.locationId, "loc-a");
      expect(control.reason.contains("fac-new"), isTrue);
    });
  });

  group("Legend (legend)", () {
    test("MapLegend.entries covers every LocationStatus with stable order", () {
      final legend = MapLegend.standard();
      final statuses = legend.entries.map((e) => e.status).toList();
      expect(statuses, containsAll(LocationStatus.values));
      final sorted = List<LocationStatus>.from(statuses)
        ..sort((a, b) => a.name.compareTo(b.name));
      expect(statuses, sorted);
      for (final entry in legend.entries) {
        expect(entry.label, isNotEmpty);
        expect(entry.token.isNotEmpty, isTrue);
      }
    });

    test("MapLegend.entryFor returns entry for any status", () {
      final legend = MapLegend.standard();
      for (final s in LocationStatus.values) {
        expect(legend.entryFor(s).status, s);
      }
      expect(legend.entryFor(LocationStatus.contested).label, isNotEmpty);
    });
  });

  group("Keyboard control (keyboard_control)", () {
    test("applyKey(advanceSmall) advances currentTick by 1", () {
      final c = MapTimeSliderController.forState(_sampleState());
      c.seekTo(40);
      final before = c.currentTick;
      c.applyKey(MapTimeKey.advanceSmall);
      expect(c.currentTick, before + 1);
    });

    test("applyKey(retreatSmall) retreats currentTick by 1", () {
      final c = MapTimeSliderController.forState(_sampleState());
      c.seekTo(40);
      c.applyKey(MapTimeKey.retreatSmall);
      expect(c.currentTick, 39);
    });

    test("applyKey(advanceBig) advances by 10 and clamps to maxTick", () {
      final c = MapTimeSliderController.forState(_sampleState());
      c.seekTo(95);
      c.applyKey(MapTimeKey.advanceBig);
      expect(c.currentTick, 100);
    });

    test("applyKey(jumpStart) snaps to minTick", () {
      final c = MapTimeSliderController.forState(_sampleState());
      c.seekTo(50);
      c.applyKey(MapTimeKey.jumpStart);
      expect(c.currentTick, 0);
    });

    test("applyKey(jumpEnd) snaps to maxTick", () {
      final c = MapTimeSliderController.forState(_sampleState());
      c.seekTo(50);
      c.applyKey(MapTimeKey.jumpEnd);
      expect(c.currentTick, 100);
    });

    test(
      "applyKey(nextKeyTick) advances to next key tick strictly greater",
      () {
        final c = MapTimeSliderController.forState(_sampleState());
        c.seekTo(0);
        c.applyKey(MapTimeKey.nextKeyTick);
        expect(c.currentTick, greaterThan(0));
        expect(c.keyTicks, contains(c.currentTick));
      },
    );

    test(
      "applyKey(prevKeyTick) retreats to previous key tick strictly less",
      () {
        final c = MapTimeSliderController.forState(_sampleState());
        c.seekTo(100);
        c.applyKey(MapTimeKey.prevKeyTick);
        expect(c.currentTick, lessThan(100));
        expect(c.keyTicks, contains(c.currentTick));
      },
    );

    test("applyKey does nothing past boundaries (clamped)", () {
      final c = MapTimeSliderController.forState(_sampleState());
      c.seekTo(0);
      c.applyKey(MapTimeKey.retreatSmall);
      expect(c.currentTick, 0);

      c.seekTo(c.maxTick);
      c.applyKey(MapTimeKey.advanceBig);
      expect(c.currentTick, c.maxTick);
    });
  });

  group("Determinism & integration", () {
    test("identical inputs produce identical layer outputs", () {
      final a = MapTimeSliderController.forState(_sampleState());
      final b = MapTimeSliderController.forState(_sampleState());
      a.enableLayerAt(0);
      a.enableLayerAt(40);
      b.enableLayerAt(0);
      b.enableLayerAt(40);
      expect(
        a.activeLayerForTick(40)!.highlights.map((h) => h.kind.name).toList(),
        b.activeLayerForTick(40)!.highlights.map((h) => h.kind.name).toList(),
      );
    });

    test("does not consume wall clock or random", () {
      final c1 = MapTimeSliderController.forState(_sampleState());
      c1.enableLayerAt(0);
      c1.enableLayerAt(40);
      final s1 = c1
          .activeLayerForTick(40)!
          .locations
          .map((e) => "${e.id}:${e.status.name}")
          .join(",");

      final c2 = MapTimeSliderController.forState(_sampleState());
      c2.enableLayerAt(0);
      c2.enableLayerAt(40);
      final s2 = c2
          .activeLayerForTick(40)!
          .locations
          .map((e) => "${e.id}:${e.status.name}")
          .join(",");

      expect(s1, s2);
    });
  });
}
